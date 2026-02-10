import { db } from './server/db';
import { deals, contacts, pipelineStages } from './shared/schema';
import { eq } from 'drizzle-orm';

async function createTestDeal() {
    try {
        console.log('🧪 Testing deal creation...\n');

        // Get first contact
        const contactsList = await db.select().from(contacts).limit(1);
        if (contactsList.length === 0) {
            console.log('❌ No contacts found. Please create a contact first.');
            process.exit(1);
        }
        const contact = contactsList[0];
        console.log(`✅ Found contact: ${contact.name} (ID: ${contact.id})`);

        // Get first pipeline stage
        const stagesList = await db.select().from(pipelineStages).limit(1);
        if (stagesList.length === 0) {
            console.log('❌ No pipeline stages found.');
            process.exit(1);
        }
        const stage = stagesList[0];
        console.log(`✅ Found stage: ${stage.name} (ID: ${stage.id})\n`);

        // Create test deal
        const newDeal = {
            companyId: contact.companyId,
            contactId: contact.id,
            title: 'Test Deal - Automated Creation',
            stageId: stage.id,
            stage: 'lead' as const,
            value: 5000,
            priority: 'high' as const,
            status: 'active',
            description: 'This is a test deal created automatically to verify the system works',
            tags: ['test', 'automated'],
            lastActivityAt: new Date(),
            createdAt: new Date(),
            updatedAt: new Date()
        };

        console.log('Creating deal with data:', JSON.stringify(newDeal, null, 2));

        const [createdDeal] = await db.insert(deals).values(newDeal).returning();

        console.log('\n✅ Deal created successfully!');
        console.log('Deal ID:', createdDeal.id);
        console.log('Title:', createdDeal.title);
        console.log('Value:', createdDeal.value);
        console.log('Contact ID:', createdDeal.contactId);
        console.log('Stage ID:', createdDeal.stageId);

        process.exit(0);
    } catch (error: any) {
        console.error('❌ Error creating deal:', error.message);
        console.error('Stack:', error.stack);
        process.exit(1);
    }
}

createTestDeal();
