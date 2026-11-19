import { Router } from 'express';
import { requireAuth } from '@/middleware/auth';
import { ChatController } from './chat.controller';

const router = Router();
const controller = new ChatController();
router.use(requireAuth);
router.post('/conversations', controller.createConversation.bind(controller));
router.get('/conversations/:conversationId/messages', controller.listMessages.bind(controller));
router.post('/conversations/:conversationId/messages', controller.sendMessage.bind(controller));
router.post('/conversations/:conversationId/read', controller.markRead.bind(controller));
export default router;
