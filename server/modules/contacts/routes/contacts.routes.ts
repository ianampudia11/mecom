import { Router } from 'express';
import type { Request, Response } from 'express';
import * as contactsRepo from '../repositories/contacts.repository';
// Import middleware from server root
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

/**
 * GET /api/contacts
 * List all contacts with optional filters
 */
router.get('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { search, limit, offset, includeArchived, channel, tags, dateFilter } = req.query;

        if (!user.companyId) {
            return res.status(400).json({ error: 'User must be associated with a company' });
        }

        const contacts = await contactsRepo.getContacts({
            companyId: user.companyId,
            filter: {
                search,
                includeArchived: includeArchived === 'true',
                channel: channel as string,
                tags: tags as string,
                dateFilter: dateFilter as string
            },
            limit: limit ? parseInt(limit as string) : 50,
            offset: offset ? parseInt(offset as string) : 0
        });

        res.json(contacts);
    } catch (error) {
        console.error('Error fetching contacts:', error);
        res.status(500).json({ error: 'Failed to fetch contacts' });
    }
});

/**
 * GET /api/contacts/search
 * Search contacts
 */
router.get('/search', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { q } = req.query;

        if (!q) {
            return res.status(400).json({ error: 'Search query required' });
        }

        const contacts = await contactsRepo.searchContacts(user.companyId, q as string);
        res.json(contacts);
    } catch (error) {
        console.error('Error searching contacts:', error);
        res.status(500).json({ error: 'Failed to search contacts' });
    }
});

/**
 * GET /api/contacts/:id
 * Get single contact by ID
 */
router.get('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const contact = await contactsRepo.getContact(id);

        if (!contact) {
            return res.status(404).json({ error: 'Contact not found' });
        }

        // Check company access
        if (contact.companyId !== (req.user as any).companyId) {
            return res.status(403).json({ error: 'Access denied' });
        }

        res.json(contact);
    } catch (error) {
        console.error('Error fetching contact:', error);
        res.status(500).json({ error: 'Failed to fetch contact' });
    }
});

/**
 * POST /api/contacts
 * Create a new contact
 */
router.post('/', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const contactData = {
            ...req.body,
            companyId: user.companyId
        };

        const newContact = await contactsRepo.createContact(contactData);
        res.status(201).json(newContact);
    } catch (error) {
        console.error('Error creating contact:', error);
        res.status(500).json({ error: 'Failed to create contact' });
    }
});

/**
 * PATCH /api/contacts/:id
 * Update an existing contact
 */
router.patch('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const updates = req.body;

        const updatedContact = await contactsRepo.updateContact(id, updates);
        res.json(updatedContact);
    } catch (error) {
        console.error('Error updating contact:', error);
        res.status(500).json({ error: 'Failed to update contact' });
    }
});

/**
 * DELETE /api/contacts/:id
 * Delete a contact
 */
router.delete('/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const user = req.user as any;

        const success = await contactsRepo.deleteContact(id, user.companyId);

        if (!success) {
            return res.status(404).json({ error: 'Contact not found' });
        }

        res.json({ message: 'Contact deleted successfully' });
    } catch (error) {
        console.error('Error deleting contact:', error);
        res.status(500).json({ error: 'Failed to delete contact' });
    }
});

/**
 * GET /api/contacts/tags
 * Get all contact tags
 */
router.get('/tags', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        // This would need a tags repository function
        // For now, return empty array - implement based on your tags table
        res.json([]);
    } catch (error) {
        console.error('Error fetching tags:', error);
        res.status(500).json({ error: 'Failed to fetch tags' });
    }
});

/**
 * GET /api/contacts/:id/notes
 * Get notes for a contact
 */
router.get('/:id/notes', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const contactId = parseInt(req.params.id);
        // Delegate to notes module or implement here
        res.json([]);
    } catch (error) {
        console.error('Error fetching notes:', error);
        res.status(500).json({ error: 'Failed to fetch notes' });
    }
});

/**
 * POST /api/contacts/:id/notes
 * Add note to contact
 */
router.post('/:id/notes', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const contactId = parseInt(req.params.id);
        // Implement note creation
        res.status(201).json({ message: 'Note created' });
    } catch (error) {
        console.error('Error creating note:', error);
        res.status(500).json({ error: 'Failed to create note' });
    }
});

/**
 * GET /api/contacts/:id/documents
 * Get documents for a contact
 */
router.get('/:id/documents', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const contactId = parseInt(req.params.id);
        res.json([]);
    } catch (error) {
        console.error('Error fetching documents:', error);
        res.status(500).json({ error: 'Failed to fetch documents' });
    }
});

/**
 * GET /api/contacts/:id/assigned-agent
 * Get assigned agent for contact
 */
router.get('/:id/assigned-agent', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const contactId = parseInt(req.params.id);
        res.json(null);
    } catch (error) {
        console.error('Error fetching assigned agent:', error);
        res.status(500).json({ error: 'Failed to fetch assigned agent' });
    }
});

/**
 * GET /api/contacts/:id/interactions
 * Get interactions for a contact
 */
router.get('/:id/interactions', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const contactId = parseInt(req.params.id);
        res.json([]);
    } catch (error) {
        console.error('Error fetching interactions:', error);
        res.status(500).json({ error: 'Failed to fetch interactions' });
    }
});

/**
 * GET /api/contacts/:id/audit-logs
 * Get audit logs for a contact
 */
router.get('/:id/audit-logs', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const contactId = parseInt(req.params.id);
        const { limit } = req.query;
        res.json([]);
    } catch (error) {
        console.error('Error fetching audit logs:', error);
        res.status(500).json({ error: 'Failed to fetch audit logs' });
    }
});

/**
 * GET /api/contacts/:id/tasks
 * Get tasks for a contact
 */
router.get('/:id/tasks', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const contactId = parseInt(req.params.id);
        const { status, priority, search } = req.query;
        res.json([]);
    } catch (error) {
        console.error('Error fetching tasks:', error);
        res.status(500).json({ error: 'Failed to fetch tasks' });
    }
});

/**
 * POST /api/contacts/:id/archive
 * Archive a contact
 */
router.post('/:id/archive', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const contactId = parseInt(req.params.id);
        const user = req.user as any;

        const success = await contactsRepo.archiveContact(contactId, user.companyId);

        if (!success) {
            return res.status(404).json({ error: 'Contact not found' });
        }

        res.json({ message: 'Contact archived successfully' });
    } catch (error) {
        console.error('Error archiving contact:', error);
        res.status(500).json({ error: 'Failed to archive contact' });
    }
});

/**
 * DELETE /api/contacts/:id/archive
 * Unarchive a contact
 */
router.delete('/:id/archive', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const contactId = parseInt(req.params.id);
        const user = req.user as any;

        const success = await contactsRepo.unarchiveContact(contactId, user.companyId);

        if (!success) {
            return res.status(404).json({ error: 'Contact not found' });
        }

        res.json({ message: 'Contact unarchived successfully' });
    } catch (error) {
        console.error('Error unarchiving contact:', error);
        res.status(500).json({ error: 'Failed to unarchive contact' });
    }
});

/**
 * POST /api/contacts/:id/update-profile-picture
 * Update contact profile picture
 */
router.post('/:id/update-profile-picture', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const contactId = parseInt(req.params.id);
        // Implement profile picture update
        res.json({ message: 'Profile picture updated' });
    } catch (error) {
        console.error('Error updating profile picture:', error);
        res.status(500).json({ error: 'Failed to update profile picture' });
    }
});

export default router;
