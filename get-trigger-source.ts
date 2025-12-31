
import "dotenv/config";
import { db } from "./server/db";
import { sql } from "drizzle-orm";

async function getTriggerSource() {
    console.log("Getting function source...");
    try {
        const result = await db.execute(sql`
            SELECT prosrc 
            FROM pg_proc 
            WHERE proname = 'check_deal_stage_company_match';
        `);
        console.log("Source:");
        console.log(result.rows[0].prosrc);
    } catch (e) {
        console.error("Error:", e);
    }
    process.exit(0);
}

getTriggerSource();
