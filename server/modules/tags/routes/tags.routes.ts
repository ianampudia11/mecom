import { Router } from 'express';
import type { Request, Response } from 'express';
import * as tagsRepo from '../repositories/tags.repository';
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

// GET /api/tags
// List tags for the company
// Query param 'include_usage=true' returns all tags from deals/contacts/conversations
// Without params, returns only manually created tags from tags table (for Settings page)
router.get('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        if (!user?.companyId) {
            return res.status(401).json({ error: 'User not authenticated' });
        }

        const includeUsage = req.query.include_usage === 'true';

        if (includeUsage) {
            // Get ALL tags including those in use (for dropdowns/filters)
            const result = await tagsRepo.getTagStats(user.companyId);
            const tags = result.map((stat: any, index: number) => ({
                id: index + 1,
                name: stat.tag,
                color: stat.color,
                usage: {
                    conversations: stat.conversationCount || 0,
                    deals: stat.dealCount || 0,
                    contacts: stat.contactCount || 0
                }
            }));
            res.json(tags);
        } else {
            // Get only manually created tags (for Settings management page)
            const manualTags = await tagsRepo.getManualTags(user.companyId);
            res.json(manualTags);
        }
    } catch (error) {
        console.error('Error fetching tags:', error);
        res.status(500).json({ error: 'Failed to fetch tags' });
    }
});


// GET /api/tags/stats
router.get('/stats', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const stats = await tagsRepo.getTagStats(user.companyId);
        res.json(stats);
    } catch (error) {
        console.error('Error fetching tag stats:', error);
        res.status(500).json({ error: 'Failed to fetch tag statistics' });
    }
});

// POST /api/tags
router.post('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { name, color } = req.body;

        if (!name?.trim()) {
            return res.status(400).json({ error: 'Tag name is required' });
        }

        const result = await tagsRepo.createTag(user.companyId, name.trim(), color);
        res.json({ success: true, ...result, message: 'Tag created successfully' });
    } catch (error: any) {
        console.error('Error creating tag:', error);
        res.status(400).json({ error: error.message || 'Failed to create tag' });
    }
});

// PUT /api/tags/:tagName
router.put('/:tagName', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const oldTag = decodeURIComponent(req.params.tagName);
        const { newName, color } = req.body;

        if (!newName?.trim()) {
            return res.status(400).json({ error: 'New tag name is required' });
        }

        const result = await tagsRepo.renameTag(user.companyId, oldTag, newName.trim(), color);
        res.json({ success: true, ...result });
    } catch (error) {
        console.error('Error renaming tag:', error);
        res.status(500).json({ error: 'Failed to rename tag' });
    }
});

// DELETE /api/tags/:tagName
router.delete('/:tagName', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const tagName = decodeURIComponent(req.params.tagName);

        const success = await tagsRepo.deleteTag(user.companyId, tagName);
        res.json({ success, deletedTag: tagName });
    } catch (error) {
        console.error('Error deleting tag:', error);
        res.status(500).json({ error: 'Failed to delete tag' });
    }
});

export default router;
