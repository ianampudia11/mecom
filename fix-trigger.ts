
import "dotenv/config";
import { db } from "./server/db";
import { sql } from "drizzle-orm";

async function fixTrigger() {
    console.log("Updating trigger function...");
    try {
        await db.execute(sql`
            CREATE OR REPLACE FUNCTION check_deal_stage_company_match() RETURNS TRIGGER AS $$
            BEGIN
              IF NEW.stage_id IS NOT NULL THEN
                IF NOT EXISTS (
                  SELECT 1 FROM pipeline_stages ps
                  JOIN pipelines p ON ps.pipeline_id = p.id
                  WHERE ps.id = NEW.stage_id
                  AND p.company_id = NEW.company_id
                ) THEN
                  RAISE EXCEPTION 'Pipeline stage must belong to the same company as the deal';
                END IF;
              END IF;
              RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
        `);
        console.log("Function updated successfully.");
    } catch (e) {
        console.error("Error updating function:", e);
    }
    process.exit(0);
}

fixTrigger();
