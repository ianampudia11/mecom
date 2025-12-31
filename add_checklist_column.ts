
import * as dotenv from "dotenv";
dotenv.config();
import pg from 'pg';
const { Pool } = pg;

async function runMigration() {
    if (!process.env.DATABASE_URL) {
        console.error("DATABASE_URL mismatch or missing");
        process.exit(1);
    }

    const pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        // ssl: { rejectUnauthorized: false } // Removed SSL for local dev
    });

    try {
        const client = await pool.connect();
        console.log("Connected to database.");
        console.log("Adding checklist column to contact_tasks...");
        await client.query(`
      ALTER TABLE contact_tasks 
      ADD COLUMN IF NOT EXISTS checklist JSONB DEFAULT '[]'::jsonb;
    `);
        console.log("Successfully added checklist column.");
        client.release();
        pool.end();
        process.exit(0);
    } catch (error) {
        console.error("Error adding column:", error);
        pool.end();
        process.exit(1);
    }
}

runMigration();
