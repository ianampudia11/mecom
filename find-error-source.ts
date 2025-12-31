import "dotenv/config";
import { db } from "./server/db";
import { sql } from "drizzle-orm";
import fs from "fs";

async function findThings() {
    // 1. Search file
    const content = fs.readFileSync("./server/storage.ts", "utf-8");
    const lines = content.split("\n");
    lines.forEach((line, index) => {
        if (line.includes("async createDeal")) {
            console.log(`Found 'async createDeal' at line ${index + 1}`);
        }
    });

    // 2. Search DB functions for error string
    console.log("Searching DB for error string...");
    try {
        const result = await db.execute(sql`
            SELECT proname, prosrc 
            FROM pg_proc 
            WHERE prosrc ILIKE '%Pipeline stage must belong to the same company as the deal%';
        `);
        console.log("DB Matches:", result.rows);
    } catch (e) {
        console.error("DB Search Error:", e);
    }
    process.exit(0);
}

findThings();
