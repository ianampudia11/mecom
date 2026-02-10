import { Router } from 'express';
import flowsRoutes from './routes/flows.routes';

const router = Router();

// Mount flows routes
router.use('/', flowsRoutes);

export default router;
