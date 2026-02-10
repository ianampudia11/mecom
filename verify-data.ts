import { db } from './server/db';
import { tasks, deals, contacts, companies } from './shared/schema';
import { sql } from 'drizzle-orm';

async function checkData() {
    try {
        console.log('🔍 Verificando datos en la base de datos...\n');

        // Contar tasks
        const tasksResult = await db.select({ count: sql<number>`count(*)` }).from(tasks);
        const tasksCount = Number(tasksResult[0]?.count || 0);
        console.log(`📋 Tasks en DB: ${tasksCount}`);

        // Contar deals
        const dealsResult = await db.select({ count: sql<number>`count(*)` }).from(deals);
        const dealsCount = Number(dealsResult[0]?.count || 0);
        console.log(`💼 Deals en DB: ${dealsCount}`);

        // Contar contacts
        const contactsResult = await db.select({ count: sql<number>`count(*)` }).from(contacts);
        const contactsCount = Number(contactsResult[0]?.count || 0);
        console.log(`👥 Contacts en DB: ${contactsCount}`);

        // Contar companies
        const companiesResult = await db.select({ count: sql<number>`count(*)` }).from(companies);
        const companiesCount = Number(companiesResult[0]?.count || 0);
        console.log(`🏢 Companies en DB: ${companiesCount}\n`);

        // Si hay datos, mostrar ejemplos
        if (tasksCount > 0) {
            const sampleTasks = await db.select().from(tasks).limit(3);
            console.log('📝 Ejemplo de tasks:');
            sampleTasks.forEach((task, i) => {
                console.log(`  ${i + 1}. ID: ${task.id}, Título: ${task.title}, CompanyID: ${task.companyId}`);
            });
            console.log('');
        }

        if (dealsCount > 0) {
            const sampleDeals = await db.select().from(deals).limit(3);
            console.log('💰 Ejemplo de deals:');
            sampleDeals.forEach((deal, i) => {
                console.log(`  ${i + 1}. ID: ${deal.id}, Título: ${deal.title}, CompanyID: ${deal.companyId}`);
            });
            console.log('');
        }

        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

checkData();
