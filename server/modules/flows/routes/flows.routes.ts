import { Router } from 'express';
import type { Request, Response } from 'express';
import * as flowsRepo from '../repositories/flows.repository';
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

/**
 * GET /api/flows
 * Get all flows for company
 */
router.get('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;

        if (!user.companyId) {
            return res.status(400).json({ error: 'User must be associated with a company' });
        }

        const flows = await flowsRepo.getFlows(user.companyId);
        res.json(flows);
    } catch (error) {
        console.error('Error fetching flows:', error);
        res.status(500).json({ error: 'Failed to fetch flows' });
    }
});

/**
 * GET /api/flows/:id
 * Get single flow
 */
router.get('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const flow = await flowsRepo.getFlow(id);

        if (!flow) {
            return res.status(404).json({ error: 'Flow not found' });
        }

        // Check company access
        if (flow.companyId !== (req.user as any).companyId) {
            return res.status(403).json({ error: 'Access denied' });
        }

        res.json(flow);
    } catch (error) {
        console.error('Error fetching flow:', error);
        res.status(500).json({ error: 'Failed to fetch flow' });
    }
});

/**
 * POST /api/flows
 * Create new flow
 */
router.post('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const flowData = {
            ...req.body,
            companyId: user.companyId
        };

        const newFlow = await flowsRepo.createFlow(flowData);
        res.status(201).json(newFlow);
    } catch (error) {
        console.error('Error creating flow:', error);
        res.status(500).json({ error: 'Failed to create flow' });
    }
});

/**
 * PATCH /api/flows/:id
 * Update flow
 */
router.patch('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const updates = req.body;

        const updatedFlow = await flowsRepo.updateFlow(id, updates);
        res.json(updatedFlow);
    } catch (error) {
        console.error('Error updating flow:', error);
        res.status(500).json({ error: 'Failed to update flow' });
    }
});

/**
 * DELETE /api/flows/:id
 * Delete flow
 */
router.delete('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const user = req.user as any;

        const success = await flowsRepo.deleteFlow(id, user.companyId);

        if (!success) {
            return res.status(404).json({ error: 'Flow not found' });
        }

        res.json({ message: 'Flow deleted successfully' });
    } catch (error) {
        console.error('Error deleting flow:', error);
        res.status(500).json({ error: 'Failed to delete flow' });
    }
});

/**
 * GET /api/flows/:id/executions
 * Get executions for a flow
 */
router.get('/:id/executions', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const flowId = parseInt(req.params.id);
        const { limit } = req.query;

        const executions = await flowsRepo.getFlowExecutions(
            flowId,
            limit ? parseInt(limit as string) : 50
        );

        res.json(executions);
    } catch (error) {
        console.error('Error fetching flow executions:', error);
        res.status(500).json({ error: 'Failed to fetch executions' });
    }
});

/**
 * POST /api/flows/:id/executions
 * Create flow execution
 */
router.post('/:id/executions', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const flowId = parseInt(req.params.id);
        const executionData = {
            ...req.body,
            flowId
        };

        const newExecution = await flowsRepo.createFlowExecution(executionData);
        res.status(201).json(newExecution);
    } catch (error) {
        console.error('Error creating flow execution:', error);
        res.status(500).json({ error: 'Failed to create execution' });
    }
});

/**
 * PATCH /api/flows/:flowId/executions/:executionId
 * Update flow execution
 */
router.patch('/:flowId/executions/:executionId', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const executionId = parseInt(req.params.executionId);
        const updates = req.body;

        const updatedExecution = await flowsRepo.updateFlowExecution(executionId, updates);
        res.json(updatedExecution);
    } catch (error) {
        console.error('Error updating flow execution:', error);
        res.status(500).json({ error: 'Failed to update execution' });
    }
});

export default router;
