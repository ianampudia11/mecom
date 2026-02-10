import { Router } from 'express';
import type { Request, Response } from 'express';
import * as pipelinesRepo from '../repositories/pipelines.repository';
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

// Pipelines
router.get('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const pipelines = await pipelinesRepo.getPipelines(user.companyId);
        res.json(pipelines);
    } catch (error) {
        console.error('Error fetching pipelines:', error);
        res.status(500).json({ error: 'Failed to fetch pipelines' });
    }
});

router.get('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const pipeline = await pipelinesRepo.getPipeline(id);

        if (!pipeline) {
            return res.status(404).json({ error: 'Pipeline not found' });
        }

        res.json(pipeline);
    } catch (error) {
        console.error('Error fetching pipeline:', error);
        res.status(500).json({ error: 'Failed to fetch pipeline' });
    }
});

router.post('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const pipelineData = {
            ...req.body,
            companyId: user.companyId
        };

        const newPipeline = await pipelinesRepo.createPipeline(pipelineData);
        res.status(201).json(newPipeline);
    } catch (error) {
        console.error('Error creating pipeline:', error);
        res.status(500).json({ error: 'Failed to create pipeline' });
    }
});

router.patch('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const updates = req.body;

        const updated = await pipelinesRepo.updatePipeline(id, updates);
        res.json(updated);
    } catch (error) {
        console.error('Error updating pipeline:', error);
        res.status(500).json({ error: 'Failed to update pipeline' });
    }
});

router.delete('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const success = await pipelinesRepo.deletePipeline(id);
        res.json({ success });
    } catch (error) {
        console.error('Error deleting pipeline:', error);
        res.status(500).json({ error: 'Failed to delete pipeline' });
    }
});

// Pipeline Stages
router.get('/:id/stages', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const pipelineId = parseInt(req.params.id);
        const stages = await pipelinesRepo.getPipelineStagesByPipelineId(pipelineId);
        res.json(stages);
    } catch (error) {
        console.error('Error fetching pipeline stages:', error);
        res.status(500).json({ error: 'Failed to fetch stages' });
    }
});

router.post('/:id/stages', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const pipelineId = parseInt(req.params.id);
        const stageData = {
            ...req.body,
            pipelineId
        };

        const newStage = await pipelinesRepo.createPipelineStage(stageData);
        res.status(201).json(newStage);
    } catch (error) {
        console.error('Error creating pipeline stage:', error);
        res.status(500).json({ error: 'Failed to create stage' });
    }
});

router.patch('/stages/:stageId', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const stageId = parseInt(req.params.stageId);
        const updates = req.body;

        const updated = await pipelinesRepo.updatePipelineStage(stageId, updates);
        res.json(updated);
    } catch (error) {
        console.error('Error updating pipeline stage:', error);
        res.status(500).json({ error: 'Failed to update stage' });
    }
});

router.delete('/stages/:stageId', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const stageId = parseInt(req.params.stageId);
        const { moveDealsToStageId } = req.query;

        const success = await pipelinesRepo.deletePipelineStage(
            stageId,
            moveDealsToStageId ? parseInt(moveDealsToStageId as string) : undefined
        );
        res.json({ success });
    } catch (error) {
        console.error('Error deleting pipeline stage:', error);
        res.status(500).json({ error: 'Failed to delete stage' });
    }
});

router.post('/stages/reorder', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const { stageIds } = req.body;

        if (!Array.isArray(stageIds)) {
            return res.status(400).json({ error: 'stageIds must be an array' });
        }

        const success = await pipelinesRepo.reorderPipelineStages(stageIds);
        res.json({ success });
    } catch (error) {
        console.error('Error reordering pipeline stages:', error);
        res.status(500).json({ error: 'Failed to reorder stages' });
    }
});

export default router;
