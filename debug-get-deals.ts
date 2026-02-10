
import "dotenv/config";
import { storage } from "./server/storage";

async function checkDeals() {
    console.log("🔍 Testing getDeals()...");
    try {
        // Simular petición con un companyId válido (ej. 1)
        const deals = await storage.getDeals({ companyId: 1 });
        console.log(`✅ Success! Retrieved ${deals.length} deals.`);
        if (deals.length > 0) {
            console.log("Sample deal contact:", JSON.stringify(deals[0].contact, null, 2));
        }
    } catch (e) {
        console.error("❌ Failed to get deals:", e);
    }
    process.exit(0);
}

checkDeals();
