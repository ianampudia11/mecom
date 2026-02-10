import { Router } from 'express';
import propertiesRoutes from './routes/properties.routes';

const router = Router();

// Mount properties routes
router.use('/', propertiesRoutes);

export default router;
