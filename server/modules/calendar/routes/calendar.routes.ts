import { Router } from 'express';
import type { Request, Response } from 'express';
import * as calendarRepo from '../repositories/calendar.repository';
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

/**
 * GET /api/calendar/appointments/contact/:contactId
 * Get all appointments for a contact
 * IMPORTANT: Specific routes before /:id
 */
router.get('/appointments/contact/:contactId', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const contactId = parseInt(req.params.contactId);
        const appointments = await calendarRepo.getContactAppointments(contactId);
        res.json(appointments);
    } catch (error) {
        console.error('Error fetching contact appointments:', error);
        res.status(500).json({ error: 'Failed to fetch appointments' });
    }
});

/**
 * GET /api/calendar/appointments/range
 * Get appointments by date range
 */
router.get('/appointments/range', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { startDate, endDate } = req.query;

        if (!startDate || !endDate) {
            return res.status(400).json({ error: 'startDate and endDate are required' });
        }

        const appointments = await calendarRepo.getAppointmentsByDateRange(
            user.companyId,
            new Date(startDate as string),
            new Date(endDate as string)
        );

        res.json(appointments);
    } catch (error) {
        console.error('Error fetching appointments by range:', error);
        res.status(500).json({ error: 'Failed to fetch appointments' });
    }
});

/**
 * GET /api/calendar/appointments/:id
 * Get single appointment by ID
 */
router.get('/appointments/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const appointment = await calendarRepo.getAppointment(id);

        if (!appointment) {
            return res.status(404).json({ error: 'Appointment not found' });
        }

        res.json(appointment);
    } catch (error) {
        console.error('Error fetching appointment:', error);
        res.status(500).json({ error: 'Failed to fetch appointment' });
    }
});

/**
 * POST /api/calendar/appointments
 * Create a new appointment
 */
router.post('/appointments', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const appointmentData = {
            ...req.body,
            companyId: user.companyId
        };

        const newAppointment = await calendarRepo.createAppointment(appointmentData);
        res.status(201).json(newAppointment);
    } catch (error) {
        console.error('Error creating appointment:', error);
        res.status(500).json({ error: 'Failed to create appointment' });
    }
});

/**
 * PATCH /api/calendar/appointments/:id
 * Update an appointment
 */
router.patch('/appointments/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const updates = req.body;

        const updatedAppointment = await calendarRepo.updateAppointment(id, updates);
        res.json(updatedAppointment);
    } catch (error) {
        console.error('Error updating appointment:', error);
        res.status(500).json({ error: 'Failed to update appointment' });
    }
});

/**
 * DELETE /api/calendar/appointments/:id
 * Delete an appointment
 */
router.delete('/appointments/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const success = await calendarRepo.deleteAppointment(id);

        if (!success) {
            return res.status(404).json({ error: 'Appointment not found' });
        }

        res.json({ message: 'Appointment deleted successfully' });
    } catch (error) {
        console.error('Error deleting appointment:', error);
        res.status(500).json({ error: 'Failed to delete appointment' });
    }
});

export default router;
