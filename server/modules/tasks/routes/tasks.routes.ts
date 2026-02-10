import { Router } from 'express';
import * as fs from 'fs';
import * as path from 'path';
import type { Request, Response } from 'express';
import * as tasksRepo from '../repositories/tasks.repository';
import { ensureAuthenticated } from '../../../middleware';

const LOG_PATH = 'c:\\Users\\ianam\\.gemini\\antigravity\\scratch\\ianampudia11\\server-error.log';

const router = Router();

/**
 * GET /api/tasks/categories
 * Get all task categories for company
 * IMPORTANT: This MUST come before GET /:id to avoid route collision
 */
router.get('/categories', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const categories = await tasksRepo.getTaskCategories(user.companyId);
        res.json(categories);
    } catch (error) {
        console.error('Error fetching task categories:', error);
        res.status(500).json({ error: 'Failed to fetch categories' });
    }
});

/**
 * POST /api/tasks/categories
 * Create task category
 */
router.post('/categories', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const categoryData = {
            ...req.body,
            companyId: user.companyId
        };

        const newCategory = await tasksRepo.createTaskCategory(categoryData);
        res.status(201).json(newCategory);
    } catch (error) {
        console.error('Error creating task category:', error);
        res.status(500).json({ error: 'Failed to create category' });
    }
});

/**
 * GET /api/tasks/contact/:contactId
 * Get all tasks for a contact
 */
router.get('/contact/:contactId', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const contactId = parseInt(req.params.contactId);
        const tasks = await tasksRepo.getContactTasks(contactId);
        res.json(tasks);
    } catch (error) {
        console.error('Error fetching contact tasks:', error);
        res.status(500).json({ error: 'Failed to fetch tasks' });
    }
});

/**
 * GET /api/tasks/:id
 * Get single task by ID
 */
router.get('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const task = await tasksRepo.getTask(id);

        if (!task) {
            return res.status(404).json({ error: 'Task not found' });
        }

        res.json(task);
    } catch (error) {
        console.error('Error fetching task:', error);
        res.status(500).json({ error: 'Failed to fetch task' });
    }
});

/**
 * GET /api/tasks
 * Get all tasks for the authenticated user's company
 */
router.get('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const tasks = await tasksRepo.getAllTasks(user.companyId);

        // Return format expected by frontend: { tasks, total }
        res.json({
            tasks,
            total: tasks.length
        });
    } catch (error) {
        console.error('Error fetching tasks:', error);
        res.status(500).json({ error: 'Failed to fetch tasks' });
    }
});


/**
 * POST /api/tasks
 * Create a new task
 */
router.post('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;

        try {
            fs.appendFileSync(LOG_PATH, `[${new Date().toISOString()}] POST /api/tasks request received from user ${user.id}\n`);
        } catch (e) { /* ignore */ }

        console.log('[CREATE TASK] Request body:', JSON.stringify(req.body, null, 2));
        console.log('[CREATE TASK] User companyId:', user.companyId);

        // Convert empty strings to null for optional fields
        const taskData = {
            ...req.body,
            companyId: user.companyId,
            contactId: req.body.contactId || null,
            description: req.body.description?.trim() || null,
            assignedTo: req.body.assignedTo?.trim() || null,
            category: req.body.category?.trim() || null,
            tags: req.body.tags && req.body.tags.length > 0 ? req.body.tags : null,
            checklist: req.body.checklist && req.body.checklist.length > 0 ? req.body.checklist : null,
            dueDate: req.body.dueDate ? new Date(req.body.dueDate) : null
        };

        console.log('[CREATE TASK] Task data to insert:', JSON.stringify(taskData, null, 2));

        const newTask = await tasksRepo.createTask(taskData);

        console.log('[CREATE TASK] Task created successfully:', newTask.id);
        res.status(201).json(newTask);
    } catch (error) {
        console.error('[CREATE TASK] Error creating task:', error);
        console.error('[CREATE TASK] Error stack:', (error as Error).stack);

        // Write error to file for debugging
        try {
            const errorLog = `
Timestamp: ${new Date().toISOString()}
Error: ${error}
Stack: ${(error as Error).stack}
Body: ${JSON.stringify(req.body, null, 2)}
User: ${JSON.stringify(req.user, null, 2)}
----------------------------------------
`;
            fs.appendFileSync(LOG_PATH, errorLog);

        } catch (logError) {
            console.error('Failed to write to error log:', logError);
        }

        res.status(500).json({ error: 'Failed to create task' });
    }
});

/**
 * PATCH /api/tasks/:id
 * Update a task
 */
router.patch('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const updates = req.body;

        const updatedTask = await tasksRepo.updateTask(id, updates);
        res.json(updatedTask);
    } catch (error) {
        console.error('Error updating task:', error);
        res.status(500).json({ error: 'Failed to update task' });
    }
});

/**
 * DELETE /api/tasks/:id
 * Delete a task
 */
router.delete('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const success = await tasksRepo.deleteTask(id);

        if (!success) {
            return res.status(404).json({ error: 'Task not found' });
        }

        res.json({ message: 'Task deleted successfully' });
    } catch (error) {
        console.error('Error deleting task:', error);
        res.status(500).json({ error: 'Failed to delete task' });
    }
});

/**
 * PATCH /api/tasks/categories/:id
 * Update task category
 */
router.patch('/categories/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const updates = req.body;

        const updatedCategory = await tasksRepo.updateTaskCategory(id, updates);
        res.json(updatedCategory);
    } catch (error) {
        console.error('Error updating task category:', error);
        res.status(500).json({ error: 'Failed to update category' });
    }
});

/**
 * DELETE /api/tasks/categories/:id
 * Delete task category
 */
router.delete('/categories/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const user = req.user as any;

        const success = await tasksRepo.deleteTaskCategory(id, user.companyId);

        if (!success) {
            return res.status(404).json({ error: 'Category not found' });
        }

        res.json({ message: 'Category deleted successfully' });
    } catch (error) {
        console.error('Error deleting task category:', error);
        res.status(500).json({ error: 'Failed to delete category' });
    }
});

export default router;
