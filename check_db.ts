
import * as dotenv from "dotenv";
dotenv.config();
import pg from 'pg';
const { Pool } = pg;

async function checkSchema() {
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
        const res = await client.query(`
      SELECT column_name, is_nullable, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'contact_tasks';
    `);
        console.log("Schema for contact_tasks:");
        console.table(res.rows);
        const rows = res.rows as any[];
        const relevant = rows.filter(r => ['contact_id', 'checklist'].includes(r.column_name));
        console.log("Relevant columns:", JSON.stringify(relevant, null, 2));
        client.release();
        pool.end();
        process.exit(0);
    } catch (error) {
        console.error("Error checking schema:", error);
        pool.end();
        process.exit(1);
    }
}

checkSchema();
