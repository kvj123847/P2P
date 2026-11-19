import { NextFunction, Request, Response } from 'express';
import { CoursesService } from './courses.service';
import { ApiError } from '@/middleware/errorHandler';

const service = new CoursesService();

export class CoursesController {
  async list(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      res.json({ success: true, data: await service.list(req.user.id, req.query) });
    } catch (error) { next(error); }
  }

  async get(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      res.json({ success: true, data: await service.get(req.user.id, req.params.courseId) });
    } catch (error) { next(error); }
  }

  async create(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      res.status(201).json({ success: true, data: await service.create(req.user.id, req.body) });
    } catch (error) { next(error); }
  }

  async createLesson(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      res.status(201).json({ success: true, data: await service.createLesson(req.user.id, req.params.courseId, req.body) });
    } catch (error) { next(error); }
  }

  async listLessons(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      res.json({ success: true, data: await service.listLessons(req.user.id, req.params.courseId) });
    } catch (error) { next(error); }
  }

  async enroll(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      res.status(201).json({ success: true, data: await service.enroll(req.user.id, req.params.courseId) });
    } catch (error) { next(error); }
  }

  async progress(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      res.json({ success: true, data: await service.progress(req.user.id, req.params.courseId) });
    } catch (error) { next(error); }
  }

  async updateProgress(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) return next(ApiError.unauthorized());
      res.json({ success: true, data: await service.updateProgress(req.user.id, req.params.courseId, req.params.lessonId, req.body.completed === true) });
    } catch (error) { next(error); }
  }
}
