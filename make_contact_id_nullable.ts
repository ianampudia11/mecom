
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
        connectionString: process.env.DATABASE_URL
        // ssl: { rejectUnauthorized: false }
    });

    try {
        const client = await pool.connect();
        console.log("Connected to database.");
        console.log("Altering contact_tasks to make contact_id nullable...");
        await client.query(`
      ALTER TABLE contact_tasks 
      ALTER COLUMN contact_id DROP NOT NULL;
    `);
        console.log("Successfully altered contact_id.");
        client.release();
        pool.end();
        process.exit(0);
    } catch (error) {
        console.error("Error altering column:", error);
        pool.end();
        process.exit(1);
    }
}

runMigration();
