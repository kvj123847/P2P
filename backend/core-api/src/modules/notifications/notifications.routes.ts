import { Router } from 'express';
import { requireAuth } from '@/middleware/auth';
import { NotificationsController } from './notifications.controller';

const router = Router();
const controller = new NotificationsController();
router.use(requireAuth);
router.get('/', controller.list.bind(controller));
router.patch('/:notificationId/read', controller.markRead.bind(controller));
router.post('/read-all', controller.markAllRead.bind(controller));
router.post('/device-token', controller.registerDevice.bind(controller));
router.delete('/device-token', controller.removeDevice.bind(controller));
export default router;
