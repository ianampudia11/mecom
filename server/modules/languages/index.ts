import { Router } from 'express';
import languagesRoutes from './routes/languages.routes';

const router = Router();
router.use('/', languagesRoutes);
export default router;
