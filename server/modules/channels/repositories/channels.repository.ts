import { db } from '../../../db';
import { channelConnections } from '@shared/schema';
import type { ChannelConnection, InsertChannelConnection } from '@shared/schema';
import { eq, and, sql } from 'drizzle-orm';

/**
 * Repository for channel connections
 */

export async function getChannelConnections(userId: number | null, companyId?: number): Promise<ChannelConnection[]> {
    try {
        if (companyId) {
            return await db
                .select()
                .from(channelConnections)
                .where(eq(channelConnections.companyId, companyId));
        } else if (userId) {
            return await db
                .select()
                .from(channelConnections)
                .where(eq(channelConnections.userId, userId));
        }
        return [];
    } catch (error) {
        console.error('Error getting channel connections:', error);
        return [];
    }
}

export async function getChannelConnectionsByCompany(companyId: number): Promise<ChannelConnection[]> {
    try {
        return await db
            .select()
            .from(channelConnections)
            .where(eq(channelConnections.companyId, companyId));
    } catch (error) {
        console.error(`Error getting channel connections for company ${companyId}:`, error);
        return [];
    }
}

export async function getChannelConnectionsByType(channelType: string): Promise<ChannelConnection[]> {
    try {
        return await db
            .select()
            .from(channelConnections)
            .where(eq(channelConnections.channelType, channelType));
    } catch (error) {
        console.error(`Error getting channel connections by type ${channelType}:`, error);
        return [];
    }
}

export async function getChannelConnection(id: number): Promise<ChannelConnection | undefined> {
    try {
        const [connection] = await db
            .select()
            .from(channelConnections)
            .where(eq(channelConnections.id, id));
        return connection;
    } catch (error) {
        console.error(`Error getting channel connection ${id}:`, error);
        return undefined;
    }
}

export async function createChannelConnection(connection: InsertChannelConnection): Promise<ChannelConnection> {
    try {
        const [newConnection] = await db
            .insert(channelConnections)
            .values({
                ...connection,
                createdAt: new Date(),
                updatedAt: new Date()
            })
            .returning();
        return newConnection;
    } catch (error) {
        console.error('Error creating channel connection:', error);
        throw error;
    }
}

export async function updateChannelConnectionStatus(id: number, status: string): Promise<ChannelConnection> {
    try {
        const [updated] = await db
            .update(channelConnections)
            .set({ status, updatedAt: new Date() })
            .where(eq(channelConnections.id, id))
            .returning();

        if (!updated) {
            throw new Error(`Channel connection ${id} not found`);
        }

        return updated;
    } catch (error) {
        console.error(`Error updating channel connection status ${id}:`, error);
        throw error;
    }
}

export async function updateChannelConnection(id: number, updates: Partial<InsertChannelConnection>): Promise<ChannelConnection> {
    try {
        const [updated] = await db
            .update(channelConnections)
            .set({ ...updates, updatedAt: new Date() })
            .where(eq(channelConnections.id, id))
            .returning();

        if (!updated) {
            throw new Error(`Channel connection ${id} not found`);
        }

        return updated;
    } catch (error) {
        console.error(`Error updating channel connection ${id}:`, error);
        throw error;
    }
}

export async function deleteChannelConnection(id: number): Promise<boolean> {
    try {
        await db.delete(channelConnections).where(eq(channelConnections.id, id));
        return true;
    } catch (error) {
        console.error(`Error deleting channel connection ${id}:`, error);
        return false;
    }
}

export async function ensureInstagramChannelsActive(): Promise<number> {
    try {
        const result = await db
            .update(channelConnections)
            .set({ status: 'active', updatedAt: new Date() })
            .where(and(
                eq(channelConnections.channelType, 'instagram'),
                eq(channelConnections.status, 'inactive')
            ))
            .returning();

        return result.length;
    } catch (error) {
        console.error('Error ensuring Instagram channels active:', error);
        return 0;
    }
}
