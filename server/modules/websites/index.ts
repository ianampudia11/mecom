import { Router } from 'express';
import websitesRoutes from './routes/websites.routes';

const router = Router();
router.use('/', websitesRoutes);
export default router;
