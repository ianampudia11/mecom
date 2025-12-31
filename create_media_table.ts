import { db } from "./server/db";
import { sql } from "drizzle-orm";

async function main() {
    console.log("Creating property_media table...");
    try {
        await db.execute(sql`
      CREATE TABLE IF NOT EXISTS property_media (
        id SERIAL PRIMARY KEY,
        property_id INTEGER NOT NULL REFERENCES properties(id),
        media_type TEXT NOT NULL,
        file_url TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        mime_type TEXT,
        order_num INTEGER DEFAULT 0,
        is_flyer BOOLEAN DEFAULT false,
        is_primary BOOLEAN DEFAULT false,
        uploaded_by INTEGER REFERENCES users(id),
        created_at TIMESTAMP DEFAULT NOW()
      );
    `);
        console.log("Table property_media created or already exists.");
    } catch (error) {
        console.error("Error creating table:", error);
    }
    process.exit(0);
}

main().catch((err) => {
    console.error("Fatal error:", err);
    process.exit(1);
});
