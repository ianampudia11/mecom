import { Router } from 'express';
import notesRoutes from './routes/notes.routes';

const router = Router();
router.use('/', notesRoutes);
export default router;
