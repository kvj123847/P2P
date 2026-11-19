import { AgeTier, PaymentStatus, PublishStatus } from '@prisma/client';
import { prisma } from '@/config/database';
import { ApiError } from '@/middleware/errorHandler';

export class CoursesService {
  private async user(id: string) {
    const user = await prisma.user.findUnique({ where: { id }, select: { ageTier: true } });
    if (!user) throw ApiError.unauthorized('User not found');
    return user;
  }

  private async courseForTier(userId: string, courseId: string, includeLessons = false) {
    const user = await this.user(userId);
    const course = await prisma.course.findUnique({
      where: { id: courseId },
      include: includeLessons ? { lessons: { orderBy: { sortOrder: 'asc' } } } : undefined,
    });
    if (!course) throw ApiError.notFound('Course not found');
    if (course.ageTierFilter !== user.ageTier) throw ApiError.forbidden('Age-tier violation in course access');
    return { user, course };
  }

  async list(userId: string, query: Record<string, unknown>) {
    const user = await this.user(userId);
    const subject = typeof query.subject === 'string' ? query.subject : undefined;
    return prisma.course.findMany({
      where: { ageTierFilter: user.ageTier, publishStatus: PublishStatus.PUBLISHED, ...(subject ? { subject } : {}) },
      include: { tutor: { include: { user: { select: { firstName: true, lastName: true } } } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async get(userId: string, courseId: string) {
    const { course } = await this.courseForTier(userId, courseId);
    if (course.publishStatus !== PublishStatus.PUBLISHED) {
      const owner = await prisma.course.findFirst({ where: { id: courseId, tutor: { userId } }, select: { id: true } });
      if (!owner) throw ApiError.notFound('Course not found');
    }
    const enrollment = await prisma.courseEnrollment.findUnique({
      where: { courseId_learnerId: { courseId, learnerId: userId } },
      select: { id: true },
    });
    if (Number(course.price) > 0 && !enrollment) {
      return { ...course, lessons: [] };
    }
    return prisma.course.findUniqueOrThrow({
      where: { id: courseId },
      include: { lessons: { orderBy: { sortOrder: 'asc' } } },
    });
  }

  async create(userId: string, input: Record<string, unknown>) {
    const tutor = await prisma.tutorProfile.findUnique({ where: { userId }, include: { user: { select: { ageTier: true } } } });
    if (!tutor) throw ApiError.forbidden('Tutor profile required');
    if (typeof input.title !== 'string' || typeof input.description !== 'string' || typeof input.subject !== 'string') {
      throw ApiError.badRequest('title, description and subject are required');
    }
    const price = Number(input.price ?? 0);
    if (!Number.isFinite(price) || price < 0) throw ApiError.badRequest('price must be a non-negative number');
    return prisma.course.create({
      data: {
        tutorId: tutor.id,
        title: input.title,
        description: input.description,
        subject: input.subject,
        ageTierFilter: tutor.user.ageTier,
        price,
        currency: typeof input.currency === 'string' ? input.currency : 'GBP',
      },
    });
  }

  async createLesson(userId: string, courseId: string, input: Record<string, unknown>) {
    const course = await prisma.course.findFirst({ where: { id: courseId, tutor: { userId } } });
    if (!course) throw ApiError.notFound('Course not found');
    if (typeof input.title !== 'string' || typeof input.content !== 'string') throw ApiError.badRequest('title and content are required');
    const lesson = await prisma.lesson.create({ data: { courseId, title: input.title, content: input.content, videoUrl: typeof input.videoUrl === 'string' ? input.videoUrl : undefined, sortOrder: Number(input.sortOrder ?? 0) } });
    await prisma.course.update({ where: { id: courseId }, data: { lessonCount: { increment: 1 } } });
    return lesson;
  }

  async listLessons(userId: string, courseId: string) {
    const { course } = await this.courseForTier(userId, courseId);
    if (Number(course.price) > 0) {
      const enrollment = await prisma.courseEnrollment.findUnique({
        where: { courseId_learnerId: { courseId, learnerId: userId } },
        select: { id: true },
      });
      if (!enrollment) throw ApiError.forbidden('Successful payment is required to access lessons');
    }
    return prisma.lesson.findMany({ where: { courseId }, orderBy: { sortOrder: 'asc' } });
  }

  async enroll(userId: string, courseId: string) {
    const { course } = await this.courseForTier(userId, courseId);
    if (course.publishStatus !== PublishStatus.PUBLISHED) throw ApiError.forbidden('Course is not published');
    if (Number(course.price) > 0) {
      const payment = await prisma.payment.findFirst({
        where: {
          userId,
          type: 'COURSE_PURCHASE',
          status: PaymentStatus.SUCCEEDED,
          provider: 'MOCK',
          metadata: { path: ['itemId'], equals: courseId },
        },
        select: { id: true },
      });
      if (!payment) throw ApiError.forbidden('Successful demo payment is required to enroll in this course');
    }
    return prisma.courseEnrollment.upsert({
      where: { courseId_learnerId: { courseId, learnerId: userId } },
      create: { courseId, learnerId: userId },
      update: {},
    });
  }

  async progress(userId: string, courseId: string) {
    await this.courseForTier(userId, courseId);
    const enrollment = await prisma.courseEnrollment.findUnique({ where: { courseId_learnerId: { courseId, learnerId: userId } } });
    if (!enrollment) throw ApiError.forbidden('Enroll in the course first');
    const [lessons, completed] = await Promise.all([
      prisma.lesson.count({ where: { courseId } }),
      prisma.lessonProgress.count({ where: { learnerId: userId, lesson: { courseId }, completedAt: { not: null } } }),
    ]);
    return { courseId, completedLessons: completed, totalLessons: lessons, percent: lessons ? Math.round((completed / lessons) * 100) : 0 };
  }

  async updateProgress(userId: string, courseId: string, lessonId: string, completed: boolean) {
    await this.progress(userId, courseId);
    const lesson = await prisma.lesson.findFirst({ where: { id: lessonId, courseId } });
    if (!lesson) throw ApiError.notFound('Lesson not found');
    return prisma.lessonProgress.upsert({
      where: { lessonId_learnerId: { lessonId, learnerId: userId } },
      create: { lessonId, learnerId: userId, completedAt: completed ? new Date() : null },
      update: { completedAt: completed ? new Date() : null },
    });
  }
}
