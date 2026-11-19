import { Request } from 'express';
import { prisma } from '@/config/database';
import { ApiError } from '@/middleware/errorHandler';
import { assertAgeTierCompatible } from '@/utils/ageTierGuard';
import { auditLog } from '@/utils/audit';
import { AgeTier, BookingStatus, EarningStatus, PaymentStatus, PaymentType, Prisma, PayoutStatus } from '@prisma/client';
import { env } from '@/config/env';

const PLATFORM_FEE_RATE = 0.2;

export interface CheckoutResultDto {
  paymentId: string;
  clientSecret: string;
  amount: number;
  currency: string;
  provider: 'MOCK';
  demoLabel: 'DEMO PAYMENT';
}

export interface TutorEarningsSummaryDto {
  availableBalance: number;
  pendingBalance: number;
  totalEarned: number;
  currency: string;
  earnings: {
    id: string;
    grossAmount: number;
    platformFee: number;
    netAmount: number;
    currency: string;
    status: EarningStatus;
    createdAt: Date;
  }[];
}

export class PaymentsService {
  private assertMockEnabled() {
    const allowed = env.MOCK_SERVICES_ENABLED &&
      (env.NODE_ENV !== 'production' || env.MOCK_DEMO_MODE);
    if (!allowed) {
      throw ApiError.forbidden('Demo payment simulation is disabled in this environment');
    }
    if (!env.MOCK_PAYMENT_ADMIN_TOKEN) {
      throw ApiError.internal('MOCK_PAYMENT_ADMIN_TOKEN is not configured');
    }
  }

  async createCheckoutSession(
    learnerUserId: string,
    itemType: 'COURSE' | 'SESSION' | 'CHAT',
    itemId: string,
    req?: Request,
  ): Promise<CheckoutResultDto> {
    this.assertMockEnabled();
    const learner = await prisma.user.findUnique({ where: { id: learnerUserId } });
    if (!learner) throw ApiError.notFound('Learner not found');

    let price: number;
    let currency: string;
    let tutorId: string;
    let targetAgeTier: AgeTier;
    if (itemType === 'COURSE') {
      const course = await prisma.course.findUnique({ where: { id: itemId } });
      if (!course) throw ApiError.notFound('Course not found');
      if (course.publishStatus !== 'PUBLISHED') throw ApiError.forbidden('Course is not available');
      price = Number(course.price);
      currency = course.currency;
      tutorId = course.tutorId;
      targetAgeTier = course.ageTierFilter;
    } else if (itemType === 'SESSION') {
      const session = await prisma.liveSession.findUnique({ where: { id: itemId } });
      if (!session) throw ApiError.notFound('Live session not found');
      price = Number(session.price);
      currency = session.currency;
      tutorId = session.tutorId;
      targetAgeTier = session.ageTierFilter;
    } else {
      const tutor = await prisma.tutorProfile.findUnique({ where: { id: itemId }, include: { user: true } });
      if (!tutor) throw ApiError.notFound('Tutor not found');
      price = Number(tutor.hourlyRate) * 0.5;
      currency = tutor.currency;
      tutorId = tutor.id;
      targetAgeTier = tutor.user.ageTier;
    }

    assertAgeTierCompatible(learner.ageTier, targetAgeTier, `checkout for ${itemType.toLowerCase()}`);
    const type = itemType === 'COURSE' ? PaymentType.COURSE_PURCHASE :
      itemType === 'SESSION' ? PaymentType.SESSION_BOOKING : PaymentType.CHAT_SESSION;
    const payment = await prisma.payment.create({
      data: {
        userId: learnerUserId,
        amount: new Prisma.Decimal(price),
        currency: currency.toUpperCase(),
        type,
        provider: 'MOCK',
        status: PaymentStatus.PENDING,
        metadata: { itemType, itemId, tutorId, learnerAgeTier: learner.ageTier },
      },
    });
    await auditLog({
      actorId: learnerUserId,
      action: 'MOCK_PAYMENT_CHECKOUT_INITIATED',
      resource: 'Payment',
      resourceId: payment.id,
      metadata: { itemType, itemId, amount: price, provider: 'MOCK' },
      success: true,
      req,
    });
    return {
      paymentId: payment.id,
      clientSecret: `mock_${payment.id}`,
      amount: price,
      currency: currency.toUpperCase(),
      provider: 'MOCK',
      demoLabel: 'DEMO PAYMENT',
    };
  }

