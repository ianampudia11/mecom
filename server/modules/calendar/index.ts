import { Router } from 'express';
import calendarRoutes from './routes/calendar.routes';

const router = Router();

// Mount calendar routes
router.use('/', calendarRoutes);

export default router;
