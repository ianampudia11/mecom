import { db } from '../../../db';
import { contactAppointments } from '@shared/schema';
import type { ContactAppointment, InsertContactAppointment } from '@shared/schema';
import { eq, and, desc, gte, lte } from 'drizzle-orm';

/**
 * Repository for calendar/appointment operations
 * Extracted from monolithic storage.ts
 */

// Get appointments for a contact
export async function getContactAppointments(contactId: number): Promise<ContactAppointment[]> {
    try {
        return await db
            .select()
            .from(contactAppointments)
            .where(eq(contactAppointments.contactId, contactId))
            .orderBy(desc(contactAppointments.startTime));
    } catch (error) {
        console.error(`Error getting appointments for contact ${contactId}:`, error);
        return [];
    }
}

// Get single appointment
export async function getAppointment(id: number): Promise<ContactAppointment | undefined> {
    try {
        const [appointment] = await db
            .select()
            .from(contactAppointments)
            .where(eq(contactAppointments.id, id));
        return appointment;
    } catch (error) {
        console.error(`Error getting appointment ${id}:`, error);
        return undefined;
    }
}

// Get appointments by date range
export async function getAppointmentsByDateRange(
    companyId: number,
    startDate: Date,
    endDate: Date
): Promise<ContactAppointment[]> {
    try {
        return await db
            .select()
            .from(contactAppointments)
            .where(
                and(
                    eq(contactAppointments.companyId, companyId),
                    gte(contactAppointments.startTime, startDate),
                    lte(contactAppointments.startTime, endDate)
                )
            )
            .orderBy(contactAppointments.startTime);
    } catch (error) {
        console.error('Error getting appointments by date range:', error);
        return [];
    }
}

// Create appointment
export async function createAppointment(appointment: InsertContactAppointment): Promise<ContactAppointment> {
    try {
        const [newAppointment] = await db
            .insert(contactAppointments)
            .values({
                ...appointment,
                createdAt: new Date(),
                updatedAt: new Date()
            })
            .returning();

        return newAppointment;
    } catch (error) {
        console.error('Error creating appointment:', error);
        throw error;
    }
}

// Update appointment
export async function updateAppointment(
    id: number,
    updates: Partial<InsertContactAppointment>
): Promise<ContactAppointment> {
    try {
        const [updatedAppointment] = await db
            .update(contactAppointments)
            .set({
                ...updates,
                updatedAt: new Date()
            })
            .where(eq(contactAppointments.id, id))
            .returning();

        if (!updatedAppointment) {
            throw new Error(`Appointment ${id} not found`);
        }

        return updatedAppointment;
    } catch (error) {
        console.error(`Error updating appointment ${id}:`, error);
        throw error;
    }
}

// Delete appointment
export async function deleteAppointment(id: number): Promise<boolean> {
    try {
        await db.delete(contactAppointments).where(eq(contactAppointments.id, id));
        return true;
    } catch (error) {
        console.error(`Error deleting appointment ${id}:`, error);
        return false;
    }
}
