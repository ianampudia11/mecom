import { Router } from 'express';
import adminRoutes from './routes/admin.routes';

const router = Router();

// Mount admin routes
router.use('/', adminRoutes);

export default router;
