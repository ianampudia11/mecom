import { db } from '../../../db';
import { plans, planAiProviderConfigs } from '@shared/schema';
import type { Plan, PlanAiProviderConfig } from '@shared/schema';
import { eq } from 'drizzle-orm';

/**
 * Repository for plans and AI provider configurations
 */

export async function getAllPlans(): Promise<Plan[]> {
    try {
        return await db.select().from(plans);
    } catch (error) {
        console.error('Error getting plans:', error);
        return [];
    }
}

export async function getPlan(id: number): Promise<Plan | undefined> {
    try {
        const [plan] = await db.select().from(plans).where(eq(plans.id, id));
        return plan;
    } catch (error) {
        console.error(`Error getting plan ${id}:`, error);
        return undefined;
    }
}

export async function getPlanAiProviderConfigs(planId: number): Promise<PlanAiProviderConfig[]> {
    try {
        return await db
            .select()
            .from(planAiProviderConfigs)
            .where(eq(planAiProviderConfigs.planId, planId));
    } catch (error) {
        console.error(`Error getting AI configs for plan ${planId}:`, error);
        return [];
    }
}

export async function getPlanByName(name: string): Promise<Plan | undefined> {
    try {
        const [plan] = await db.select().from(plans).where(eq(plans.name, name));
        return plan;
    } catch (error) {
        console.error(`Error getting plan by name ${name}:`, error);
        return undefined;
    }
}
