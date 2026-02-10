
import { pool } from "./db";

async function main() {
    console.log("Dropping problematic index idx_messages_media_dedup...");
    try {
        const client = await pool.connect();
        await client.query("DROP INDEX IF EXISTS idx_messages_media_dedup");
        console.log("Index dropped successfully.");
        client.release();
    } catch (err) {
        console.error("Error dropping index:", err);
    } finally {
        process.exit(0);
    }
}

main();
