import { db } from '../../../db';
import { websites, websiteAssets } from '@shared/schema';
import type { Website, InsertWebsite, WebsiteAsset, InsertWebsiteAsset } from '@shared/schema';
import { eq, and, desc } from 'drizzle-orm';

/**
 * Repository for website management
 */

// Websites
export async function getWebsites(companyId?: number): Promise<Website[]> {
    try {
        if (companyId) {
            return await db
                .select()
                .from(websites)
                .where(eq(websites.companyId, companyId))
                .orderBy(desc(websites.createdAt));
        }
        return await db.select().from(websites).orderBy(desc(websites.createdAt));
    } catch (error) {
        console.error('Error getting websites:', error);
        return [];
    }
}

export async function getWebsite(id: number): Promise<Website | undefined> {
    try {
        const [website] = await db
            .select()
            .from(websites)
            .where(eq(websites.id, id));
        return website;
    } catch (error) {
        console.error(`Error getting website ${id}:`, error);
        return undefined;
    }
}

export async function getWebsiteBySlug(slug: string): Promise<Website | undefined> {
    try {
        const [website] = await db
            .select()
            .from(websites)
            .where(eq(websites.slug, slug));
        return website;
    } catch (error) {
        console.error(`Error getting website by slug ${slug}:`, error);
        return undefined;
    }
}

export async function getPublishedWebsite(): Promise<Website | undefined> {
    try {
        const [website] = await db
            .select()
            .from(websites)
            .where(eq(websites.status, 'published'))
            .orderBy(desc(websites.updatedAt))
            .limit(1);
        return website;
    } catch (error) {
        console.error('Error getting published website:', error);
        return undefined;
    }
}

export async function createWebsite(website: InsertWebsite): Promise<Website> {
    try {
        const [newWebsite] = await db
            .insert(websites)
            .values({
                ...website,
                createdAt: new Date(),
                updatedAt: new Date()
            })
            .returning();
        return newWebsite;
    } catch (error) {
        console.error('Error creating website:', error);
        throw error;
    }
}

export async function updateWebsite(id: number, updates: Partial<InsertWebsite>): Promise<Website> {
    try {
        const [updated] = await db
            .update(websites)
            .set({ ...updates, updatedAt: new Date() })
            .where(eq(websites.id, id))
            .returning();

        if (!updated) {
            throw new Error(`Website ${id} not found`);
        }

        return updated;
    } catch (error) {
        console.error(`Error updating website ${id}:`, error);
        throw error;
    }
}

export async function deleteWebsite(id: number): Promise<boolean> {
    try {
        await db.delete(websites).where(eq(websites.id, id));
        return true;
    } catch (error) {
        console.error(`Error deleting website ${id}:`, error);
        return false;
    }
}

// Website Assets
export async function getWebsiteAssets(websiteId: number): Promise<WebsiteAsset[]> {
    try {
        return await db
            .select()
            .from(websiteAssets)
            .where(eq(websiteAssets.websiteId, websiteId))
            .orderBy(desc(websiteAssets.createdAt));
    } catch (error) {
        console.error(`Error getting assets for website ${websiteId}:`, error);
        return [];
    }
}

export async function createWebsiteAsset(asset: InsertWebsiteAsset): Promise<WebsiteAsset> {
    try {
        const [newAsset] = await db
            .insert(websiteAssets)
            .values({
                ...asset,
                createdAt: new Date()
            })
            .returning();
        return newAsset;
    } catch (error) {
        console.error('Error creating website asset:', error);
        throw error;
    }
}

export async function deleteWebsiteAsset(id: number): Promise<boolean> {
    try {
        await db.delete(websiteAssets).where(eq(websiteAssets.id, id));
        return true;
    } catch (error) {
        console.error(`Error deleting website asset ${id}:`, error);
        return false;
    }
}
