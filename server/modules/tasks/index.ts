import { Router } from 'express';
import tasksRoutes from './routes/tasks.routes';

const router = Router();

// Mount tasks routes
router.use('/', tasksRoutes);

export default router;
