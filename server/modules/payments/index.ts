import { Router } from 'express';
import paymentsRoutes from './routes/payments.routes';

const router = Router();
router.use('/', paymentsRoutes);
export default router;
