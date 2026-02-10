import { db } from '../../../db';
import { conversations, messages, contacts } from '@shared/schema';
import { sql } from 'drizzle-orm';

/**
 * Repository for analytics and statistics
 */

// Get conversations count
export async function getConversationsCount(): Promise<number> {
    try {
        const result = await db.select({ count: sql<number>`count(*)::int` }).from(conversations);
        return result[0]?.count || 0;
    } catch (error) {
        console.error('Error getting conversations count:', error);
        return 0;
    }
}

export async function getConversationsCountByCompany(companyId: number): Promise<number> {
    try {
        const result = await db
            .select({ count: sql<number>`count(*)::int` })
            .from(conversations)
            .where(sql`company_id = ${companyId}`);
        return result[0]?.count || 0;
    } catch (error) {
        console.error(`Error getting conversations count for company ${companyId}:`, error);
        return 0;
    }
}

export async function getConversationsCountByCompanyAndDateRange(
    companyId: number,
    startDate: Date,
    endDate: Date
): Promise<number> {
    try {
        const result = await db
            .select({ count: sql<number>`count(*)::int` })
            .from(conversations)
            .where(sql`company_id = ${companyId} AND created_at BETWEEN ${startDate} AND ${endDate}`);
        return result[0]?.count || 0;
    } catch (error) {
        console.error('Error getting conversations count by date range:', error);
        return 0;
    }
}

// Get messages count
export async function getMessagesCount(): Promise<number> {
    try {
        const result = await db.select({ count: sql<number>`count(*)::int` }).from(messages);
        return result[0]?.count || 0;
    } catch (error) {
        console.error('Error getting messages count:', error);
        return 0;
    }
}

export async function getMessagesCountByCompany(companyId: number): Promise<number> {
    try {
        const result = await db
            .select({ count: sql<number>`count(*)::int` })
            .from(messages)
            .where(sql`company_id = ${companyId}`);
        return result[0]?.count || 0;
    } catch (error) {
        console.error(`Error getting messages count for company ${companyId}:`, error);
        return 0;
    }
}

export async function getMessagesCountByCompanyAndDateRange(
    companyId: number,
    startDate: Date,
    endDate: Date
): Promise<number> {
    try {
        const result = await db
            .select({ count: sql<number>`count(*)::int` })
            .from(messages)
            .where(sql`company_id = ${companyId} AND created_at BETWEEN ${startDate} AND ${endDate}`);
        return result[0]?.count || 0;
    } catch (error) {
        console.error('Error getting messages count by date range:', error);
        return 0;
    }
}

// Get contacts count
export async function getContactsCountByCompanyAndDateRange(
    companyId: number,
    startDate: Date,
    endDate: Date
): Promise<number> {
    try {
        const result = await db
            .select({ count: sql<number>`count(*)::int` })
            .from(contacts)
            .where(sql`company_id = ${companyId} AND created_at BETWEEN ${startDate} AND ${endDate}`);
        return result[0]?.count || 0;
    } catch (error) {
        console.error('Error getting contacts count by date range:', error);
        return 0;
    }
}

// Get conversations by day
export async function getConversationsByDay(days: number): Promise<any[]> {
    try {
        const result = await db.execute(sql`
      SELECT 
        DATE(created_at) as date,
        COUNT(*)::int as count
      FROM conversations
      WHERE created_at >= NOW() - INTERVAL '${sql.raw(days.toString())} days'
      GROUP BY DATE(created_at)
      ORDER BY date
    `);
        return result.rows as any[];
    } catch (error) {
        console.error('Error getting conversations by day:', error);
        return [];
    }
}

export async function getConversationsByDayByCompany(companyId: number, days: number): Promise<any[]> {
    try {
        const result = await db.execute(sql`
      SELECT 
        DATE(created_at) as date,
        COUNT(*)::int as count
      FROM conversations
      WHERE company_id = ${companyId}
        AND created_at >= NOW() - INTERVAL '${sql.raw(days.toString())} days'
      GROUP BY DATE(created_at)
      ORDER BY date
    `);
        return result.rows as any[];
    } catch (error) {
        console.error('Error getting conversations by day for company:', error);
        return [];
    }
}

export async function getConversationsByDayByCompanyAndDateRange(
    companyId: number,
    startDate: Date,
    endDate: Date
): Promise<any[]> {
    try {
        const result = await db.execute(sql`
      SELECT 
        DATE(created_at) as date,
        COUNT(*)::int as count
      FROM conversations
      WHERE company_id = ${companyId}
        AND created_at BETWEEN ${startDate} AND ${endDate}
      GROUP BY DATE(created_at)
      ORDER BY date
    `);
        return result.rows as any[];
    } catch (error) {
        console.error('Error getting conversations by day and date range:', error);
        return [];
    }
}

// Get messages by channel
export async function getMessagesByChannel(): Promise<any[]> {
    try {
        const result = await db.execute(sql`
      SELECT 
        c.channel_type as channel,
        COUNT(m.*)::int as count
      FROM messages m
      JOIN conversations conv ON m.conversation_id = conv.id
      JOIN channel_connections c ON conv.channel_id = c.id
      GROUP BY c.channel_type
      ORDER BY count DESC
    `);
        return result.rows as any[];
    } catch (error) {
        console.error('Error getting messages by channel:', error);
        return [];
    }
}

export async function getMessagesByChannelByCompany(companyId: number): Promise<any[]> {
    try {
        const result = await db.execute(sql`
      SELECT 
        c.channel_type as channel,
        COUNT(m.*)::int as count
      FROM messages m
      JOIN conversations conv ON m.conversation_id = conv.id
      JOIN channel_connections c ON conv.channel_id = c.id
      WHERE m.company_id = ${companyId}
      GROUP BY c.channel_type
      ORDER BY count DESC
    `);
        return result.rows as any[];
    } catch (error) {
        console.error('Error getting messages by channel for company:', error);
        return [];
    }
}
