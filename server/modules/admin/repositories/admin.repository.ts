import { db } from '../../../db';
import { users, companies } from '@shared/schema';
import type { User, InsertUser, Company, InsertCompany } from '@shared/schema';
import { eq, and, desc, ilike } from 'drizzle-orm';

/**
 * Repository for admin operations (users, companies)
 * Extracted from monolithic storage.ts and admin-routes.ts
 */

// ============ USER MANAGEMENT ============

// Get user by ID
export async function getUser(id: number): Promise<User | undefined> {
    try {
        const [user] = await db
            .select()
            .from(users)
            .where(eq(users.id, id));
        return user;
    } catch (error) {
        console.error(`Error getting user ${id}:`, error);
        return undefined;
    }
}

// Get users for a company
export async function getCompanyUsers(companyId: number): Promise<User[]> {
    try {
        return await db
            .select()
            .from(users)
            .where(eq(users.companyId, companyId))
            .orderBy(desc(users.createdAt));
    } catch (error) {
        console.error(`Error getting users for company ${companyId}:`, error);
        return [];
    }
}

// Create user
export async function createUser(user: InsertUser): Promise<User> {
    try {
        const [newUser] = await db
            .insert(users)
            .values({
                ...user,
                createdAt: new Date(),
                updatedAt: new Date()
            })
            .returning();

        return newUser;
    } catch (error) {
        console.error('Error creating user:', error);
        throw error;
    }
}

// Update user
export async function updateUser(id: number, updates: Partial<InsertUser>): Promise<User> {
    try {
        const [updatedUser] = await db
            .update(users)
            .set({
                ...updates,
                updatedAt: new Date()
            })
            .where(eq(users.id, id))
            .returning();

        if (!updatedUser) {
            throw new Error(`User ${id} not found`);
        }

        return updatedUser;
    } catch (error) {
        console.error(`Error updating user ${id}:`, error);
        throw error;
    }
}

// Delete user
export async function deleteUser(id: number): Promise<boolean> {
    try {
        await db.delete(users).where(eq(users.id, id));
        return true;
    } catch (error) {
        console.error(`Error deleting user ${id}:`, error);
        return false;
    }
}

// ============ COMPANY MANAGEMENT ============

// Get company by ID
export async function getCompany(id: number): Promise<Company | undefined> {
    try {
        const [company] = await db
            .select()
            .from(companies)
            .where(eq(companies.id, id));
        return company;
    } catch (error) {
        console.error(`Error getting company ${id}:`, error);
        return undefined;
    }
}

// Get all companies
export async function getCompanies(): Promise<Company[]> {
    try {
        return await db
            .select()
            .from(companies)
            .orderBy(desc(companies.createdAt));
    } catch (error) {
        console.error('Error getting companies:', error);
        return [];
    }
}

// Create company
export async function createCompany(company: InsertCompany): Promise<Company> {
    try {
        const [newCompany] = await db
            .insert(companies)
            .values({
                ...company,
                createdAt: new Date(),
                updatedAt: new Date()
            })
            .returning();

        return newCompany;
    } catch (error) {
        console.error('Error creating company:', error);
        throw error;
    }
}

// Update company
export async function updateCompany(id: number, updates: Partial<InsertCompany>): Promise<Company> {
    try {
        const [updatedCompany] = await db
            .update(companies)
            .set({
                ...updates,
                updatedAt: new Date()
            })
            .where(eq(companies.id, id))
            .returning();

        if (!updatedCompany) {
            throw new Error(`Company ${id} not found`);
        }

        return updatedCompany;
    } catch (error) {
        console.error(`Error updating company ${id}:`, error);
        throw error;
    }
}

// Delete company
export async function deleteCompany(id: number): Promise<boolean> {
    try {
        await db.delete(companies).where(eq(companies.id, id));
        return true;
    } catch (error) {
        console.error(`Error deleting company ${id}:`, error);
        return false;
    }
}
