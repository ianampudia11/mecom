import { db } from '../../../db';
import { notes } from '@shared/schema';
import type { Note, InsertNote } from '@shared/schema';
import { eq, desc } from 'drizzle-orm';

/**
 * Repository for notes operations
 */

// Get notes by contact
export async function getNotesByContact(contactId: number): Promise<Note[]> {
    try {
        return await db
            .select()
            .from(notes)
            .where(eq(notes.contactId, contactId))
            .orderBy(desc(notes.createdAt));
    } catch (error) {
        console.error(`Error getting notes for contact ${contactId}:`, error);
        return [];
    }
}

// Create note
export async function createNote(note: InsertNote): Promise<Note> {
    try {
        const [newNote] = await db
            .insert(notes)
            .values({
                ...note,
                createdAt: new Date(),
                updatedAt: new Date()
            })
            .returning();

        return newNote;
    } catch (error) {
        console.error('Error creating note:', error);
        throw error;
    }
}
