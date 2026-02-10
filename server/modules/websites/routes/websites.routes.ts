import { Router } from 'express';
import type { Request, Response } from 'express';
import * as websitesRepo from '../repositories/websites.repository';
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

// Websites
router.get('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const websites = await websitesRepo.getWebsites(user.companyId);
        res.json(websites);
    } catch (error) {
        console.error('Error fetching websites:', error);
        res.status(500).json({ error: 'Failed to fetch websites' });
    }
});

router.get('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const website = await websitesRepo.getWebsite(id);

        if (!website) {
            return res.status(404).json({ error: 'Website not found' });
        }

        res.json(website);
    } catch (error) {
        console.error('Error fetching website:', error);
        res.status(500).json({ error: 'Failed to fetch website' });
    }
});

router.post('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const websiteData = {
            ...req.body,
            companyId: user.companyId
        };

        const newWebsite = await websitesRepo.createWebsite(websiteData);
        res.status(201).json(newWebsite);
    } catch (error) {
        console.error('Error creating website:', error);
        res.status(500).json({ error: 'Failed to create website' });
    }
});

router.patch('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const updates = req.body;

        const updated = await websitesRepo.updateWebsite(id, updates);
        res.json(updated);
    } catch (error) {
        console.error('Error updating website:', error);
        res.status(500).json({ error: 'Failed to update website' });
    }
});

router.delete('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const success = await websitesRepo.deleteWebsite(id);
        res.json({ success });
    } catch (error) {
        console.error('Error deleting website:', error);
        res.status(500).json({ error: 'Failed to delete website' });
    }
});

// Website Assets
router.get('/:id/assets', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const websiteId = parseInt(req.params.id);
        const assets = await websitesRepo.getWebsiteAssets(websiteId);
        res.json(assets);
    } catch (error) {
        console.error('Error fetching website assets:', error);
        res.status(500).json({ error: 'Failed to fetch assets' });
    }
});

router.post('/:id/assets', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const websiteId = parseInt(req.params.id);
        const assetData = {
            ...req.body,
            websiteId
        };

        const newAsset = await websitesRepo.createWebsiteAsset(assetData);
        res.status(201).json(newAsset);
    } catch (error) {
        console.error('Error creating website asset:', error);
        res.status(500).json({ error: 'Failed to create asset' });
    }
});

router.delete('/assets/:assetId', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const assetId = parseInt(req.params.assetId);
        const success = await websitesRepo.deleteWebsiteAsset(assetId);
        res.json({ success });
    } catch (error) {
        console.error('Error deleting website asset:', error);
        res.status(500).json({ error: 'Failed to delete asset' });
    }
});

export default router;
