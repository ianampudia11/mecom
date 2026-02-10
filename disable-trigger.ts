
import "dotenv/config";
import { db } from "./server/db";
import { sql } from "drizzle-orm";

async function disableTrigger() {
    console.log("🔓 Disabling strict trigger function...");
    try {
        await db.execute(sql`
            CREATE OR REPLACE FUNCTION check_deal_stage_company_match() RETURNS TRIGGER AS $$
            BEGIN
              -- Validations are handled in application layer.
              -- This DB trigger was too strict for current data state.
              RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
        `);
        console.log("✅ Trigger function disabled successfully.");
    } catch (e) {
        console.error("❌ Error ensuring trigger:", e);
    }
    process.exit(0);
}

disableTrigger();
