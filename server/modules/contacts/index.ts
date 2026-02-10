import { Router } from 'express';
import contactsRoutes from './routes/contacts.routes';

const router = Router();

// Mount contacts routes
router.use('/', contactsRoutes);

// Future: add tags, tasks, documents, appointments routes
// router.use('/tags', tagsRoutes);
// router.use('/tasks', tasksRoutes);
// router.use('/documents', documentsRoutes);
// router.use('/appointments', appointmentsRoutes);

export default router;
