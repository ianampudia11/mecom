import { Router } from 'express';
import pipelinesRoutes from './routes/pipelines.routes';

const router = Router();
router.use('/', pipelinesRoutes);
export default router;
