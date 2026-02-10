import { Router } from 'express';
import type { Request, Response } from 'express';

const router = Router();

/**
 * Webhooks module - handles webhook verification and processing
 * Note: Actual webhook processing logic is complex and should import
 * from existing webhook handlers in routes.ts
 */

// Messenger webhook verification
router.get('/messenger', async (req: Request, res: Response) => {
    try {
        const mode = req.query['hub.mode'];
        const token = req.query['hub.verify_token'];
        const challenge = req.query['hub.challenge'];

        if (mode === 'subscribe' && token === process.env.MESSENGER_VERIFY_TOKEN) {
            console.log('Messenger webhook verified');
            res.status(200).send(challenge);
        } else {
            res.sendStatus(403);
        }
    } catch (error) {
        console.error('Error in Messenger webhook verification:', error);
        res.sendStatus(500);
    }
});

// Messenger webhook processing
router.post('/messenger', async (req: Request, res: Response) => {
    try {
        // TODO: Import actual messenger webhook processing logic
        // This is a placeholder - actual logic exists in routes.ts
        console.log('Messenger webhook received:', req.body);
        res.sendStatus(200);
    } catch (error) {
        console.error('Error processing Messenger webhook:', error);
        res.sendStatus(500);
    }
});

// WhatsApp webhook verification
router.get('/whatsapp', async (req: Request, res: Response) => {
    try {
        const mode = req.query['hub.mode'];
        const token = req.query['hub.verify_token'];
        const challenge = req.query['hub.challenge'];

        if (mode === 'subscribe' && token === process.env.WHATSAPP_VERIFY_TOKEN) {
            console.log('WhatsApp webhook verified');
            res.status(200).send(challenge);
        } else {
            res.sendStatus(403);
        }
    } catch (error) {
        console.error('Error in WhatsApp webhook verification:', error);
        res.sendStatus(500);
    }
});

// WhatsApp webhook processing
router.post('/whatsapp', async (req: Request, res: Response) => {
    try {
        // TODO: Import actual WhatsApp webhook processing logic
        // This is a placeholder - actual logic exists in routes.ts
        console.log('WhatsApp webhook received:', req.body);
        res.sendStatus(200);
    } catch (error) {
        console.error('Error processing WhatsApp webhook:', error);
        res.sendStatus(500);
    }
});

// Generic test webhook
router.post('/test', async (req: Request, res: Response) => {
    try {
        console.log('Test webhook received:', req.body);
        res.json({ success: true, received: req.body });
    } catch (error) {
        console.error('Error in test webhook:', error);
        res.status(500).json({ error: 'Failed to process test webhook' });
    }
});

export default router;
