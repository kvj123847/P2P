/**
 * @file payments.controller.ts
 * @description Controller for checkout creation, webhooks, earnings, and tutor payouts.
 */

import { Request, Response, NextFunction } from 'express';
import { PaymentsService } from './payments.service';
import { ApiError } from '@/middleware/errorHandler';

const paymentsService = new PaymentsService();

export class PaymentsController {
  /**
   * POST /api/v1/payments/checkout
   * Initiates payment for a course, live session, or chat doubt session.
   */
  async createCheckout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      const { itemType, itemId } = req.body;

      const result = await paymentsService.createCheckoutSession(
        req.user.id,
        itemType,
        itemId,
        req,
      );

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }

  async simulatePayment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (req.headers['x-mock-payment-token'] !== process.env.MOCK_PAYMENT_ADMIN_TOKEN) {
        return next(ApiError.forbidden('Invalid mock payment control token'));
      }

      const { outcome } = req.body;
      if (outcome !== 'success' && outcome !== 'failure') {
        return next(ApiError.badRequest('outcome must be success or failure'));
      }
      const payment = await paymentsService.simulatePayment(req.params.paymentId, outcome, req);
      res.status(200).json({ success: true, demoLabel: 'DEMO PAYMENT', data: payment });
    } catch (err) {
      next(err);
    }
  }

  async confirmDemoPayment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      const payment = await paymentsService.confirmDemoPayment(
        req.user.id,
        req.params.paymentId,
        req,
      );
      res.status(200).json({ success: true, demoLabel: 'DEMO PAYMENT', data: payment });
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /api/v1/payments/transactions
   * Learner's purchase history.
   */
  async getTransactions(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      const page = req.query.page ? parseInt(req.query.page as string, 10) : 1;
      const pageSize = req.query.pageSize ? parseInt(req.query.pageSize as string, 10) : 20;

      const result = await paymentsService.getUserTransactions(req.user.id, page, pageSize);
      res.status(200).json({
        success: true,
        ...result,
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /api/v1/payments/earnings
   * Tutor's balance ledger and payout availability.
   */
  async getEarnings(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      const earnings = await paymentsService.getTutorEarnings(req.user.id);
      res.status(200).json({
        success: true,
        data: earnings,
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /api/v1/payments/payout
   * Tutor initiates payout to their connected Stripe account.
   */
  async requestPayout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      const { amount, currency } = req.body;

      const result = await paymentsService.requestPayout(
        req.user.id,
        Number(amount),
        currency,
        req,
      );

      res.status(200).json({
        success: true,
        message: 'Payout successfully processed',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  }
}
