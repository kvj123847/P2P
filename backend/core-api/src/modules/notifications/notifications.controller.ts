import { NextFunction, Request, Response } from 'express';
import { ApiError } from '@/middleware/errorHandler';
import { NotificationsService } from './notifications.service';

const service = new NotificationsService();
export class NotificationsController {
  async list(req: Request, res: Response, next: NextFunction) {
    try { if (!req.user) return next(ApiError.unauthorized()); res.json({ success: true, data: await service.list(req.user.id, req.query.unread === 'true') }); } catch (e) { next(e); }
  }
  async markRead(req: Request, res: Response, next: NextFunction) {
    try { if (!req.user) return next(ApiError.unauthorized()); res.json({ success: true, data: await service.markRead(req.user.id, req.params.notificationId) }); } catch (e) { next(e); }
  }
  async markAllRead(req: Request, res: Response, next: NextFunction) {
    try { if (!req.user) return next(ApiError.unauthorized()); await service.markAllRead(req.user.id); res.json({ success: true }); } catch (e) { next(e); }
  }
  async registerDevice(req: Request, res: Response, next: NextFunction) {
    try { if (!req.user) return next(ApiError.unauthorized()); res.status(201).json({ success: true, data: await service.registerDevice(req.user.id, req.body) }); } catch (e) { next(e); }
  }
  async removeDevice(req: Request, res: Response, next: NextFunction) {
    try { if (!req.user) return next(ApiError.unauthorized()); await service.removeDevice(req.user.id, req.body?.token); res.json({ success: true }); } catch (e) { next(e); }
  }
}
