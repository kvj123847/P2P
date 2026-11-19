import { prisma } from '@/config/database';
import { ApiError } from '@/middleware/errorHandler';

export class NotificationsService {
  list(userId: string, unread: boolean) {
    return prisma.notification.findMany({ where: { userId, ...(unread ? { isRead: false } : {}) }, orderBy: { createdAt: 'desc' }, take: 100 });
  }

  async markRead(userId: string, notificationId: string) {
    const notification = await prisma.notification.findFirst({ where: { id: notificationId, userId } });
    if (!notification) throw ApiError.notFound('Notification not found');
    return prisma.notification.update({ where: { id: notificationId }, data: { isRead: true } });
  }

  async markAllRead(userId: string) {
    await prisma.notification.updateMany({ where: { userId, isRead: false }, data: { isRead: true } });
  }

  async registerDevice(userId: string, input: Record<string, unknown>) {
    if (typeof input.token !== 'string' || input.token.length < 20) throw ApiError.badRequest('A valid device token is required');
    const platform = typeof input.platform === 'string' ? input.platform : 'android';
    return prisma.deviceToken.upsert({
      where: { userId_token: { userId, token: input.token } },
      create: { userId, token: input.token, platform },
      update: { platform },
    });
  }

  async removeDevice(userId: string, token: unknown) {
    if (typeof token !== 'string' || !token) throw ApiError.badRequest('Device token is required');
    await prisma.deviceToken.deleteMany({ where: { userId, token } });
  }
}
