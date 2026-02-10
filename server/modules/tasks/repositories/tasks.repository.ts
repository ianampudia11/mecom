import { db } from '../../../db';
import { contactTasks, taskCategories } from '@shared/schema';
import type { ContactTask, InsertContactTask, TaskCategory, InsertTaskCategory } from '@shared/schema';
import { eq, and, desc, or } from 'drizzle-orm';

/**
 * Repository for task-related database operations  
 * Extracted from monolithic storage.ts
 */

// Get tasks for a contact
export async function getContactTasks(contactId: number): Promise<ContactTask[]> {
    try {
        return await db
            .select()
            .from(contactTasks)
            .where(eq(contactTasks.contactId, contactId))
            .orderBy(desc(contactTasks.createdAt));
    } catch (error) {
        console.error(`Error getting tasks for contact ${contactId}:`, error);
        return [];
    }
}

// Get single task
export async function getTask(id: number): Promise<ContactTask | undefined> {
    try {
        const [task] = await db
            .select()
            .from(contactTasks)
            .where(eq(contactTasks.id, id));
        return task;
    } catch (error) {
        console.error(`Error getting task ${id}:`, error);
        return undefined;
    }
}

// Get all tasks for a company
export async function getAllTasks(companyId: number): Promise<ContactTask[]> {
    try {
        return await db
            .select()
            .from(contactTasks)
            .where(eq(contactTasks.companyId, companyId))
            .orderBy(desc(contactTasks.createdAt));
    } catch (error) {
        console.error(`Error getting all tasks for company ${companyId}:`, error);
        return [];
    }
}


// Create task
export async function createTask(task: InsertContactTask): Promise<ContactTask> {
    try {
        console.log('[TASK REPO] Creating task with data:', JSON.stringify(task, null, 2));

        const [newTask] = await db
            .insert(contactTasks)
            .values(task)
            .returning();

        console.log('[TASK REPO] Task created successfully:', newTask.id);
        return newTask;
    } catch (error) {
        console.error('[TASK REPO] Error creating task:', error);
        console.error('[TASK REPO] Error message:', (error as any).message);
        console.error('[TASK REPO] Error detail:', (error as any).detail);
        console.error('[TASK REPO] Error code:', (error as any).code);
        console.error('[TASK REPO] Full error:', JSON.stringify(error, Object.getOwnPropertyNames(error), 2));
        throw error;
    }
}

// Update task
export async function updateTask(id: number, updates: Partial<InsertContactTask>): Promise<ContactTask> {
    try {
        const [updatedTask] = await db
            .update(contactTasks)
            .set({
                ...updates,
                updatedAt: new Date()
            })
            .where(eq(contactTasks.id, id))
            .returning();

        if (!updatedTask) {
            throw new Error(`Task ${id} not found`);
        }

        return updatedTask;
    } catch (error) {
        console.error(`Error updating task ${id}:`, error);
        throw error;
    }
}

// Delete task
export async function deleteTask(id: number): Promise<boolean> {
    try {
        await db.delete(contactTasks).where(eq(contactTasks.id, id));
        return true;
    } catch (error) {
        console.error(`Error deleting task ${id}:`, error);
        return false;
    }
}

// Get task categories
export async function getTaskCategories(companyId: number): Promise<TaskCategory[]> {
    try {
        return await db
            .select()
            .from(taskCategories)
            .where(eq(taskCategories.companyId, companyId))
            .orderBy(taskCategories.name);
    } catch (error) {
        console.error(`Error getting task categories for company ${companyId}:`, error);
        return [];
    }
}

// Create task category  
export async function createTaskCategory(category: InsertTaskCategory): Promise<TaskCategory> {
    try {
        const [newCategory] = await db
            .insert(taskCategories)
            .values(category)
            .returning();

        return newCategory;
    } catch (error) {
        console.error('Error creating task category:', error);
        throw error;
    }
}

// Update task category
export async function updateTaskCategory(id: number, updates: Partial<InsertTaskCategory>): Promise<TaskCategory> {
    try {
        const [updatedCategory] = await db
            .update(taskCategories)
            .set({
                ...updates,
                updatedAt: new Date()
            })
            .where(eq(taskCategories.id, id))
            .returning();

        if (!updatedCategory) {
            throw new Error(`Task category ${id} not found`);
        }

        return updatedCategory;
    } catch (error) {
        console.error(`Error updating task category ${id}:`, error);
        throw error;
    }
}

// Delete task category
export async function deleteTaskCategory(id: number, companyId: number): Promise<boolean> {
    try {
        await db
            .delete(taskCategories)
            .where(and(
                eq(taskCategories.id, id),
                eq(taskCategories.companyId, companyId)
            ));

        return true;
    } catch (error) {
        console.error(`Error deleting task category ${id}:`, error);
        return false;
    }
}
