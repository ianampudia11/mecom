import { Router } from 'express';
import type { Request, Response } from 'express';
import * as notesRepo from '../repositories/notes.repository';
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

/**
 * GET /api/notes/contact/:contactId
 * Get notes for a contact
 */
router.get('/contact/:contactId', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const contactId = parseInt(req.params.contactId);
        const notes = await notesRepo.getNotesByContact(contactId);
        res.json(notes);
    } catch (error) {
        console.error('Error fetching notes:', error);
        res.status(500).json({ error: 'Failed to fetch notes' });
    }
});

/**
 * POST /api/notes
 * Create a new note
 */
router.post('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const noteData = req.body;
        const newNote = await notesRepo.createNote(noteData);
        res.status(201).json(newNote);
    } catch (error) {
        console.error('Error creating note:', error);
        res.status(500).json({ error: 'Failed to create note' });
    }
});

export default router;