  async simulatePayment(paymentId: string, outcome: 'success' | 'failure', req?: Request) {
    this.assertMockEnabled();
    const payment = await prisma.payment.findUnique({ where: { id: paymentId } });
    if (!payment || payment.provider !== 'MOCK') throw ApiError.notFound('Mock payment not found');
    if (payment.status !== PaymentStatus.PENDING) throw ApiError.conflict('Payment is no longer pending');
    if (outcome === 'failure') {
      return prisma.payment.update({ where: { id: paymentId }, data: { status: PaymentStatus.FAILED } });
    }

    await this.fulfillPayment(paymentId);
    await auditLog({
      action: 'MOCK_PAYMENT_SIMULATED',
      resource: 'Payment',
      resourceId: paymentId,
      metadata: { outcome, provider: 'MOCK' },
      success: true,
      req,
    });
    return prisma.payment.findUniqueOrThrow({ where: { id: paymentId } });
  }

  async confirmDemoPayment(userId: string, paymentId: string, req?: Request) {
    this.assertMockEnabled();
    const payment = await prisma.payment.findFirst({
      where: { id: paymentId, userId, provider: 'MOCK', status: PaymentStatus.PENDING },
    });
    if (!payment) throw ApiError.notFound('Pending demo payment not found');
    await this.fulfillPayment(paymentId);
    await auditLog({
      actorId: userId,
      action: 'MOCK_PAYMENT_CONFIRMED',
      resource: 'Payment',
      resourceId: paymentId,
      metadata: { provider: 'MOCK', demoOnly: true },
      success: true,
      req,
    });
    return prisma.payment.findUniqueOrThrow({ where: { id: paymentId } });
  }

  async fulfillPayment(paymentId: string): Promise<void> {
    const payment = await prisma.payment.findUnique({ where: { id: paymentId } });
    if (!payment || payment.provider !== 'MOCK') throw ApiError.notFound('Mock payment not found');
    if (payment.status === PaymentStatus.SUCCEEDED) return;
    if (payment.status !== PaymentStatus.PENDING) throw ApiError.conflict('Only pending payments can be fulfilled');

    const metadata = (payment.metadata ?? {}) as Record<string, string>;
    const itemType = metadata.itemType;
    const itemId = metadata.itemId;
    const tutorId = metadata.tutorId;
    const gross = Number(payment.amount);
    const platformFee = Math.round(gross * PLATFORM_FEE_RATE * 100) / 100;
    const net = Math.round((gross - platformFee) * 100) / 100;

    await prisma.$transaction(async (tx) => {
      await tx.payment.update({
        where: { id: paymentId },
        data: { status: PaymentStatus.SUCCEEDED, providerReference: `mock_${paymentId}` },
      });
      if (tutorId) {
        await tx.tutorEarning.create({
          data: {
            tutorId,
            paymentId,
            grossAmount: new Prisma.Decimal(gross),
            platformFee: new Prisma.Decimal(platformFee),
            netAmount: new Prisma.Decimal(net),
            currency: payment.currency,
            status: EarningStatus.AVAILABLE,
          },
        });
        await tx.tutorProfile.update({
          where: { id: tutorId },
          data: { totalEarnings: { increment: new Prisma.Decimal(net) } },
        });
      }
      if (itemType === 'COURSE' && itemId) {
        await tx.courseEnrollment.upsert({
          where: { courseId_learnerId: { courseId: itemId, learnerId: payment.userId } },
          create: { courseId: itemId, learnerId: payment.userId },
          update: {},
        });
      }
      if (itemType === 'SESSION' && itemId) {
        await tx.sessionBooking.upsert({
          where: { sessionId_learnerId: { sessionId: itemId, learnerId: payment.userId } },
          create: { sessionId: itemId, learnerId: payment.userId, status: BookingStatus.CONFIRMED, paymentId },
          update: { status: BookingStatus.CONFIRMED, paymentId },
        });
      }
    });
  }

