import { Router } from 'express';
import webhooksRoutes from './routes/webhooks.routes';

const router = Router();
router.use('/', webhooksRoutes);
export default router;
