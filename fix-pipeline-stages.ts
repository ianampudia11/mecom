import 'dotenv/config';
import { db } from "./server/db";
import { sql } from "drizzle-orm";

async function fixPipelineStages() {
    try {
        console.log("Checking for pipelines with no stages...");

        // Get all pipelines
        const pipelinesResult = await db.execute(sql`SELECT * FROM pipelines`);
        const pipelines = pipelinesResult.rows;

        for (const pipeline of pipelines) {
            // Check stage count
            const countResult = await db.execute(sql`
            SELECT count(*) as count FROM pipeline_stages WHERE pipeline_id = ${pipeline.id}
        `);
            const count = parseInt(countResult.rows[0].count as string);

            if (count === 0) {
                console.log(`Pipeline ${pipeline.id} (${pipeline.name}) has 0 stages. Fixing...`);

                const defaultStages = [
                    { name: 'Nuevos', order: 0, color: '#3B82F6' },
                    { name: 'Contactados', order: 1, color: '#EAB308' },
                    { name: 'Interesados', order: 2, color: '#F97316' },
                    { name: 'Cita Agendada', order: 3, color: '#A855F7' },
                    { name: 'Negociación', order: 4, color: '#EC4899' },
                    { name: 'Cerrado', order: 5, color: '#22C55E' }
                ];

                for (const stage of defaultStages) {
                    // Use order_num instead of order_index
                    await db.execute(sql`
                  INSERT INTO pipeline_stages (pipeline_id, name, order_num, color)
                  VALUES (${pipeline.id}, ${stage.name}, ${stage.order}, ${stage.color})
                `);
                }
                console.log(`Added 6 default stages to pipeline ${pipeline.id}`);
            } else {
                console.log(`Pipeline ${pipeline.id} has ${count} stages. OK.`);
            }
        }

        console.log("Fix complete.");
    } catch (error) {
        console.error("Error:", error);
    } finally {
        process.exit(0);
    }
}

fixPipelineStages();
