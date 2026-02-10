import { Router } from 'express';
import type { Request, Response } from 'express';
import * as propertiesRepo from '../repositories/properties.repository';
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

/**
 * GET /api/properties
 * List all properties with optional filters
 */
router.get('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { search, limit, offset } = req.query;

        if (!user.companyId) {
            return res.status(400).json({ error: 'User must be associated with a company' });
        }

        const properties = await propertiesRepo.getProperties({
            companyId: user.companyId,
            filter: { search },
            limit: limit ? parseInt(limit as string) : 50,
            offset: offset ? parseInt(offset as string) : 0
        });

        res.json(properties);
    } catch (error) {
        console.error('Error fetching properties:', error);
        res.status(500).json({ error: 'Failed to fetch properties' });
    }
});

/**
 * GET /api/properties/:id
 * Get single property by ID
 */
router.get('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const property = await propertiesRepo.getProperty(id);

        if (!property) {
            return res.status(404).json({ error: 'Property not found' });
        }

        // Check company access
        if (property.companyId !== (req.user as any).companyId) {
            return res.status(403).json({ error: 'Access denied' });
        }

        res.json(property);
    } catch (error) {
        console.error('Error fetching property:', error);
        res.status(500).json({ error: 'Failed to fetch property' });
    }
});

/**
 * POST /api/properties
 * Create a new property
 */
router.post('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const propertyData = {
            ...req.body,
            companyId: user.companyId
        };

        const newProperty = await propertiesRepo.createProperty(propertyData);
        res.status(201).json(newProperty);
    } catch (error) {
        console.error('Error creating property:', error);
        res.status(500).json({ error: 'Failed to create property' });
    }
});

/**
 * PATCH /api/properties/:id
 * Update an existing property
 */
router.patch('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const updates = req.body;

        const updatedProperty = await propertiesRepo.updateProperty(id, updates);
        res.json(updatedProperty);
    } catch (error) {
        console.error('Error updating property:', error);
        res.status(500).json({ error: 'Failed to update property' });
    }
});

/**
 * DELETE /api/properties/:id
 * Delete a property
 */
router.delete('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const user = req.user as any;

        const success = await propertiesRepo.deleteProperty(id, user.companyId);

        if (!success) {
            return res.status(404).json({ error: 'Property not found' });
        }

        res.json({ message: 'Property deleted successfully' });
    } catch (error) {
        console.error('Error deleting property:', error);
        res.status(500).json({ error: 'Failed to delete property' });
    }
});

/**
 * POST /api/properties/:id/link-deal
 * Link property to a deal
 */
router.post('/:id/link-deal', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const propertyId = parseInt(req.params.id);
        const { dealId } = req.body;

        if (!dealId) {
            return res.status(400).json({ error: 'dealId is required' });
        }

        const success = await propertiesRepo.linkPropertyToDeal(propertyId, dealId);

        if (!success) {
            return res.status(500).json({ error: 'Failed to link property to deal' });
        }

        res.json({ message: 'Property linked to deal successfully' });
    } catch (error) {
        console.error('Error linking property to deal:', error);
        res.status(500).json({ error: 'Failed to link property to deal' });
    }
});

/**
 * DELETE /api/properties/:id/unlink-deal/:dealId
 * Unlink property from a deal
 */
router.delete('/:id/unlink-deal/:dealId', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const propertyId = parseInt(req.params.id);
        const dealId = parseInt(req.params.dealId);

        const success = await propertiesRepo.unlinkPropertyFromDeal(propertyId, dealId);

        if (!success) {
            return res.status(404).json({ error: 'Link not found' });
        }

        res.json({ message: 'Property unlinked from deal successfully' });
    } catch (error) {
        console.error('Error unlinking property from deal:', error);
        res.status(500).json({ error: 'Failed to unlink property from deal' });
    }
});

export default router;
