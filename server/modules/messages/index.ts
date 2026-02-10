import { Router } from 'express';
import messagesRoutes from './routes/messages.routes';

const router = Router();

// Mount messages routes
router.use('/', messagesRoutes);

export default router;
