import { Router } from 'express';
import type { Request, Response } from 'express';
import * as dealsRepo from '../repositories/deals.repository';

// Import auth middleware
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

/**
 * GET /api/deals
 * List all deals with optional filters
 * INCLUDES: Linked properties (fix we implemented earlier!)
 */
router.get('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { generalSearch } = req.query;

        if (!user.companyId) {
            return res.status(400).json({ message: 'User must be associated with a company' });
        }

        const filter: any = { companyId: user.companyId };

        if (generalSearch) {
            filter.generalSearch = generalSearch;
        }

        // Get deals from repository
        const deals = await dealsRepo.getDeals(filter);

        // Load linked properties for each deal (our recent fix!)
        const dealsWithProperties = await Promise.all(
            deals.map(async (deal: any) => {
                try {
                    const properties = await dealsRepo.getDealProperties(deal.id);
                    return {
                        ...deal,
                        properties
                    };
                } catch (err) {
                    console.error(`Error loading properties for deal ${deal.id}: `, err);
                    return { ...deal, properties: [] };
                }
            })
        );

        return res.status(200).json(dealsWithProperties);
    } catch (error: any) {
        console.error('Error fetching deals:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

/**
 * GET /api/deals/stage/:stage
 * Get deals by stage
 */
router.get('/stage/:stage', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const { stage } = req.params;
        const deals = await dealsRepo.getDealsByStage(stage);
        res.json(deals);
    } catch (error) {
        console.error('Error fetching deals by stage:', error);
        res.status(500).json({ error: 'Failed to fetch deals' });
    }
});

/**
 * GET /api/deals/contact/:contactId
 * Get deals for a specific contact
 */
router.get('/contact/:contactId', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const contactId = parseInt(req.params.contactId);
        const deals = await dealsRepo.getDealsByContact(contactId);
        res.json(deals);
    } catch (error) {
        console.error('Error fetching deals for contact:', error);
        res.status(500).json({ error: 'Failed to fetch deals' });
    }
});

/**
 * GET /api/deals/:id
 * Get single deal by ID
 */
router.get('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const deal = await dealsRepo.getDeal(id);

        if (!deal) {
            return res.status(404).json({ error: 'Deal not found' });
        }

        // Check company access
        if (deal.companyId !== (req.user as any).companyId) {
            return res.status(403).json({ error: 'Access denied' });
        }

        res.json(deal);
    } catch (error) {
        console.error('Error fetching deal:', error);
        res.status(500).json({ error: 'Failed to fetch deal' });
    }
});

/**
 * POST /api/deals
 * Create a new deal
 */
router.post('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const dealData = {
            ...req.body,
            companyId: user.companyId
        };

        const newDeal = await dealsRepo.createDeal(dealData);
        res.status(201).json(newDeal);
    } catch (error) {
        console.error('Error creating deal:', error);
        res.status(500).json({ error: 'Failed to create deal' });
    }
});

/**
 * PATCH /api/deals/:id
 * Update an existing deal
 */
router.patch('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const updates = req.body;

        const updatedDeal = await dealsRepo.updateDeal(id, updates);
        res.json(updatedDeal);
    } catch (error) {
        console.error('Error updating deal:', error);
        res.status(500).json({ error: 'Failed to update deal' });
    }
});

/**
 * DELETE /api/deals/:id
 * Delete a deal
 */
router.delete('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const user = req.user as any;

        const result = await dealsRepo.deleteDeal(id, user.companyId);

        if (!result.success) {
            return res.status(404).json({ error: result.reason || 'Deal not found' });
        }

        res.json({ message: 'Deal deleted successfully' });
    } catch (error) {
        console.error('Error deleting deal:', error);
        res.status(500).json({ error: 'Failed to delete deal' });
    }
});

export default router;
