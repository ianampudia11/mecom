import { db } from '../../../db';
import { conversations, messages } from '@shared/schema';
import type { Conversation, InsertConversation, Message, InsertMessage } from '@shared/schema';
import { eq, and, desc, or, sql, ilike } from 'drizzle-orm';

/**
 * Repository for messages and conversations
 * Extracted from monolithic storage.ts
 */

// Get conversations for a company
export async function getConversations(options: {
    companyId: number;
    filter?: any;
    limit?: number;
    offset?: number;
}): Promise<Conversation[]> {
    try {
        const { companyId, filter = {}, limit = 50, offset = 0 } = options;

        let query = db
            .select()
            .from(conversations)
            .where(eq(conversations.companyId, companyId));

        // Apply filters
        if (filter.search) {
            query = query.where(
                or(
                    ilike(conversations.contactName, `%${filter.search}%`),
                    ilike(conversations.contactPhone, `%${filter.search}%`)
                )
            );
        }

        if (filter.status) {
            query = query.where(eq(conversations.status, filter.status));
        }

        if (filter.channel) {
            query = query.where(eq(conversations.channel, filter.channel));
        }

        const result = await query
            .orderBy(desc(conversations.lastMessageAt))
            .limit(limit)
            .offset(offset);

        return result;
    } catch (error) {
        console.error('Error getting conversations:', error);
        return [];
    }
}

// Get single conversation
export async function getConversation(id: number): Promise<Conversation | undefined> {
    try {
        const [conversation] = await db
            .select()
            .from(conversations)
            .where(eq(conversations.id, id));
        return conversation;
    } catch (error) {
        console.error(`Error getting conversation ${id}:`, error);
        return undefined;
    }
}

// Create conversation
export async function createConversation(conversation: InsertConversation): Promise<Conversation> {
    try {
        const [newConversation] = await db
            .insert(conversations)
            .values({
                ...conversation,
                createdAt: new Date(),
                updatedAt: new Date()
            })
            .returning();

        return newConversation;
    } catch (error) {
        console.error('Error creating conversation:', error);
        throw error;
    }
}

// Update conversation
export async function updateConversation(
    id: number,
    updates: Partial<InsertConversation>
): Promise<Conversation> {
    try {
        const [updatedConversation] = await db
            .update(conversations)
            .set({
                ...updates,
                updatedAt: new Date()
            })
            .where(eq(conversations.id, id))
            .returning();

        if (!updatedConversation) {
            throw new Error(`Conversation ${id} not found`);
        }

        return updatedConversation;
    } catch (error) {
        console.error(`Error updating conversation ${id}:`, error);
        throw error;
    }
}

// Delete conversation
export async function deleteConversation(id: number, companyId: number): Promise<boolean> {
    try {
        await db
            .delete(conversations)
            .where(and(
                eq(conversations.id, id),
                eq(conversations.companyId, companyId)
            ));

        return true;
    } catch (error) {
        console.error(`Error deleting conversation ${id}:`, error);
        return false;
    }
}

// Get messages for a conversation
export async function getMessages(options: {
    conversationId: number;
    limit?: number;
    offset?: number;
}): Promise<Message[]> {
    try {
        const { conversationId, limit = 50, offset = 0 } = options;

        return await db
            .select()
            .from(messages)
            .where(eq(messages.conversationId, conversationId))
            .orderBy(desc(messages.createdAt))
            .limit(limit)
            .offset(offset);
    } catch (error) {
        console.error(`Error getting messages for conversation ${conversationId}:`, error);
        return [];
    }
}

// Create message
export async function createMessage(message: InsertMessage): Promise<Message> {
    try {
        const [newMessage] = await db
            .insert(messages)
            .values({
                ...message,
                createdAt: new Date()
            })
            .returning();

        return newMessage;
    } catch (error) {
        console.error('Error creating message:', error);
        throw error;
    }
}

// Update message
export async function updateMessage(id: number, updates: Partial<InsertMessage>): Promise<Message> {
    try {
        const [updatedMessage] = await db
            .update(messages)
            .set(updates)
            .where(eq(messages.id, id))
            .returning();

        if (!updatedMessage) {
            throw new Error(`Message ${id} not found`);
        }

        return updatedMessage;
    } catch (error) {
        console.error(`Error updating message ${id}:`, error);
        throw error;
    }
}

// Delete message
export async function deleteMessage(id: number): Promise<boolean> {
    try {
        await db.delete(messages).where(eq(messages.id, id));
        return true;
    } catch (error) {
        console.error(`Error deleting message ${id}:`, error);
        return false;
    }
}

// Mark messages as read
export async function markMessagesAsRead(conversationId: number): Promise<number> {
    try {
        const result = await db
            .update(messages)
            .set({ read: true })
            .where(and(
                eq(messages.conversationId, conversationId),
                eq(messages.read, false)
            ))
            .returning();

        return result.length;
    } catch (error) {
        console.error(`Error marking messages as read for conversation ${conversationId}:`, error);
        return 0;
    }
}