  async requestPayout(userId: string, amount: number, currency = 'USD', req?: Request) {
    const tutor = await prisma.tutorProfile.findUnique({ where: { userId }, include: { user: true } });
    if (!tutor) throw ApiError.notFound('Tutor profile not found');
    if (tutor.user.ageTier === AgeTier.SCHOOL) {
      const availability = (tutor.availability ?? {}) as Record<string, unknown>;
      if (availability.guardianApprovedPayout !== true) {
        throw ApiError.forbidden('School-tier tutors under 18 require an active guardian-linked account for mock payouts');
      }
    }
    const earnings = await prisma.tutorEarning.findMany({ where: { tutorId: tutor.id, status: EarningStatus.AVAILABLE } });
    const available = earnings.reduce((sum, earning) => sum + Number(earning.netAmount), 0);
    if (!Number.isFinite(amount) || amount <= 0 || amount > available) {
      throw ApiError.badRequest(`Insufficient available balance. Available: ${available.toFixed(2)}`);
    }
    const payout = await prisma.payout.create({
      data: { tutorId: tutor.id, amount: new Prisma.Decimal(amount), currency: currency.toUpperCase(), status: PayoutStatus.PENDING },
    });
    await prisma.$transaction(async (tx) => {
      await tx.payout.update({ where: { id: payout.id }, data: { status: PayoutStatus.PAID, completedAt: new Date() } });
      let remaining = amount;
      for (const earning of earnings) {
        if (remaining <= 0) break;
        await tx.tutorEarning.update({ where: { id: earning.id }, data: { status: EarningStatus.PAID_OUT, paidOutAt: new Date() } });
        remaining -= Number(earning.netAmount);
      }
    });
    await auditLog({
      actorId: userId,
      action: 'MOCK_PAYOUT_SIMULATED',
      resource: 'Payout',
      resourceId: payout.id,
      metadata: { amount, currency, provider: 'MOCK' },
      success: true,
      req,
    });
    return { payoutId: payout.id, amount, status: 'PAID', provider: 'MOCK', demoLabel: 'DEMO PAYOUT' };
  }

  async getTutorEarnings(userId: string): Promise<TutorEarningsSummaryDto> {
    const tutor = await prisma.tutorProfile.findUnique({ where: { userId } });
    if (!tutor) throw ApiError.notFound('Tutor profile not found');
    const earnings = await prisma.tutorEarning.findMany({ where: { tutorId: tutor.id }, orderBy: { createdAt: 'desc' }, take: 50 });
    const available = earnings.filter((e) => e.status === EarningStatus.AVAILABLE).reduce((s, e) => s + Number(e.netAmount), 0);
    const pending = earnings.filter((e) => e.status === EarningStatus.PENDING).reduce((s, e) => s + Number(e.netAmount), 0);
    return {
      availableBalance: Math.round(available * 100) / 100,
      pendingBalance: Math.round(pending * 100) / 100,
      totalEarned: Number(tutor.totalEarnings),
      currency: tutor.currency,
      earnings: earnings.map((e) => ({ id: e.id, grossAmount: Number(e.grossAmount), platformFee: Number(e.platformFee), netAmount: Number(e.netAmount), currency: e.currency, status: e.status, createdAt: e.createdAt })),
    };
  }

  async getUserTransactions(userId: string, page = 1, pageSize = 20) {
    const skip = (Math.max(1, page) - 1) * pageSize;
    const [transactions, total] = await Promise.all([
      prisma.payment.findMany({ where: { userId }, skip, take: pageSize, orderBy: { createdAt: 'desc' } }),
      prisma.payment.count({ where: { userId } }),
    ]);
    return {
      data: transactions.map((t) => ({ id: t.id, amount: Number(t.amount), currency: t.currency, type: t.type, status: t.status, provider: t.provider, createdAt: t.createdAt, metadata: t.metadata })),
      total, page, pageSize, totalPages: Math.ceil(total / pageSize),
    };
  }
}
