import { Router } from 'express';
import type { Request, Response } from 'express';
import * as integrationsRepo from '../repositories/integrations.repository';
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

// Google Calendar
router.get('/google-calendar', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const tokens = await integrationsRepo.getGoogleTokens(user.id, user.companyId);

        if (!tokens) {
            return res.status(404).json({ error: 'Google Calendar not connected' });
        }

        res.json({ connected: true, hasTokens: true });
    } catch (error) {
        console.error('Error fetching Google tokens:', error);
        res.status(500).json({ error: 'Failed to fetch connection' });
    }
});

router.post('/google-calendar', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { tokens } = req.body;

        const success = await integrationsRepo.saveGoogleTokens(user.id, user.companyId, tokens);
        res.json({ success });
    } catch (error) {
        console.error('Error saving Google tokens:', error);
        res.status(500).json({ error: 'Failed to save tokens' });
    }
});

router.delete('/google-calendar', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const success = await integrationsRepo.deleteGoogleTokens(user.id, user.companyId);
        res.json({ success });
    } catch (error) {
        console.error('Error deleting Google tokens:', error);
        res.status(500).json({ error: 'Failed to disconnect' });
    }
});

// Zoho Calendar
router.get('/zoho', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const tokens = await integrationsRepo.getZohoTokens(user.id, user.companyId);

        if (!tokens) {
            return res.status(404).json({ error: 'Zoho not connected' });
        }

        res.json({ connected: true, hasTokens: true });
    } catch (error) {
        console.error('Error fetching Zoho tokens:', error);
        res.status(500).json({ error: 'Failed to fetch connection' });
    }
});

router.post('/zoho', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { tokens } = req.body;

        const success = await integrationsRepo.saveZohoTokens(user.id, user.companyId, tokens);
        res.json({ success });
    } catch (error) {
        console.error('Error saving Zoho tokens:', error);
        res.status(500).json({ error: 'Failed to save tokens' });
    }
});

router.delete('/zoho', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const success = await integrationsRepo.deleteZohoTokens(user.id, user.companyId);
        res.json({ success });
    } catch (error) {
        console.error('Error deleting Zoho tokens:', error);
        res.status(500).json({ error: 'Failed to disconnect' });
    }
});

// Calendly
router.get('/calendly', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const tokens = await integrationsRepo.getCalendlyTokens(user.id, user.companyId);

        if (!tokens) {
            return res.status(404).json({ error: 'Calendly not connected' });
        }

        res.json({ connected: true, hasTokens: true });
    } catch (error) {
        console.error('Error fetching Calendly tokens:', error);
        res.status(500).json({ error: 'Failed to fetch connection' });
    }
});

router.post('/calendly', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { tokens } = req.body;

        const success = await integrationsRepo.saveCalendlyTokens(user.id, user.companyId, tokens);
        res.json({ success });
    } catch (error) {
        console.error('Error saving Calendly tokens:', error);
        res.status(500).json({ error: 'Failed to save tokens' });
    }
});

router.delete('/calendly', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const success = await integrationsRepo.deleteCalendlyTokens(user.id, user.companyId);
        res.json({ success });
    } catch (error) {
        console.error('Error deleting Calendly tokens:', error);
        res.status(500).json({ error: 'Failed to disconnect' });
    }
});

export default router;
