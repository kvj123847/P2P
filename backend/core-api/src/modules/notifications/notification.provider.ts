import { NotificationType, Prisma } from '@prisma/client';
import { prisma } from '@/config/database';

export interface NotificationProvider {
  notify(input: {
    userId: string;
    type: NotificationType;
    title: string;
    body: string;
    data?: Prisma.InputJsonValue;
  }): Promise<void>;
}

/**
 * Stores notifications for in-app delivery. No push notification is sent.
 * A Firebase provider can implement the same contract in a later release.
 */
export class MockNotificationProvider implements NotificationProvider {
  async notify(input: Parameters<NotificationProvider['notify']>[0]): Promise<void> {
    await prisma.notification.create({ data: input });
  }
}

export const notificationProvider: NotificationProvider = new MockNotificationProvider();
