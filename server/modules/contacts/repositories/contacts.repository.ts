import { db } from '../../../db';
import { contacts } from '@shared/schema';
import type { Contact, InsertContact } from '@shared/schema';
import { eq, and, desc, or, sql, like, ilike } from 'drizzle-orm';

/**
 * Repository for contact-related database operations
 * Extracted from monolithic storage.ts
 */

// Get single contact by ID
export async function getContact(id: number): Promise<Contact | undefined> {
    try {
        const [contact] = await db
            .select()
            .from(contacts)
            .where(eq(contacts.id, id));
        return contact;
    } catch (error) {
        console.error(`Error getting contact with ID ${id}:`, error);
        return undefined;
    }
}

// Get contacts with filters
export async function getContacts(options: {
    companyId: number;
    filter?: any;
    limit?: number;
    offset?: number;
}): Promise<{ contacts: Contact[]; total: number }> {
    try {
        const { companyId, filter = {}, limit = 50, offset = 0 } = options;

        const conditions = [eq(contacts.companyId, companyId)];

        // Apply search filter if provided
        if (filter.search) {
            conditions.push(
                or(
                    ilike(contacts.name, `%${filter.search}%`),
                    ilike(contacts.phone, `%${filter.search}%`),
                    ilike(contacts.email, `%${filter.search}%`)
                ) as any
            );
        }

        // Get total count
        const totalResult = await db
            .select({ count: sql<number>`count(*)` })
            .from(contacts)
            .where(and(...conditions));

        const total = Number(totalResult[0]?.count || 0);

        // Get paginated results
        const result = await db
            .select()
            .from(contacts)
            .where(and(...conditions))
            .orderBy(desc(contacts.createdAt))
            .limit(limit)
            .offset(offset);

        return { contacts: result, total };
    } catch (error) {
        console.error('Error getting contacts:', error);
        return { contacts: [], total: 0 };
    }
}

// Create new contact
export async function createContact(contact: InsertContact): Promise<Contact> {
    try {
        const [newContact] = await db
            .insert(contacts)
            .values({
                ...contact,
                createdAt: new Date(),
                updatedAt: new Date()
            })
            .returning();

        return newContact;
    } catch (error) {
        console.error('Error creating contact:', error);
        throw error;
    }
}

// Update contact
export async function updateContact(id: number, updates: Partial<InsertContact>): Promise<Contact> {
    try {
        const [updatedContact] = await db
            .update(contacts)
            .set({
                ...updates,
                updatedAt: new Date()
            })
            .where(eq(contacts.id, id))
            .returning();

        if (!updatedContact) {
            throw new Error(`Contact ${id} not found`);
        }

        return updatedContact;
    } catch (error) {
        console.error(`Error updating contact ${id}:`, error);
        throw error;
    }
}

// Delete contact
export async function deleteContact(id: number, companyId: number): Promise<boolean> {
    try {
        await db
            .delete(contacts)
            .where(and(
                eq(contacts.id, id),
                eq(contacts.companyId, companyId)
            ));

        return true;
    } catch (error) {
        console.error(`Error deleting contact ${id}:`, error);
        return false;
    }
}

// Search contacts
export async function searchContacts(companyId: number, searchTerm: string): Promise<Contact[]> {
    try {
        const result = await db
            .select()
            .from(contacts)
            .where(
                and(
                    eq(contacts.companyId, companyId),
                    or(
                        ilike(contacts.name, `%${searchTerm}%`),
                        ilike(contacts.phone, `%${searchTerm}%`),
                        ilike(contacts.email, `%${searchTerm}%`)
                    )
                )
            )
            .limit(50);

        return result;
    } catch (error) {
        console.error('Error searching contacts:', error);
        return [];
    }
}

// Get contact by phone
export async function getContactByPhone(phone: string, companyId: number): Promise<Contact | null> {
    try {
        const [contact] = await db
            .select()
            .from(contacts)
            .where(
                and(
                    eq(contacts.phone, phone),
                    eq(contacts.companyId, companyId)
                )
            )
            .limit(1);

        return contact || null;
    } catch (error) {
        console.error(`Error getting contact by phone ${phone}:`, error);
        return null;
    }
}

// Get contact by email
export async function getContactByEmail(email: string, companyId: number): Promise<Contact | null> {
    try {
        const [contact] = await db
            .select()
            .from(contacts)
            .where(
                and(
                    eq(contacts.email, email),
                    eq(contacts.companyId, companyId)
                )
            )
            .limit(1);

        return contact || null;
    } catch (error) {
        console.error(`Error getting contact by email ${email}:`, error);
        return null;
    }
}

// Archive contact
export async function archiveContact(id: number, companyId: number): Promise<boolean> {
    try {
        await db
            .update(contacts)
            .set({
                isArchived: true,
                updatedAt: new Date()
            })
            .where(and(
                eq(contacts.id, id),
                eq(contacts.companyId, companyId)
            ));

        return true;
    } catch (error) {
        console.error(`Error archiving contact ${id}:`, error);
        return false;
    }
}

// Unarchive contact
export async function unarchiveContact(id: number, companyId: number): Promise<boolean> {
    try {
        await db
            .update(contacts)
            .set({
                isArchived: false,
                updatedAt: new Date()
            })
            .where(and(
                eq(contacts.id, id),
                eq(contacts.companyId, companyId)
            ));

        return true;
    } catch (error) {
        console.error(`Error unarchiving contact ${id}:`, error);
        return false;
    }
}
