import { Router } from 'express';
import tagsRoutes from './routes/tags.routes';

const router = Router();
router.use('/', tagsRoutes);
export default router;
