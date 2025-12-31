
import "dotenv/config";
import { db } from "./server/db";
import { sql } from "drizzle-orm";





async function checkSchema() {
    console.log("Checking DB Triggers and Functions...");
    try {
        const triggers = await db.execute(sql`
            SELECT tgname, proname, prosrc 
            FROM pg_trigger
            JOIN pg_proc ON pg_trigger.tgfoid = pg_proc.oid
            WHERE tgname NOT LIKE 'RI_constraint_%';
        `);
        console.log("Triggers:", triggers.rows);

        const constraints = await db.execute(sql`
            SELECT conname, pg_get_constraintdef(oid) 
            FROM pg_constraint 
            WHERE contype = 'c' AND conname LIKE '%check%';
        `);
        console.log("Check Constraints:", constraints.rows);

    } catch (error) {
        console.error("Error checking schema:", error);
    }
    process.exit(0);
}

checkSchema();
