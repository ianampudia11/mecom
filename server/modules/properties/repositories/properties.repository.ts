import { db } from '../../../db';
import { properties, dealProperties } from '@shared/schema';
import type { Property, InsertProperty } from '@shared/schema';
import { eq, and, desc, ilike } from 'drizzle-orm';

/**
 * Repository for property-related database operations
 * Extracted from monolithic storage.ts
 */

// Get single property by ID
export async function getProperty(id: number): Promise<Property | undefined> {
    try {
        const [property] = await db
            .select()
            .from(properties)
            .where(eq(properties.id, id));
        return property;
    } catch (error) {
        console.error(`Error getting property with ID ${id}:`, error);
        return undefined;
    }
}

// Get properties with filters
export async function getProperties(options: {
    companyId: number;
    filter?: any;
    limit?: number;
    offset?: number;
}): Promise<Property[]> {
    try {
        const { companyId, filter = {}, limit = 50, offset = 0 } = options;

        let query = db
            .select()
            .from(properties)
            .where(eq(properties.companyId, companyId));

        // Apply search filter
        if (filter.search) {
            query = query.where(ilike(properties.name, `%${filter.search}%`));
        }

        const result = await query
            .orderBy(desc(properties.createdAt))
            .limit(limit)
            .offset(offset);

        return result;
    } catch (error) {
        console.error('Error getting properties:', error);
        return [];
    }
}

// Create new property
export async function createProperty(property: InsertProperty): Promise<Property> {
    try {
        const [newProperty] = await db
            .insert(properties)
            .values({
                ...property,
                createdAt: new Date(),
                updatedAt: new Date()
            })
            .returning();

        return newProperty;
    } catch (error) {
        console.error('Error creating property:', error);
        throw error;
    }
}

// Update property
export async function updateProperty(id: number, updates: Partial<InsertProperty>): Promise<Property> {
    try {
        const [updatedProperty] = await db
            .update(properties)
            .set({
                ...updates,
                updatedAt: new Date()
            })
            .where(eq(properties.id, id))
            .returning();

        if (!updatedProperty) {
            throw new Error(`Property ${id} not found`);
        }

        return updatedProperty;
    } catch (error) {
        console.error(`Error updating property ${id}:`, error);
        throw error;
    }
}

// Delete property
export async function deleteProperty(id: number, companyId: number): Promise<boolean> {
    try {
        await db
            .delete(properties)
            .where(and(
                eq(properties.id, id),
                eq(properties.companyId, companyId)
            ));

        return true;
    } catch (error) {
        console.error(`Error deleting property ${id}:`, error);
        return false;
    }
}

// Link property to deal
export async function linkPropertyToDeal(propertyId: number, dealId: number): Promise<boolean> {
    try {
        await db
            .insert(dealProperties)
            .values({
                propertyId,
                dealId,
                createdAt: new Date()
            });

        return true;
    } catch (error) {
        console.error(`Error linking property ${propertyId} to deal ${dealId}:`, error);
        return false;
    }
}

// Unlink property from deal
export async function unlinkPropertyFromDeal(propertyId: number, dealId: number): Promise<boolean> {
    try {
        await db
            .delete(dealProperties)
            .where(and(
                eq(dealProperties.propertyId, propertyId),
                eq(dealProperties.dealId, dealId)
            ));

        return true;
    } catch (error) {
        console.error(`Error unlinking property ${propertyId} from deal ${dealId}:`, error);
        return false;
    }
}
