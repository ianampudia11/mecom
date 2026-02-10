import { Router } from 'express';
import type { Request, Response } from 'express';
import * as plansRepo from '../repositories/plans.repository';
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

router.get('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const plans = await plansRepo.getAllPlans();
        res.json(plans);
    } catch (error) {
        console.error('Error fetching plans:', error);
        res.status(500).json({ error: 'Failed to fetch plans' });
    }
});

router.get('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const plan = await plansRepo.getPlan(id);

        if (!plan) {
            return res.status(404).json({ error: 'Plan not found' });
        }

        res.json(plan);
    } catch (error) {
        console.error('Error fetching plan:', error);
        res.status(500).json({ error: 'Failed to fetch plan' });
    }
});

router.get('/:id/ai-providers', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const planId = parseInt(req.params.id);
        const configs = await plansRepo.getPlanAiProviderConfigs(planId);
        res.json(configs);
    } catch (error) {
        console.error('Error fetching AI provider configs:', error);
        res.status(500).json({ error: 'Failed to fetch configs' });
    }
});

export default router;
