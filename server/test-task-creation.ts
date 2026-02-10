import { db } from './db';
import { contactTasks } from '@shared/schema';

async function testTaskCreation() {
    try {
        console.log('Testing task creation...');

        const taskData = {
            companyId: 1, // Assuming company ID 1 exists
            contactId: null,
            title: 'Test Task',
            description: 'Testing',
            priority: 'medium' as const,
            status: 'not_started' as const,
            dueDate: new Date('2026-01-18'),
            assignedTo: null,
            category: null,
            tags: null,
            checklist: null,
            backgroundColor: '#ffffff'
        };

        console.log('Task data:', JSON.stringify(taskData, null, 2));

        const [newTask] = await db
            .insert(contactTasks)
            .values(taskData)
            .returning();

        console.log('Task created successfully:', newTask);
    } catch (error) {
        console.error('Error creating task:', error);
        console.error('Error message:', (error as any).message);
        console.error('Error detail:', (error as any).detail);
        console.error('Error code:', (error as any).code);
        console.error('Full error:', JSON.stringify(error, Object.getOwnPropertyNames(error), 2));
    }

    process.exit(0);
}

testTaskCreation();
