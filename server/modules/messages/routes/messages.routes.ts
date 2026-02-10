import { Router } from 'express';
import type { Request, Response } from 'express';
import * as messagesRepo from '../repositories/messages.repository';
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

/**
 * GET /api/messages/conversations
 * Get all conversations for company
 */
router.get('/conversations', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { search, status, channel, limit, offset } = req.query;

        if (!user.companyId) {
            return res.status(400).json({ error: 'User must be associated with a company' });
        }

        const conversations = await messagesRepo.getConversations({
            companyId: user.companyId,
            filter: { search, status, channel },
            limit: limit ? parseInt(limit as string) : 50,
            offset: offset ? parseInt(offset as string) : 0
        });

        res.json(conversations);
    } catch (error) {
        console.error('Error fetching conversations:', error);
        res.status(500).json({ error: 'Failed to fetch conversations' });
    }
});

/**
 * GET /api/messages/conversations/:id
 * Get single conversation
 */
router.get('/conversations/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const conversation = await messagesRepo.getConversation(id);

        if (!conversation) {
            return res.status(404).json({ error: 'Conversation not found' });
        }

        // Check company access
        if (conversation.companyId !== (req.user as any).companyId) {
            return res.status(403).json({ error: 'Access denied' });
        }

        res.json(conversation);
    } catch (error) {
        console.error('Error fetching conversation:', error);
        res.status(500).json({ error: 'Failed to fetch conversation' });
    }
});

/**
 * POST /api/messages/conversations
 * Create new conversation
 */
router.post('/conversations', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const conversationData = {
            ...req.body,
            companyId: user.companyId
        };

        const newConversation = await messagesRepo.createConversation(conversationData);
        res.status(201).json(newConversation);
    } catch (error) {
        console.error('Error creating conversation:', error);
        res.status(500).json({ error: 'Failed to create conversation' });
    }
});

/**
 * PATCH /api/messages/conversations/:id
 * Update conversation
 */
router.patch('/conversations/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const updates = req.body;

        const updatedConversation = await messagesRepo.updateConversation(id, updates);
        res.json(updatedConversation);
    } catch (error) {
        console.error('Error updating conversation:', error);
        res.status(500).json({ error: 'Failed to update conversation' });
    }
});

/**
 * DELETE /api/messages/conversations/:id
 * Delete conversation
 */
router.delete('/conversations/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const user = req.user as any;

        const success = await messagesRepo.deleteConversation(id, user.companyId);

        if (!success) {
            return res.status(404).json({ error: 'Conversation not found' });
        }

        res.json({ message: 'Conversation deleted successfully' });
    } catch (error) {
        console.error('Error deleting conversation:', error);
        res.status(500).json({ error: 'Failed to delete conversation' });
    }
});

/**
 * GET /api/messages/:conversationId/messages
 * Get messages for a conversation
 */
router.get('/:conversationId/messages', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const conversationId = parseInt(req.params.conversationId);
        const { limit, offset } = req.query;

        const messages = await messagesRepo.getMessages({
            conversationId,
            limit: limit ? parseInt(limit as string) : 50,
            offset: offset ? parseInt(offset as string) : 0
        });

        res.json(messages);
    } catch (error) {
        console.error('Error fetching messages:', error);
        res.status(500).json({ error: 'Failed to fetch messages' });
    }
});

/**
 * POST /api/messages/:conversationId/messages
 * Create message in conversation
 */
router.post('/:conversationId/messages', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const conversationId = parseInt(req.params.conversationId);
        const messageData = {
            ...req.body,
            conversationId
        };

        const newMessage = await messagesRepo.createMessage(messageData);
        res.status(201).json(newMessage);
    } catch (error) {
        console.error('Error creating message:', error);
        res.status(500).json({ error: 'Failed to create message' });
    }
});

/**
 * PATCH /api/messages/:conversationId/messages/:messageId
 * Update a message
 */
router.patch('/:conversationId/messages/:messageId', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const messageId = parseInt(req.params.messageId);
        const updates = req.body;

        const updatedMessage = await messagesRepo.updateMessage(messageId, updates);
        res.json(updatedMessage);
    } catch (error) {
        console.error('Error updating message:', error);
        res.status(500).json({ error: 'Failed to update message' });
    }
});

/**
 * DELETE /api/messages/:conversationId/messages/:messageId
 * Delete a message
 */
router.delete('/:conversationId/messages/:messageId', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const messageId = parseInt(req.params.messageId);

        const success = await messagesRepo.deleteMessage(messageId);

        if (!success) {
            return res.status(404).json({ error: 'Message not found' });
        }

        res.json({ message: 'Message deleted successfully' });
    } catch (error) {
        console.error('Error deleting message:', error);
        res.status(500).json({ error: 'Failed to delete message' });
    }
});

/**
 * POST /api/messages/:conversationId/mark-read
 * Mark all messages in conversation as read
 */
router.post('/:conversationId/mark-read', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const conversationId = parseInt(req.params.conversationId);

        const count = await messagesRepo.markMessagesAsRead(conversationId);

        res.json({ message: `Marked ${count} messages as read` });
    } catch (error) {
        console.error('Error marking messages as read:', error);
        res.status(500).json({ error: 'Failed to mark messages as read' });
    }
});

export default router;
