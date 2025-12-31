import 'dotenv/config';
import { db } from "./server/db";
import { sql } from "drizzle-orm";

async function manualMigrate() {
  try {
    console.log("Creating/Verifying tables...");

    // Create pipelines table
    await db.execute(sql`
      CREATE TABLE IF NOT EXISTS pipelines (
        id SERIAL PRIMARY KEY,
        company_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        is_default BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);
    console.log("Table 'pipelines' checked.");

    // Create pipeline_stages table
    await db.execute(sql`
      CREATE TABLE IF NOT EXISTS pipeline_stages (
        id SERIAL PRIMARY KEY,
        pipeline_id INTEGER REFERENCES pipelines(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        color TEXT DEFAULT '#3B82F6',
        order_index INTEGER DEFAULT 0,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);
    console.log("Table 'pipeline_stages' checked.");

    // Add pipeline_id column if missing - safely
    try {
      const checkCol = await db.execute(sql`
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name='pipeline_stages' AND column_name='pipeline_id'
        `);

      if (checkCol.rows.length === 0) {
        console.log("Adding pipeline_id column...");
        await db.execute(sql`ALTER TABLE pipeline_stages ADD COLUMN pipeline_id INTEGER REFERENCES pipelines(id) ON DELETE CASCADE`);
      } else {
        console.log("Column 'pipeline_id' already exists.");
      }
    } catch (e) {
      console.log("Column check skipped or failed:", e);
    }

    // Default pipeline
    const users = await db.execute(sql`SELECT DISTINCT company_id FROM users`);
    for (const row of users.rows) {
      const companyId = row.company_id as number;
      const exists = await db.execute(sql`SELECT 1 FROM pipelines WHERE company_id = ${companyId}`);
      if (exists.rows.length === 0) {
        console.log(`Creating default pipeline for company ${companyId}`);
        await db.execute(sql`
                INSERT INTO pipelines (company_id, name, description, is_default)
                VALUES (${companyId}, 'Default Pipeline', 'Pipeline por defecto', TRUE)
            `);
      }
    }

    console.log("Manual migration done.");
  } catch (error) {
    console.error("Error:", error);
  } finally {
    process.exit(0);
  }
}

manualMigrate();
