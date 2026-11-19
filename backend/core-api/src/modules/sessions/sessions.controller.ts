/**
 * Controllers for live sessions, bookings and the Person 2 authorization
 * boundary.
 */
import { Request, Response, NextFunction } from 'express';
import { SessionsService } from './sessions.service';
import { ApiError } from '@/middleware/errorHandler';

const sessionsService = new SessionsService();

export class SessionsController {
  async createSession(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      const session = await sessionsService.createSession(req.user.id, req.body, req);
      res.status(201).json({
        success: true,
        message: 'Live session scheduled successfully',
        data: { session },
      });
    } catch (err) {
      next(err);
    }
  }

  async listSessions(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      const page = req.query.page ? parseInt(req.query.page as string, 10) : 1;
      const pageSize = req.query.pageSize ? parseInt(req.query.pageSize as string, 10) : 20;
      const result = await sessionsService.listAvailableSessions(req.user.ageTier, page, pageSize);
      res.status(200).json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  }

  async bookSession(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      const booking = await sessionsService.bookSession(
        req.user.id,
        req.params.sessionId,
        req.body.paymentId,
        req,
      );
      res.status(200).json({
        success: true,
        message:
          booking.status === 'CONFIRMED'
            ? 'Session booking confirmed'
            : 'Session booking created; payment confirmation is required',
        data: { booking },
      });
    } catch (err) {
      next(err);
    }
  }

  async getRoomCredentials(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      const credentials = await sessionsService.authorizeRoomAccess(
        req.user.id,
        req.params.sessionId,
        req,
      );
      res.status(200).json({ success: true, data: credentials });
    } catch (err) {
      next(err);
    }
  }

  async authorizeRoomAccess(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      const credentials = await sessionsService.authorizeRoomAccess(
        req.user.id,
        req.params.sessionId,
        req,
      );
      res.status(200).json({ success: true, data: credentials });
    } catch (err) {
      next(err);
    }
  }

  async getBookingForSessionEngine(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await sessionsService.getBookingForSessionEngine(req.params.bookingId);
      res.status(200).json({ success: true, data });
    } catch (err) {
      next(err);
    }
  }

  async markCompletedFromSessionEngine(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await sessionsService.markCompletedFromSessionEngine(req.params.sessionId);
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  }

  async markCancelledFromSessionEngine(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await sessionsService.markCancelledFromSessionEngine(
        req.params.sessionId,
        String(req.body?.reason ?? ''),
      );
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  }
}
