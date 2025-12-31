
import "dotenv/config";
import { db } from "./server/db";
import { sql } from "drizzle-orm";

async function main() {
    try {
        // Get all columns
        const columns = await db.execute(sql`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'properties'
        ORDER BY column_name
    `);
        const colNames = columns.rows.map((r: any) => r.column_name);
        console.log("Columns in 'properties':", colNames);

        // Get sample data
        const samples = await db.execute(sql`SELECT * FROM properties LIMIT 3`);
        console.log("Sample Properties:", JSON.stringify(samples.rows, null, 2));

    } catch (error) {
        console.error("Error inspecting properties:", error);
    }
    process.exit(0);
}

main();
