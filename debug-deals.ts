
import "dotenv/config";
import { storage } from "./server/storage";

async function main() {
    try {
        console.log("Fetching deals...");
        const deals = await storage.getDeals();
        console.log(`Successfully fetched ${deals.length} deals.`);
        if (deals.length > 0) {
            console.log("Sample deal:", JSON.stringify(deals[0], null, 2));
        }
    } catch (error) {
        console.error("Error fetching deals:", error);
    }
    process.exit(0);
}

main();
