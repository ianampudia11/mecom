import { Router } from 'express';
import channelsRoutes from './routes/channels.routes';

const router = Router();
router.use('/', channelsRoutes);
export default router;
