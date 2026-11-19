import { Router } from 'express';
import { requireAuth, requireRole } from '@/middleware/auth';
import { UserRoleType } from '@prisma/client';
import { CoursesController } from './courses.controller';

const router = Router();
const controller = new CoursesController();

router.use(requireAuth);
router.get('/', controller.list.bind(controller));
router.get('/:courseId', controller.get.bind(controller));
router.post('/', requireRole(UserRoleType.TUTOR), controller.create.bind(controller));
router.post('/:courseId/lessons', requireRole(UserRoleType.TUTOR), controller.createLesson.bind(controller));
router.get('/:courseId/lessons', controller.listLessons.bind(controller));
router.post('/:courseId/enroll', controller.enroll.bind(controller));
router.get('/:courseId/progress', controller.progress.bind(controller));
router.patch('/:courseId/lessons/:lessonId/progress', controller.updateProgress.bind(controller));

export default router;
