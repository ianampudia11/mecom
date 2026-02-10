import { db } from '../../../db';
import { pipelines, pipelineStages } from '@shared/schema';
import type { PipelineStage, InsertPipelineStage } from '@shared/schema';
import { eq, inArray } from 'drizzle-orm';

type Pipeline = typeof pipelines.$inferSelect;
type InsertPipeline = typeof pipelines.$inferInsert;

/**
 * Repository for pipelines and stages
 */

// Pipelines
export async function getPipelines(companyId: number): Promise<Pipeline[]> {
    try {
        return await db
            .select()
            .from(pipelines)
            .where(eq(pipelines.companyId, companyId));
    } catch (error) {
        console.error(`Error getting pipelines for company ${companyId}:`, error);
        return [];
    }
}

export async function getPipeline(id: number): Promise<Pipeline | undefined> {
    try {
        const [pipeline] = await db
            .select()
            .from(pipelines)
            .where(eq(pipelines.id, id));
        return pipeline;
    } catch (error) {
        console.error(`Error getting pipeline ${id}:`, error);
        return undefined;
    }
}

export async function createPipeline(pipeline: InsertPipeline): Promise<Pipeline> {
    try {
        const [newPipeline] = await db
            .insert(pipelines)
            .values({
                ...pipeline,
                createdAt: new Date(),
                updatedAt: new Date()
            })
            .returning();
        return newPipeline;
    } catch (error) {
        console.error('Error creating pipeline:', error);
        throw error;
    }
}

export async function updatePipeline(id: number, updates: Partial<InsertPipeline>): Promise<Pipeline> {
    try {
        const [updated] = await db
            .update(pipelines)
            .set({ ...updates, updatedAt: new Date() })
            .where(eq(pipelines.id, id))
            .returning();

        if (!updated) {
            throw new Error(`Pipeline ${id} not found`);
        }

        return updated;
    } catch (error) {
        console.error(`Error updating pipeline ${id}:`, error);
        throw error;
    }
}

export async function deletePipeline(id: number): Promise<boolean> {
    try {
        await db.delete(pipelines).where(eq(pipelines.id, id));
        return true;
    } catch (error) {
        console.error(`Error deleting pipeline ${id}:`, error);
        return false;
    }
}

// Pipeline Stages
export async function getPipelineStages(): Promise<PipelineStage[]> {
    try {
        return await db.select().from(pipelineStages);
    } catch (error) {
        console.error('Error getting pipeline stages:', error);
        return [];
    }
}

export async function getPipelineStage(id: number): Promise<PipelineStage | undefined> {
    try {
        const [stage] = await db
            .select()
            .from(pipelineStages)
            .where(eq(pipelineStages.id, id));
        return stage;
    } catch (error) {
        console.error(`Error getting pipeline stage ${id}:`, error);
        return undefined;
    }
}

export async function getPipelineStagesByPipelineId(pipelineId: number): Promise<PipelineStage[]> {
    try {
        return await db
            .select()
            .from(pipelineStages)
            .where(eq(pipelineStages.pipelineId, pipelineId));
    } catch (error) {
        console.error(`Error getting stages for pipeline ${pipelineId}:`, error);
        return [];
    }
}

export async function createPipelineStage(stage: InsertPipelineStage): Promise<PipelineStage> {
    try {
        const [newStage] = await db
            .insert(pipelineStages)
            .values({
                ...stage,
                createdAt: new Date(),
                updatedAt: new Date()
            })
            .returning();
        return newStage;
    } catch (error) {
        console.error('Error creating pipeline stage:', error);
        throw error;
    }
}

export async function updatePipelineStage(id: number, updates: Partial<PipelineStage>): Promise<PipelineStage> {
    try {
        const [updated] = await db
            .update(pipelineStages)
            .set({ ...updates, updatedAt: new Date() })
            .where(eq(pipelineStages.id, id))
            .returning();

        if (!updated) {
            throw new Error(`Pipeline stage ${id} not found`);
        }

        return updated;
    } catch (error) {
        console.error(`Error updating pipeline stage ${id}:`, error);
        throw error;
    }
}

export async function deletePipelineStage(id: number, moveDealsToStageId?: number): Promise<boolean> {
    try {
        // TODO: Handle moving deals if moveDealsToStageId is provided
        await db.delete(pipelineStages).where(eq(pipelineStages.id, id));
        return true;
    } catch (error) {
        console.error(`Error deleting pipeline stage ${id}:`, error);
        return false;
    }
}

export async function reorderPipelineStages(stageIds: number[]): Promise<boolean> {
    try {
        // Update order for each stage
        for (let i = 0; i < stageIds.length; i++) {
            await db
                .update(pipelineStages)
                .set({ order: i, updatedAt: new Date() })
                .where(eq(pipelineStages.id, stageIds[i]));
        }
        return true;
    } catch (error) {
        console.error('Error reordering pipeline stages:', error);
        return false;
    }
}
