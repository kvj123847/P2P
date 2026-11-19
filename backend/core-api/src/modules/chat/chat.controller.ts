import { NextFunction, Request, Response } from 'express';
import { ApiError } from '@/middleware/errorHandler';
import { ChatService } from './chat.service';

const service = new ChatService();
export class ChatController {
  async createConversation(req: Request, res: Response, next: NextFunction) {
    try { if (!req.user) return next(ApiError.unauthorized()); res.status(201).json({ success: true, data: await service.createConversation(req.user.id, req.body) }); } catch (e) { next(e); }
  }
  async listMessages(req: Request, res: Response, next: NextFunction) {
    try { if (!req.user) return next(ApiError.unauthorized()); res.json({ success: true, data: await service.listMessages(req.user.id, req.params.conversationId, req.query) }); } catch (e) { next(e); }
  }
  async sendMessage(req: Request, res: Response, next: NextFunction) {
    try { if (!req.user) return next(ApiError.unauthorized()); res.status(201).json({ success: true, data: await service.sendMessage(req.user.id, req.params.conversationId, req.body) }); } catch (e) { next(e); }
  }
  async markRead(req: Request, res: Response, next: NextFunction) {
    try { if (!req.user) return next(ApiError.unauthorized()); await service.markRead(req.user.id, req.params.conversationId); res.json({ success: true }); } catch (e) { next(e); }
  }
}
