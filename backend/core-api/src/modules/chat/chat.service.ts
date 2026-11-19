import { ConversationType } from '@prisma/client';
import { prisma } from '@/config/database';
import { ApiError } from '@/middleware/errorHandler';

export class ChatService {
  private async membership(userId: string, conversationId: string) {
    const membership = await prisma.chatParticipant.findUnique({
      where: { conversationId_userId: { conversationId, userId } },
      include: { conversation: true },
    });
    if (!membership) throw ApiError.notFound('Conversation not found');
    return membership;
  }

  async createConversation(userId: string, input: Record<string, unknown>) {
    const requested = Array.isArray(input.participantIds) ? input.participantIds.filter((id): id is string => typeof id === 'string') : [];
    const participantIds = [...new Set([userId, ...requested])];
    if (participantIds.length < 2) throw ApiError.badRequest('At least two participants are required');
    const users = await prisma.user.findMany({ where: { id: { in: participantIds }, deletedAt: null }, select: { id: true, ageTier: true } });
    if (users.length !== participantIds.length) throw ApiError.badRequest('All participants must be active users');
    const tier = users[0].ageTier;
    if (users.some((user) => user.ageTier !== tier)) throw ApiError.forbidden('Chat participants must share the same age tier');
    const type = input.type === ConversationType.SESSION_SUPPORT ? ConversationType.SESSION_SUPPORT : ConversationType.DIRECT;
    const conversation = await prisma.chatConversation.create({
      data: {
        type,
        sessionId: typeof input.sessionId === 'string' ? input.sessionId : undefined,
        ageTierValidated: true,
        participants: { create: participantIds.map((id) => ({ userId: id })) },
      },
      include: { participants: true },
    });
    return conversation;
  }

  async listMessages(userId: string, conversationId: string, query: Record<string, unknown>) {
    await this.membership(userId, conversationId);
    const limit = Math.min(Math.max(Number(query.limit ?? 30), 1), 100);
    const before = typeof query.before === 'string' ? query.before : undefined;
    return prisma.chatMessage.findMany({
      where: { conversationId, isDeleted: false, ...(before ? { createdAt: { lt: new Date(before) } } : {}) },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }

  async sendMessage(userId: string, conversationId: string, input: Record<string, unknown>) {
    await this.membership(userId, conversationId);
    if (typeof input.content !== 'string' || !input.content.trim()) throw ApiError.badRequest('Message content is required');
    return prisma.chatMessage.create({
      data: { conversationId, senderId: userId, content: input.content.trim() },
    });
  }

  async markRead(userId: string, conversationId: string) {
    await this.membership(userId, conversationId);
    await prisma.chatParticipant.update({
      where: { conversationId_userId: { conversationId, userId } },
      data: { lastReadAt: new Date() },
    });
  }
}
