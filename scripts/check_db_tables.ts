
import { db } from "../server/db";
import { sql } from "drizzle-orm";

async function checkTables() {
    try {
        const result = await db.execute(sql`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
    `);
        console.log("Tables in DB:", result.rows.map((row: any) => row.table_name));

        // Check specific columns in contacts
        const contactsColumns = await db.execute(sql`
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = 'contacts'
    `);
        console.log("Contacts Columns:", contactsColumns.rows.map((row: any) => row.column_name));

    } catch (error) {
        console.error("Error checking tables:", error);
    }
    process.exit(0);
}

checkTables();
