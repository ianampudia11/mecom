import { Router } from 'express';
import type { Request, Response } from 'express';
import { storage } from '../storage';
import { ensureAuthenticated, ensureActiveSubscription, requireAnyPermission, requirePermission } from '../middleware';
import { PERMISSIONS } from '@shared/schema';

const router = Router();

/**
 * GET /api/conversations
 * Get all conversations for the authenticated user's company
 */
router.get('/', ensureAuthenticated, ensureActiveSubscription, requireAnyPermission([PERMISSIONS.VIEW_ALL_CONVERSATIONS, PERMISSIONS.VIEW_ASSIGNED_CONVERSATIONS]), async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const userPermissions = (req as any).userPermissions;

        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 50;
        const search = req.query.search as string;
        const contactId = req.query.contactId ? parseInt(req.query.contactId as string) : undefined;

        const companyId = user.isSuperAdmin ? undefined : user.companyId;

        const assignedToUserId = (userPermissions && !userPermissions[PERMISSIONS.VIEW_ALL_CONVERSATIONS]) ? user.id : undefined;

        const { conversations, total } = await storage.getConversations({
            companyId,
            page,
            limit,
            search,
            assignedToUserId,
            contactId
        });

        const conversationsWithContacts = await Promise.all(
            conversations.map(async (conversation) => {
                const contact = conversation.contactId ? await storage.getContact(conversation.contactId) : null;
                const channelConnection = conversation.channelId ? await storage.getChannelConnection(conversation.channelId) : null;
                return {
                    ...conversation,
                    contact,
                    channelConnection
                };
            })
        );

        res.json({
            conversations: conversationsWithContacts,
            total: total,
            page,
            limit,
            totalPages: Math.ceil(total / limit)
        });
    } catch (error) {
        console.error('Error fetching conversations:', error);
        res.status(500).json({ error: 'Failed to fetch conversations' });
    }
});

/**
 * GET /api/conversations/:id
 * Get a single conversation by ID
 */
router.get('/:id', ensureAuthenticated, ensureActiveSubscription, requireAnyPermission([PERMISSIONS.VIEW_ALL_CONVERSATIONS, PERMISSIONS.VIEW_ASSIGNED_CONVERSATIONS]), async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const user = req.user as any;
        const userPermissions = (req as any).userPermissions;

        const conversation = await storage.getConversation(id);

        if (!conversation) {
            return res.status(404).json({ message: 'Conversation not found' });
        }

        // Filter out group conversations
        if (conversation.isGroup || conversation.groupJid) {
            return res.status(404).json({ message: 'Conversation not found' });
        }

        // Check permissions
        if (!user.isSuperAdmin) {
            if (user.companyId && conversation.companyId !== user.companyId && conversation.companyId !== null) {
                return res.status(403).json({ message: 'Access denied' });
            }

            if (userPermissions && !userPermissions[PERMISSIONS.VIEW_ALL_CONVERSATIONS]) {
                if (conversation.assignedToUserId !== user.id) {
                    return res.status(403).json({ message: 'Access denied' });
                }
            }
        }

        const contact = conversation.contactId ? await storage.getContact(conversation.contactId) : null;
        const channelConnection = conversation.channelId ? await storage.getChannelConnection(conversation.channelId) : null;

        res.json({
            ...conversation,
            contact,
            channelConnection
        });
    } catch (error) {
        console.error('Error fetching conversation:', error);
        res.status(500).json({ error: 'Failed to fetch conversation' });
    }
});

/**
 * POST /api/conversations/:id/mark-read
 * Mark a conversation as read
 */
router.post('/:id/mark-read', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const conversationId = parseInt(req.params.id);
        const user = req.user as any;

        const conversation = await storage.getConversation(conversationId);
        if (!conversation) {
            return res.status(404).json({ message: 'Conversation not found' });
        }

        if (!user.isSuperAdmin && user.companyId && conversation.companyId !== user.companyId && conversation.companyId !== null) {
            return res.status(403).json({ message: 'Access denied' });
        }

        await storage.markConversationAsRead(conversationId);

        // Broadcast to WebSocket clients
        if ((global as any).broadcastToAll) {
            (global as any).broadcastToAll({
                type: 'unreadCountUpdated',
                data: {
                    conversationId,
                    unreadCount: 0
                }
            });
        }

        res.json({
            success: true,
            conversationId,
            unreadCount: 0
        });
    } catch (err: any) {
        console.error('Error marking conversation as read:', err);
        res.status(500).json({ message: err.message || 'Failed to mark conversation as read' });
    }
});

