import { db } from './server/db';
import { deals, contacts, pipelineStages, tasks } from './shared/schema';
import { eq } from 'drizzle-orm';

async function seedData() {
    try {
        console.log('🌱 Seeding test data...\n');

        // 1. Get first contact
        const contactsList = await db.select().from(contacts).limit(1);
        if (contactsList.length === 0) {
            console.log('❌ No contacts found. Please create a contact manually first or run a contact seed.');
            process.exit(1);
        }
        const contact = contactsList[0];
        console.log(`✅ Found contact: ${contact.name} (ID: ${contact.id})`);

        // 2. Get first pipeline stage
        const stagesList = await db.select().from(pipelineStages).limit(1);
        if (stagesList.length === 0) {
            console.log('❌ No pipeline stages found. Please ensure pipelines are migrated.');
            process.exit(1);
        }
        const stage = stagesList[0];
        console.log(`✅ Found stage: ${stage.name} (ID: ${stage.id})`);

        // 3. Create Deals
        console.log('\nCreating Deals...');
        const newDeals = [
            {
                companyId: contact.companyId,
                contactId: contact.id,
                title: 'Deal 1: Website Redesign',
                stageId: stage.id,
                stage: 'lead' as const,
                value: 5000,
                priority: 'high' as const,
                status: 'active',
                description: 'Full redesign of corporate website',
                tags: ['web', 'design'],
                lastActivityAt: new Date(),
                createdAt: new Date(),
                updatedAt: new Date()
            },
            {
                companyId: contact.companyId,
                contactId: contact.id,
                title: 'Deal 2: SEO Campaign',
                stageId: stage.id,
                stage: 'qualified' as const,
                value: 1500,
                priority: 'medium' as const,
                status: 'active',
                description: 'Monthly SEO optimization',
                tags: ['marketing', 'seo'],
                lastActivityAt: new Date(),
                createdAt: new Date(),
                updatedAt: new Date()
            }
        ];

        for (const deal of newDeals) {
            const [created] = await db.insert(deals).values(deal).returning();
            console.log(`  + Created deal: ${created.title} (ID: ${created.id})`);
        }

        // 4. Create Tasks
        console.log('\nCreating Tasks...');

        // Ensure companyId is number (it might be null in type definition but required in runtime?)
        // Schema says: companyId: integer("company_id").notNull()
        const companyId = contact.companyId || 1;

        const newTasks = [
            {
                companyId: companyId,
                contactId: contact.id,
                title: 'Call client to discuss requirements',
                description: 'Initial discovery call',
                priority: 'high' as const,
                status: 'not_started' as const,
                dueDate: new Date(Date.now() + 86400000), // tomorrow
                createdAt: new Date(),
                updatedAt: new Date()
            },
            {
                companyId: companyId,
                contactId: contact.id,
                title: 'Prepare proposal',
                description: 'Draft the project proposal based on notes',
                priority: 'medium' as const,
                status: 'in_progress' as const,
                dueDate: new Date(Date.now() + 172800000), // 2 days
                createdAt: new Date(),
                updatedAt: new Date()
            },
            {
                companyId: companyId,
                contactId: contact.id,
                title: 'Follow up email',
                description: 'Send follow up regarding previous items',
                priority: 'low' as const,
                status: 'completed' as const,
                dueDate: new Date(Date.now() - 86400000), // yesterday
                createdAt: new Date(),
                updatedAt: new Date()
            }
        ];

        for (const task of newTasks) {
            const [created] = await db.insert(tasks).values(task).returning();
            console.log(`  + Created task: ${created.title} (ID: ${created.id})`);
        }

        console.log('\n✅ Seeding completed successfully!');
        process.exit(0);
    } catch (error: any) {
        console.error('❌ Error seeding data:', error.message);
        console.error(error);
        process.exit(1);
    }
}

seedData();
