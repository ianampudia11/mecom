import { db } from '../../../db';
import { languages, translationNamespaces, translationKeys, translations } from '@shared/schema';
import { eq, and } from 'drizzle-orm';

/**
 * Repository for languages and translations management
 */

// Languages
export async function getAllLanguages() {
    try {
        return await db.select().from(languages);
    } catch (error) {
        console.error('Error getting languages:', error);
        return [];
    }
}

export async function getLanguageByCode(code: string) {
    try {
        const [lang] = await db.select().from(languages).where(eq(languages.code, code));
        return lang;
    } catch (error) {
        console.error(`Error getting language ${code}:`, error);
        return undefined;
    }
}

// Translation Namespaces
export async function getAllNamespaces() {
    try {
        return await db.select().from(translationNamespaces);
    } catch (error) {
        console.error('Error getting namespaces:', error);
        return [];
    }
}

// Translation Keys
export async function getAllKeys(namespaceId?: number) {
    try {
        if (namespaceId) {
            return await db.select().from(translationKeys).where(eq(translationKeys.namespaceId, namespaceId));
        }
        return await db.select().from(translationKeys);
    } catch (error) {
        console.error('Error getting keys:', error);
        return [];
    }
}

// Translations
export async function getAllTranslations(languageId?: number, keyId?: number) {
    try {
        const conditions = [];
        if (languageId) conditions.push(eq(translations.languageId, languageId));
        if (keyId) conditions.push(eq(translations.keyId, keyId));

        if (conditions.length > 0) {
            return await db.select().from(translations).where(and(...conditions));
        }
        return await db.select().from(translations);
    } catch (error) {
        console.error('Error getting translations:', error);
        return [];
    }
}
