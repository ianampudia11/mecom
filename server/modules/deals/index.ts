import { Router } from 'express';
import dealsRoutes from './routes/deals.routes';

const router = Router();

// Mount deals routes
router.use('/', dealsRoutes);

// Future: add pipeline routes, properties routes, etc.
// router.use('/pipeline', pipelineRoutes);
// router.use('/properties', propertiesRoutes);

export default router;
