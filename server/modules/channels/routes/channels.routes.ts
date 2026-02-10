import { Router } from 'express';
import type { Request, Response } from 'express';
import * as channelsRepo from '../repositories/channels.repository';
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

router.get('/connections', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const connections = await channelsRepo.getChannelConnections(user.id, user.companyId);
        res.json(connections);
    } catch (error) {
        console.error('Error fetching channel connections:', error);
        res.status(500).json({ error: 'Failed to fetch channel connections' });
    }
});

router.get('/connections/company/:companyId', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const companyId = parseInt(req.params.companyId);
        const connections = await channelsRepo.getChannelConnectionsByCompany(companyId);
        res.json(connections);
    } catch (error) {
        console.error('Error fetching company channel connections:', error);
        res.status(500).json({ error: 'Failed to fetch channel connections' });
    }
});

router.get('/connections/type/:type', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const { type } = req.params;
        const connections = await channelsRepo.getChannelConnectionsByType(type);
        res.json(connections);
    } catch (error) {
        console.error('Error fetching channel connections by type:', error);
        res.status(500).json({ error: 'Failed to fetch channel connections' });
    }
});

router.get('/connections/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const connection = await channelsRepo.getChannelConnection(id);

        if (!connection) {
            return res.status(404).json({ error: 'Channel connection not found' });
        }

        res.json(connection);
    } catch (error) {
        console.error('Error fetching channel connection:', error);
        res.status(500).json({ error: 'Failed to fetch channel connection' });
    }
});

router.post('/connections', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const connectionData = req.body;
        const newConnection = await channelsRepo.createChannelConnection(connectionData);
        res.status(201).json(newConnection);
    } catch (error) {
        console.error('Error creating channel connection:', error);
        res.status(500).json({ error: 'Failed to create channel connection' });
    }
});

router.patch('/connections/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const updates = req.body;

        const updated = await channelsRepo.updateChannelConnection(id, updates);
        res.json(updated);
    } catch (error) {
        console.error('Error updating channel connection:', error);
        res.status(500).json({ error: 'Failed to update channel connection' });
    }
});

router.patch('/connections/:id/status', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const { status } = req.body;

        const updated = await channelsRepo.updateChannelConnectionStatus(id, status);
        res.json(updated);
    } catch (error) {
        console.error('Error updating channel connection status:', error);
        res.status(500).json({ error: 'Failed to update status' });
    }
});

router.delete('/connections/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const success = await channelsRepo.deleteChannelConnection(id);
        res.json({ success });
    } catch (error) {
        console.error('Error deleting channel connection:', error);
        res.status(500).json({ error: 'Failed to delete channel connection' });
    }
});

router.post('/instagram/activate', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const count = await channelsRepo.ensureInstagramChannelsActive();
        res.json({ activated: count });
    } catch (error) {
        console.error('Error activating Instagram channels:', error);
        res.status(500).json({ error: 'Failed to activate Instagram channels' });
    }
});

export default router;
