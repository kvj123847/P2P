import { timingSafeEqual } from 'crypto';
import { Request, Response, NextFunction } from 'express';
import { env } from '@/config/env';
import { ApiError } from '@/middleware/errorHandler';

/**
 * Authenticates trusted backend-to-backend calls without replacing the
 * end-user JWT. The caller must send both X-Service-Token and Authorization.
 */
export function requireServiceToken(
  req: Request,
  _res: Response,
  next: NextFunction,
): void {
  const supplied = req.header('x-service-token');
  const expected = env.P1_SERVICE_TOKEN;

  if (!supplied || !expected) {
    return next(ApiError.unauthorized('Invalid service credentials'));
  }

  const suppliedBuffer = Buffer.from(supplied);
  const expectedBuffer = Buffer.from(expected);
  if (
    suppliedBuffer.length !== expectedBuffer.length ||
    !timingSafeEqual(suppliedBuffer, expectedBuffer)
  ) {
    return next(ApiError.unauthorized('Invalid service credentials'));
  }

  next();
}
