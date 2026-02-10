import { Router } from 'express';
import plansRoutes from './routes/plans.routes';

const router = Router();
router.use('/', plansRoutes);
export default router;
