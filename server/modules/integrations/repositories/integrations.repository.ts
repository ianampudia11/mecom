import { db } from '../../../db';
import { googleCalendarTokens, zohoCalendarTokens, calendlyCalendarTokens } from '@shared/schema';
import { eq, and } from 'drizzle-orm';

export interface GoogleTokens {
    access_token: string;
    refresh_token?: string;
    id_token?: string;
    token_type?: string;
    expiry_date?: number;
    scope?: string;
}

export interface ZohoTokens {
    access_token: string;
    refresh_token?: string;
    token_type?: string;
    expires_in?: number;
    scope?: string;
    updatedAt?: Date;
}

export interface CalendlyTokens {
    access_token: string;
    refresh_token?: string;
    token_type?: string;
    expires_in?: number;
    scope?: string;
    updatedAt?: Date;
}

/**
 * Repository for calendar integrations (Google, Zoho, Calendly)
 */

// Google Calendar
export async function getGoogleTokens(userId: number, companyId: number): Promise<GoogleTokens | null> {
    try {
        const [result] = await db
            .select()
            .from(googleCalendarTokens)
            .where(and(
                eq(googleCalendarTokens.userId, userId),
                eq(googleCalendarTokens.companyId, companyId)
            ));

        if (!result) return null;

        return {
            access_token: result.accessToken,
            refresh_token: result.refreshToken || undefined,
            id_token: result.idToken || undefined,
            token_type: result.tokenType || undefined,
            expiry_date: result.expiryDate ? result.expiryDate.getTime() : undefined,
            scope: result.scope || undefined
        };
    } catch (error) {
        console.error('Error getting Google tokens:', error);
        return null;
    }
}

export async function saveGoogleTokens(userId: number, companyId: number, tokens: GoogleTokens): Promise<boolean> {
    try {
        const existing = await getGoogleTokens(userId, companyId);

        const tokenData = {
            userId,
            companyId,
            accessToken: tokens.access_token,
            refreshToken: tokens.refresh_token || null,
            idToken: tokens.id_token || null,
            tokenType: tokens.token_type || null,
            expiryDate: tokens.expiry_date ? new Date(tokens.expiry_date) : null,
            scope: tokens.scope || null,
            updatedAt: new Date()
        };

        if (existing) {
            await db
                .update(googleCalendarTokens)
                .set(tokenData)
                .where(and(
                    eq(googleCalendarTokens.userId, userId),
                    eq(googleCalendarTokens.companyId, companyId)
                ));
        } else {
            await db
                .insert(googleCalendarTokens)
                .values({
                    ...tokenData,
                    createdAt: new Date()
                });
        }

        return true;
    } catch (error) {
        console.error('Error saving Google tokens:', error);
        return false;
    }
}

export async function deleteGoogleTokens(userId: number, companyId: number): Promise<boolean> {
    try {
        await db
            .delete(googleCalendarTokens)
            .where(and(
                eq(googleCalendarTokens.userId, userId),
                eq(googleCalendarTokens.companyId, companyId)
            ));
        return true;
    } catch (error) {
        console.error('Error deleting Google tokens:', error);
        return false;
    }
}

// Zoho Calendar
export async function getZohoTokens(userId: number, companyId: number): Promise<ZohoTokens | null> {
    try {
        const [result] = await db
            .select()
            .from(zohoCalendarTokens)
            .where(and(
                eq(zohoCalendarTokens.userId, userId),
                eq(zohoCalendarTokens.companyId, companyId)
            ));

        if (!result) return null;

        return {
            access_token: result.accessToken,
            refresh_token: result.refreshToken || undefined,
            token_type: result.tokenType || undefined,
            expires_in: result.expiresIn || undefined,
            scope: result.scope || undefined,
            updatedAt: result.updatedAt
        };
    } catch (error) {
        console.error('Error getting Zoho tokens:', error);
        return null;
    }
}

export async function saveZohoTokens(userId: number, companyId: number, tokens: ZohoTokens): Promise<boolean> {
    try {
        const existing = await getZohoTokens(userId, companyId);

        const tokenData = {
            userId,
            companyId,
            accessToken: tokens.access_token,
            refreshToken: tokens.refresh_token || null,
            tokenType: tokens.token_type || null,
            expiresIn: tokens.expires_in || null,
            scope: tokens.scope || null,
            updatedAt: new Date()
        };

        if (existing) {
            await db
                .update(zohoCalendarTokens)
                .set(tokenData)
                .where(and(
                    eq(zohoCalendarTokens.userId, userId),
                    eq(zohoCalendarTokens.companyId, companyId)
                ));
        } else {
            await db
                .insert(zohoCalendarTokens)
                .values({
                    ...tokenData,
                    createdAt: new Date()
                });
        }

        return true;
    } catch (error) {
        console.error('Error saving Zoho tokens:', error);
        return false;
    }
}

export async function deleteZohoTokens(userId: number, companyId: number): Promise<boolean> {
    try {
        await db
            .delete(zohoCalendarTokens)
            .where(and(
                eq(zohoCalendarTokens.userId, userId),
                eq(zohoCalendarTokens.companyId, companyId)
            ));
        return true;
    } catch (error) {
        console.error('Error deleting Zoho tokens:', error);
        return false;
    }
}

// Calendly
export async function getCalendlyTokens(userId: number, companyId: number): Promise<CalendlyTokens | null> {
    try {
        const [result] = await db
            .select()
            .from(calendlyCalendarTokens)
            .where(and(
                eq(calendlyCalendarTokens.userId, userId),
                eq(calendlyCalendarTokens.companyId, companyId)
            ));

        if (!result) return null;

        return {
            access_token: result.accessToken,
            refresh_token: result.refreshToken || undefined,
            token_type: result.tokenType || undefined,
            expires_in: result.expiresIn || undefined,
            scope: result.scope || undefined,
            updatedAt: result.updatedAt
        };
    } catch (error) {
        console.error('Error getting Calendly tokens:', error);
        return null;
    }
}

export async function saveCalendlyTokens(userId: number, companyId: number, tokens: CalendlyTokens): Promise<boolean> {
    try {
        const existing = await getCalendlyTokens(userId, companyId);

        const tokenData = {
            userId,
            companyId,
            accessToken: tokens.access_token,
            refreshToken: tokens.refresh_token || null,
            tokenType: tokens.token_type || null,
            expiresIn: tokens.expires_in || null,
            scope: tokens.scope || null,
            updatedAt: new Date()
        };

        if (existing) {
            await db
                .update(calendlyCalendarTokens)
                .set(tokenData)
                .where(and(
                    eq(calendlyCalendarTokens.userId, userId),
                    eq(calendlyCalendarTokens.companyId, companyId)
                ));
        } else {
            await db
                .insert(calendlyCalendarTokens)
                .values({
                    ...tokenData,
                    createdAt: new Date()
                });
        }

        return true;
    } catch (error) {
        console.error('Error saving Calendly tokens:', error);
        return false;
    }
}

export async function deleteCalendlyTokens(userId: number, companyId: number): Promise<boolean> {
    try {
        await db
            .delete(calendlyCalendarTokens)
            .where(and(
                eq(calendlyCalendarTokens.userId, userId),
                eq(calendlyCalendarTokens.companyId, companyId)
            ));
        return true;
    } catch (error) {
        console.error('Error deleting Calendly tokens:', error);
        return false;
    }
}
