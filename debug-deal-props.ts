
import "dotenv/config";
import { storage } from "./server/storage";

async function main() {
    try {
        console.log("Fetching deals...");
        const deals = await storage.getDeals();

        // Filter for deals that likely have properties
        const dealsWithProps = deals.filter(d => d.properties && d.properties.length > 0);

        console.log(`Found ${dealsWithProps.length} deals with properties.`);

        dealsWithProps.slice(0, 5).forEach(d => {
            console.log(`Deal ${d.id} (${d.title}):`);
            console.log("Properties:", JSON.stringify(d.properties, null, 2));
        });

    } catch (error) {
        console.error("Error fetching deals:", error);
    }
    process.exit(0);
}

main();
