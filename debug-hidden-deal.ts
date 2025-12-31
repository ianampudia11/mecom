
import 'dotenv/config';
import { db } from './server/db';
import { deals, pipelineStages, pipelines } from './shared/schema';
import { eq } from 'drizzle-orm';

async function main() {
    try {
        // Get Deal 2 (Propiedad 402)
        const deal = await db.query.deals.findFirst({
            where: (d, { eq }) => eq(d.id, 2)
        });

        if (!deal) {
            console.log("Deal ID 2 not found.");
            process.exit(0);
        }

        console.log(`DEAL 2 STAGE ID: ${deal.stageId}`);

        // Get Stage info
        const stage = await db.query.pipelineStages.findFirst({
            where: (s, { eq }) => eq(s.id, deal.stageId)
        });

        console.log(`STAGE INFO: ID=${stage?.id}, Name=${stage?.name}, PipelineID=${stage?.pipelineId}`);

        // Get Ruta Principal
        const pipeline = await db.query.pipelines.findFirst({
            where: (p, { eq }) => eq(p.name, 'Ruta Principal')
        });

        console.log(`RUTA PRINCIPAL ID: ${pipeline?.id}`);

        // Check match
        if (stage && pipeline) {
            if (stage.pipelineId === pipeline.id) {
                console.log("MATCH: Deal is in Ruta Principal.");
            } else {
                console.log(`MISMATCH: Deal is in Pipeline ${stage.pipelineId}, but Ruta Principal is ${pipeline.id}.`);
            }
        }

    } catch (error) {
        console.error(error);
    }
    process.exit(0);
}

main();
