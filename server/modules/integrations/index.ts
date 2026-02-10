import { Router } from 'express';
import integrationsRoutes from './routes/integrations.routes';

const router = Router();
router.use('/', integrationsRoutes);
export default router;
