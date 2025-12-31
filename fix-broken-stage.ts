
import 'dotenv/config';
import { db } from './server/db';
import { pipelineStages } from './shared/schema';
import { eq } from 'drizzle-orm';

async function main() {
    try {
        console.log("Fixing Stage 25 (Lead) -> Linking to Pipeline 3 (Ruta Principal)...");

        await db.update(pipelineStages)
            .set({ pipelineId: 3 })
            .where(eq(pipelineStages.id, 25));

        console.log("Success! Stage 25 should now be part of Ruta Principal.");

    } catch (error) {
        console.error("Error:", error);
    }
    process.exit(0);
}

main();
