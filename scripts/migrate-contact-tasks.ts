
import { db } from "../server/db";
import { tasks, contactTasks } from "../shared/schema";
import { eq } from "drizzle-orm";

const TASKS_BATCH_SIZE = 100;

async function migrateTasks() {
    console.log("Starting tasks migration...");

    try {
        // Fetch all contact tasks
        const existingContactTasks = await db.select().from(contactTasks);
        console.log(`Found ${existingContactTasks.length} contact tasks to migrate.`);

        if (existingContactTasks.length === 0) {
            console.log("No tasks to migrate.");
            process.exit(0);
        }

        let migratedCount = 0;

        // Process in chunks or just all at once (assuming not huge for now)
        for (const contactTask of existingContactTasks) {
            // Map status
            let status: 'not_started' | 'in_progress' | 'completed' | 'cancelled' = 'not_started';
            if (contactTask.status === 'pending') status = 'not_started'; // Assumption
            else if (contactTask.status === 'in_progress') status = 'in_progress';
            else if (contactTask.status === 'completed') status = 'completed';
            else if (contactTask.status === 'cancelled') status = 'cancelled';
            else status = 'not_started'; // Default fallback

            // Map priority
            let priority: 'low' | 'medium' | 'high' | 'urgent' = 'medium';
            if (contactTask.priority === 'low') priority = 'low';
            else if (contactTask.priority === 'high') priority = 'high';
            else if (contactTask.priority === 'urgent') priority = 'urgent';
            else priority = 'medium';

            await db.insert(tasks).values({
                contactId: contactTask.contactId,
                companyId: contactTask.companyId,
                title: contactTask.title,
                description: contactTask.description,
                status: status,
                priority: priority,
                dueDate: contactTask.dueDate ? new Date(contactTask.dueDate) : null,
                completedAt: contactTask.completedAt ? new Date(contactTask.completedAt) : null,
                createdAt: contactTask.createdAt ? new Date(contactTask.createdAt) : new Date(),
                updatedAt: contactTask.updatedAt ? new Date(contactTask.updatedAt) : new Date(),
                assignedTo: null, // Legacy didn't have easy assignedTo maybe? default to null.
                checklist: null,
                tags: null
            });
            migratedCount++;
        }

        console.log(`Successfully migrated ${migratedCount} tasks.`);

    } catch (error) {
        console.error("Migration failed:", error);
        process.exit(1);
    }

    process.exit(0);
}

migrateTasks();
