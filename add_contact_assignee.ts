
import 'dotenv/config';
import { db } from "./server/db";
import { sql } from "drizzle-orm";

async function main() {
    try {
        console.log("Adding assigned_to_user_id to contacts table...");

        await db.execute(sql`
      ALTER TABLE contacts 
      ADD COLUMN IF NOT EXISTS assigned_to_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL;
    `);

        console.log("Migration completed successfully");
        process.exit(0);
    } catch (error) {
        console.error("Migration failed:", error);
        process.exit(1);
    }
}

main();
