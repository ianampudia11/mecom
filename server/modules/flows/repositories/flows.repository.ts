import { db } from '../../../db';
import { flows, flowExecutions } from '@shared/schema';
import type { Flow, InsertFlow, FlowExecution, InsertFlowExecution } from '@shared/schema';
import { eq, and, desc } from 'drizzle-orm';

/**
 * Repository for flows and flow executions
 * Extracted from monolithic storage.ts
 */

// Get flows for a company
export async function getFlows(companyId: number): Promise<Flow[]> {
    try {
        return await db
            .select()
            .from(flows)
            .where(eq(flows.companyId, companyId))
            .orderBy(desc(flows.createdAt));
    } catch (error) {
        console.error(`Error getting flows for company ${companyId}:`, error);
        return [];
    }
}

// Get single flow
export async function getFlow(id: number): Promise<Flow | undefined> {
    try {
        const [flow] = await db
            .select()
            .from(flows)
            .where(eq(flows.id, id));
        return flow;
    } catch (error) {
        console.error(`Error getting flow ${id}:`, error);
        return undefined;
    }
}

// Create flow
export async function createFlow(flow: InsertFlow): Promise<Flow> {
    try {
        const [newFlow] = await db
            .insert(flows)
            .values({
                ...flow,
                createdAt: new Date(),
                updatedAt: new Date()
            })
            .returning();

        return newFlow;
    } catch (error) {
        console.error('Error creating flow:', error);
        throw error;
    }
}

// Update flow
export async function updateFlow(id: number, updates: Partial<InsertFlow>): Promise<Flow> {
    try {
        const [updatedFlow] = await db
            .update(flows)
            .set({
                ...updates,
                updatedAt: new Date()
            })
            .where(eq(flows.id, id))
            .returning();

        if (!updatedFlow) {
            throw new Error(`Flow ${id} not found`);
        }

        return updatedFlow;
    } catch (error) {
        console.error(`Error updating flow ${id}:`, error);
        throw error;
    }
}

// Delete flow
export async function deleteFlow(id: number, companyId: number): Promise<boolean> {
    try {
        await db
            .delete(flows)
            .where(and(
                eq(flows.id, id),
                eq(flows.companyId, companyId)
            ));

        return true;
    } catch (error) {
        console.error(`Error deleting flow ${id}:`, error);
        return false;
    }
}

// Get flow executions
export async function getFlowExecutions(flowId: number, limit = 50): Promise<FlowExecution[]> {
    try {
        return await db
            .select()
            .from(flowExecutions)
            .where(eq(flowExecutions.flowId, flowId))
            .orderBy(desc(flowExecutions.createdAt))
            .limit(limit);
    } catch (error) {
        console.error(`Error getting executions for flow ${flowId}:`, error);
        return [];
    }
}

// Create flow execution
export async function createFlowExecution(execution: InsertFlowExecution): Promise<FlowExecution> {
    try {
        const [newExecution] = await db
            .insert(flowExecutions)
            .values({
                ...execution,
                createdAt: new Date()
            })
            .returning();

        return newExecution;
    } catch (error) {
        console.error('Error creating flow execution:', error);
        throw error;
    }
}

// Update flow execution
export async function updateFlowExecution(
    id: number,
    updates: Partial<InsertFlowExecution>
): Promise<FlowExecution> {
    try {
        const [updatedExecution] = await db
            .update(flowExecutions)
            .set(updates)
            .where(eq(flowExecutions.id, id))
            .returning();

        if (!updatedExecution) {
            throw new Error(`Flow execution ${id} not found`);
        }

        return updatedExecution;
    } catch (error) {
        console.error(`Error updating flow execution ${id}:`, error);
        throw error;
    }
}
