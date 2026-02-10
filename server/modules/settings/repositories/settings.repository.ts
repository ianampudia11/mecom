import { db } from '../../../db';
import { appSettings, companySettings } from '@shared/schema';
import { eq, and } from 'drizzle-orm';

// Define types locally since they're in storage.ts
export interface AppSetting {
    id: number;
    key: string;
    value: unknown;
    createdAt: Date;
    updatedAt: Date;
}

export interface CompanySetting {
    id: number;
    companyId: number;
    key: string;
    value: unknown;
    createdAt: Date;
    updatedAt: Date;
}

/**
 * Repository for app and company settings
 */

// App Settings
export async function getAppSetting(key: string): Promise<AppSetting | undefined> {
    try {
        const [setting] = await db
            .select()
            .from(appSettings)
            .where(eq(appSettings.key, key));
        return setting as AppSetting | undefined;
    } catch (error) {
        console.error(`Error getting app setting ${key}:`, error);
        return undefined;
    }
}

export async function getAllAppSettings(): Promise<AppSetting[]> {
    try {
        return await db.select().from(appSettings) as AppSetting[];
    } catch (error) {
        console.error('Error getting all app settings:', error);
        return [];
    }
}

export async function saveAppSetting(key: string, value: unknown): Promise<AppSetting> {
    try {
        const existing = await getAppSetting(key);

        if (existing) {
            const [updated] = await db
                .update(appSettings)
                .set({ value: value as any, updatedAt: new Date() })
                .where(eq(appSettings.key, key))
                .returning();
            return updated as AppSetting;
        } else {
            const [created] = await db
                .insert(appSettings)
                .values({
                    key,
                    value: value as any,
                    createdAt: new Date(),
                    updatedAt: new Date()
                })
                .returning();
            return created as AppSetting;
        }
    } catch (error) {
        console.error(`Error saving app setting ${key}:`, error);
        throw error;
    }
}

export async function deleteAppSetting(key: string): Promise<boolean> {
    try {
        await db.delete(appSettings).where(eq(appSettings.key, key));
        return true;
    } catch (error) {
        console.error(`Error deleting app setting ${key}:`, error);
        return false;
    }
}

// Company Settings
export async function getCompanySetting(companyId: number, key: string): Promise<CompanySetting | undefined> {
    try {
        const [setting] = await db
            .select()
            .from(companySettings)
            .where(and(
                eq(companySettings.companyId, companyId),
                eq(companySettings.key, key)
            ));
        return setting as CompanySetting | undefined;
    } catch (error) {
        console.error(`Error getting company setting ${companyId}/${key}:`, error);
        return undefined;
    }
}

export async function getAllCompanySettings(companyId: number): Promise<CompanySetting[]> {
    try {
        return await db
            .select()
            .from(companySettings)
            .where(eq(companySettings.companyId, companyId)) as CompanySetting[];
    } catch (error) {
        console.error(`Error getting all company settings for ${companyId}:`, error);
        return [];
    }
}

export async function saveCompanySetting(companyId: number, key: string, value: unknown): Promise<CompanySetting> {
    try {
        const existing = await getCompanySetting(companyId, key);

        if (existing) {
            const [updated] = await db
                .update(companySettings)
                .set({ value: value as any, updatedAt: new Date() })
                .where(and(
                    eq(companySettings.companyId, companyId),
                    eq(companySettings.key, key)
                ))
                .returning();
            return updated as CompanySetting;
        } else {
            const [created] = await db
                .insert(companySettings)
                .values({
                    companyId,
                    key,
                    value: value as any,
                    createdAt: new Date(),
                    updatedAt: new Date()
                })
                .returning();
            return created as CompanySetting;
        }
    } catch (error) {
        console.error(`Error saving company setting ${companyId}/${key}:`, error);
        throw error;
    }
}

export async function deleteCompanySetting(companyId: number, key: string): Promise<boolean> {
    try {
        await db
            .delete(companySettings)
            .where(and(
                eq(companySettings.companyId, companyId),
                eq(companySettings.key, key)
            ));
        return true;
    } catch (error) {
        console.error(`Error deleting company setting ${companyId}/${key}:`, error);
        return false;
    }
}
