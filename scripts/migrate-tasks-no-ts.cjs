
const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

async function migrate() {
    const envPath = path.resolve(__dirname, '..', '.env');
    let connectionString = process.env.DATABASE_URL;

    if (!connectionString) {
        if (fs.existsSync(envPath)) {
            const envContent = fs.readFileSync(envPath, 'utf8');
            const dbUrlLine = envContent.split('\n').find(line => line.startsWith('DATABASE_URL='));
            if (dbUrlLine) {
                connectionString = dbUrlLine.split('=', 2)[1].trim().replace(/^['"]|['"]$/g, '');
            }
        }
    }

    if (!connectionString) {
        console.error('DATABASE_URL not found');
        process.exit(1);
    }

    const client = new Client({ connectionString });
    await client.connect();
    // Create Types if they don't exist
    try {
        await client.query(`DO $$ BEGIN
        CREATE TYPE "task_priority" AS ENUM ('low', 'medium', 'high', 'urgent');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;`);

        await client.query(`DO $$ BEGIN
        CREATE TYPE "task_status" AS ENUM ('not_started', 'in_progress', 'completed', 'cancelled');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;`);
    } catch (e) {
        console.log('Error creating enums (ignoring):', e.message);
    }

    // Create tasks table if not exists
    await client.query(`
      CREATE TABLE IF NOT EXISTS "tasks" (
        "id" serial PRIMARY KEY,
        "contact_id" integer,
        "company_id" integer NOT NULL,
        "title" text NOT NULL,
        "description" text,
        "priority" "task_priority" DEFAULT 'medium' NOT NULL,
        "status" "task_status" DEFAULT 'not_started' NOT NULL,
        "due_date" timestamp,
        "completed_at" timestamp,
        "assigned_to" text,
        "category" text,
        "tags" text[],
        "checklist" jsonb,
        "background_color" text,
        "created_by" integer,
        "updated_by" integer,
        "created_at" timestamp DEFAULT now(),
        "updated_at" timestamp DEFAULT now()
      );
    `);
    console.log('Ensured tasks table exists.');

    // 2. Clear existing tasks? No, migrate incrementally.


    try {
        const { rows: contactTasks } = await client.query('SELECT * FROM "contact_tasks"');
        console.log(`Found ${contactTasks.length} contact tasks.`);

        if (contactTasks.length > 0) {
            let migrated = 0;
            for (const task of contactTasks) {
                // Mapping logic
                const statusMap = { 'pending': 'not_started', 'in_progress': 'in_progress', 'completed': 'completed', 'cancelled': 'cancelled' };
                const status = statusMap[task.status] || 'not_started';

                const priorityMap = { 'low': 'low', 'high': 'high', 'urgent': 'urgent', 'medium': 'medium' };
                const priority = priorityMap[task.priority] || 'medium';

                // tasks table columns: contact_id, company_id, title, description, status, priority, due_date, completed_at, created_at, updated_at
                await client.query(`
            INSERT INTO tasks (
              contact_id, company_id, title, description, status, priority, due_date, completed_at, created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
          `, [
                    task.contact_id, task.company_id, task.title, task.description, status, priority, task.due_date, task.completed_at, task.created_at, task.updated_at
                ]);
                migrated++;
            }
            console.log(`Migrated ${migrated} tasks.`);
        }
    } catch (err) {
        console.error('Migration error:', err);
    } finally {
        await client.end();
    }
}

migrate();