/**
 * GET /api/conversations/unread-counts
 * Get unread counts for all conversations
 */
router.get('/unread-counts', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const unreadCounts = await storage.getAllUnreadCounts(user.id);
        res.json(unreadCounts);
    } catch (err: any) {
        console.error('Error fetching unread counts:', err);
        res.status(500).json({ message: err.message || 'Failed to fetch unread counts' });
    }
});

/**
 * GET /api/conversations/:id/unread-count
 * Get unread count for a specific conversation
 */
router.get('/:id/unread-count', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const conversationId = parseInt(req.params.id);
        const user = req.user as any;

        const conversation = await storage.getConversation(conversationId);
        if (!conversation) {
            return res.status(404).json({ message: 'Conversation not found' });
        }

        if (!user.isSuperAdmin && user.companyId && conversation.companyId !== user.companyId && conversation.companyId !== null) {
            return res.status(403).json({ message: 'Access denied' });
        }

        const unreadCount = await storage.getUnreadCount(conversationId);
        res.json({ unreadCount });
    } catch (err: any) {
        console.error('Error fetching unread count:', err);
        res.status(500).json({ message: err.message || 'Failed to fetch unread count' });
    }
});

/**
 * PATCH /api/conversations/:id
 * Update a conversation
 */
router.patch('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const conversationId = parseInt(req.params.id);
        const updates = req.body;

        const updatedConversation = await storage.updateConversation(conversationId, updates);
        res.json(updatedConversation);
    } catch (error) {
        console.error('Error updating conversation:', error);
        res.status(500).json({ error: 'Failed to update conversation' });
    }
});

/**
 * POST /api/conversations/:id/assign
 * Assign a conversation to an agent
 */
router.post('/:id/assign', ensureAuthenticated, requirePermission(PERMISSIONS.ASSIGN_CONVERSATIONS), async (req: Request, res: Response) => {
    try {
        const conversationId = parseInt(req.params.id);
        const { agentId } = req.body;
        const user = req.user as any;

        if (isNaN(conversationId)) {
            return res.status(400).json({ error: 'Invalid conversation ID' });
        }

        const conversation = await storage.getConversation(conversationId);
        if (!conversation) {
            return res.status(404).json({ error: 'Conversation not found' });
        }

        if (!user.isSuperAdmin && conversation.companyId !== user.companyId) {
            return res.status(403).json({ error: 'Access denied' });
        }

        const updatedConversation = await storage.updateConversation(conversationId, {
            assignedToUserId: agentId
        });

        res.json(updatedConversation);
    } catch (error) {
        console.error('Error assigning conversation:', error);
        res.status(500).json({ error: 'Failed to assign conversation' });
    }
});

/**
 * DELETE /api/conversations/:id/assign
 * Unassign a conversation
 */
router.delete('/:id/assign', ensureAuthenticated, requirePermission(PERMISSIONS.ASSIGN_CONVERSATIONS), async (req: Request, res: Response) => {
    try {
        const conversationId = parseInt(req.params.id);
        const user = req.user as any;

        if (isNaN(conversationId)) {
            return res.status(400).json({ error: 'Invalid conversation ID' });
        }

        const conversation = await storage.getConversation(conversationId);
        if (!conversation) {
            return res.status(404).json({ error: 'Conversation not found' });
        }

        if (!user.isSuperAdmin && conversation.companyId !== user.companyId) {
            return res.status(403).json({ error: 'Access denied' });
        }

        const updatedConversation = await storage.updateConversation(conversationId, {
            assignedToUserId: null
        });

        res.json(updatedConversation);
    } catch (error) {
        console.error('Error unassigning conversation:', error);
        res.status(500).json({ error: 'Failed to unassign conversation' });
    }
});

export default router;
