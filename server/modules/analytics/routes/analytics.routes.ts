import { Router } from 'express';
import type { Request, Response } from 'express';
import * as analyticsRepo from '../repositories/analytics.repository';
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

// Conversations analytics
router.get('/conversations/count', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const count = await analyticsRepo.getConversationsCountByCompany(user.companyId);
        res.json({ count });
    } catch (error) {
        console.error('Error fetching conversations count:', error);
        res.status(500).json({ error: 'Failed to fetch count' });
    }
});

router.get('/conversations/by-day', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { days } = req.query;
        const data = await analyticsRepo.getConversationsByDayByCompany(
            user.companyId,
            days ? parseInt(days as string) : 30
        );
        res.json(data);
    } catch (error) {
        console.error('Error fetching conversations by day:', error);
        res.status(500).json({ error: 'Failed to fetch data' });
    }
});

router.get('/conversations/by-date-range', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { startDate, endDate } = req.query;

        if (!startDate || !endDate) {
            return res.status(400).json({ error: 'startDate and endDate are required' });
        }

        const data = await analyticsRepo.getConversationsByDayByCompanyAndDateRange(
            user.companyId,
            new Date(startDate as string),
            new Date(endDate as string)
        );
        res.json(data);
    } catch (error) {
        console.error('Error fetching conversations by date range:', error);
        res.status(500).json({ error: 'Failed to fetch data' });
    }
});

// Messages analytics
router.get('/messages/count', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const count = await analyticsRepo.getMessagesCountByCompany(user.companyId);
        res.json({ count });
    } catch (error) {
        console.error('Error fetching messages count:', error);
        res.status(500).json({ error: 'Failed to fetch count' });
    }
});

router.get('/messages/by-channel', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const data = await analyticsRepo.getMessagesByChannelByCompany(user.companyId);
        res.json(data);
    } catch (error) {
        console.error('Error fetching messages by channel:', error);
        res.status(500).json({ error: 'Failed to fetch data' });
    }
});

// Contacts analytics
router.get('/contacts/count-by-range', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { startDate, endDate } = req.query;

        if (!startDate || !endDate) {
            return res.status(400).json({ error: 'startDate and endDate are required' });
        }

        const count = await analyticsRepo.getContactsCountByCompanyAndDateRange(
            user.companyId,
            new Date(startDate as string),
            new Date(endDate as string)
        );
        res.json({ count });
    } catch (error) {
        console.error('Error fetching contacts count:', error);
        res.status(500).json({ error: 'Failed to fetch count' });
    }
});

export default router;
