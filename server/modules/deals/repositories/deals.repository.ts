import { db } from '../../../db';
import { deals, dealActivities, pipelineStages, contacts } from '@shared/schema';
import type { Deal, InsertDeal } from '@shared/schema';
import { eq, and, desc, sql } from 'drizzle-orm';

/**
 * Repository for deal-related database operations
 * Extracted from monolithic storage.ts to improve maintainability
 */

// Get deals by stage
export async function getDealsByStage(stage: string): Promise<Deal[]> {
    try {
        return await db
            .select()
            .from(deals)
            .where(eq(deals.stage, stage as any))
            .orderBy(desc(deals.lastActivityAt));
    } catch (error) {
        console.error(`Error getting deals by stage ${stage}:`, error);
        return [];
    }
}

// Get single deal by ID
export async function getDeal(id: number): Promise<Deal | undefined> {
    try {
        const [deal] = await db
            .select()
            .from(deals)
            .where(eq(deals.id, id));
        return deal;
    } catch (error) {
        console.error(`Error getting deal with ID ${id}:`, error);
        return undefined;
    }
}

// Get deals by contact
export async function getDealsByContact(contactId: number): Promise<Deal[]> {
    try {
        return await db
            .select()
            .from(deals)
            .where(
                and(
                    eq(deals.contactId, contactId),
                    sql`${deals.status} != 'archived'`
                )
            )
            .orderBy(desc(deals.lastActivityAt));
    } catch (error) {
        console.error(`Error getting deals for contact ${contactId}:`, error);
        return [];
    }
}

// Get active deal by contact
export async function getActiveDealByContact(contactId: number, companyId?: number): Promise<Deal | null> {
    try {
        const conditions = [
            eq(deals.contactId, contactId),
            eq(deals.status, 'active')
        ];

        if (companyId) {
            conditions.push(eq(deals.companyId, companyId));
        }

        const result = await db
            .select()
            .from(deals)
            .where(and(...conditions))
            .limit(1);

        return result[0] || null;
    } catch (error) {
        console.error(`Error getting active deal for contact ${contactId}:`, error);
        return null;
    }
}

// Get deals with filters
export async function getDeals(options: {
    companyId: number;
    filter?: any;
}): Promise<any[]> {
    try {
        const conditions = [eq(deals.companyId, options.companyId)];

        if (options.filter?.status) {
            conditions.push(eq(deals.status, options.filter.status));
        }

        if (options.filter?.priority) {
            conditions.push(eq(deals.priority, options.filter.priority));
        }

        if (options.filter?.stageId) {
            conditions.push(eq(deals.stageId, options.filter.stageId));
        }

        const result = await db
            .select({
                id: deals.id,
                title: deals.title,
                value: deals.value,
                status: deals.status,
                priority: deals.priority,
                stageId: deals.stageId,
                stage: deals.stage,
                contactId: deals.contactId,
                assignedToUserId: deals.assignedToUserId,
                description: deals.description,
                tags: deals.tags,
                dueDate: deals.dueDate,
                companyId: deals.companyId,
                createdAt: deals.createdAt,
                updatedAt: deals.updatedAt,
                lastActivityAt: deals.lastActivityAt,
                // Contact information
                contactName: contacts.name,
                contactPhone: contacts.phone,
                contactEmail: contacts.email,
            })
            .from(deals)
            .leftJoin(contacts, eq(deals.contactId, contacts.id))
            .where(and(...conditions))
            .orderBy(desc(deals.createdAt));

        return result.map((row: any) => ({
            ...row,
            contact: row.contactId ? {
                id: row.contactId,
                name: row.contactName,
                phone: row.contactPhone,
                email: row.contactEmail,
            } : null
        }));
    } catch (error) {
        console.error('Error getting deals:', error);
        return [];
    }
}

// Create new deal
export async function createDeal(deal: InsertDeal): Promise<Deal> {
    try {
        if (!deal.contactId) {
            throw new Error('Contact ID is required');
        }

        const processedDeal = {
            ...deal,
            dueDate: deal.dueDate ? new Date(deal.dueDate) : undefined,
            lastActivityAt: new Date(),
            createdAt: new Date(),
            updatedAt: new Date()
        };

        const [newDeal] = await db
            .insert(deals)
            .values(processedDeal)
            .returning();

        return newDeal;
    } catch (error) {
        console.error('Error creating deal:', error);
        throw error;
    }
}

// Update deal
export async function updateDeal(id: number, updates: Partial<InsertDeal>): Promise<Deal> {
    try {
        const updateData: any = { ...updates };

        // Handle date fields
        if (updateData.dueDate) {
            updateData.dueDate = new Date(updateData.dueDate);
        }

        updateData.updatedAt = new Date();

        const [updatedDeal] = await db
            .update(deals)
            .set(updateData)
            .where(eq(deals.id, id))
            .returning();

        if (!updatedDeal) {
            throw new Error(`Deal ${id} not found`);
        }

        return updatedDeal;
    } catch (error) {
        console.error(`Error updating deal with ID ${id}:`, error);
        throw error;
    }
}

// Delete deal
export async function deleteDeal(id: number, companyId?: number): Promise<{ success: boolean; reason?: string }> {
    try {
        const whereConditions = companyId
            ? and(eq(deals.id, id), eq(deals.companyId, companyId))
            : eq(deals.id, id);

        const existingDeal = await db
            .select({ id: deals.id, status: deals.status, companyId: deals.companyId })
            .from(deals)
            .where(whereConditions)
            .limit(1);

        if (!existingDeal.length) {
            return { success: false, reason: 'Deal not found' };
        }

        await db.delete(deals).where(whereConditions);

        return { success: true };
    } catch (error) {
        console.error(`Error deleting deal with ID ${id}:`, error);
        return { success: false, reason: 'Internal server error' };
    }
}

// Get linked properties for a deal
export async function getDealProperties(dealId: number): Promise<any[]> {
    try {
        const result = await db.execute(sql`
      SELECT p.id, p.name as title, p.address
      FROM deal_properties dp
      JOIN properties p ON dp.property_id = p.id
      WHERE dp.deal_id = ${dealId}
      ORDER BY dp.created_at DESC
    `);

        return result.rows || [];
    } catch (error) {
        console.error(`Error loading properties for deal ${dealId}:`, error);
        return [];
    }
}
