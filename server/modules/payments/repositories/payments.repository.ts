import { db } from '../../../db';
import { paymentTransactions, couponCodes, affiliateEarningsBalance, affiliateEarningsTransactions } from '@shared/schema';
import { eq, and } from 'drizzle-orm';

/**
 * Repository for payments, transactions, coupons, and affiliate earnings
 */

// Payment Transactions
export async function getAllPaymentTransactions() {
    try {
        return await db.select().from(paymentTransactions);
    } catch (error) {
        console.error('Error getting payment transactions:', error);
        return [];
    }
}

export async function getPaymentTransactionsByCompany(companyId: number) {
    try {
        return await db
            .select()
            .from(paymentTransactions)
            .where(eq(paymentTransactions.companyId, companyId));
    } catch (error) {
        console.error(`Error getting transactions for company ${companyId}:`, error);
        return [];
    }
}

export async function getPaymentTransaction(id: number) {
    try {
        const [transaction] = await db
            .select()
            .from(paymentTransactions)
            .where(eq(paymentTransactions.id, id));
        return transaction;
    } catch (error) {
        console.error(`Error getting transaction ${id}:`, error);
        return undefined;
    }
}

// Coupons
export async function getAllCoupons() {
    try {
        return await db.select().from(couponCodes);
    } catch (error) {
        console.error('Error getting coupons:', error);
        return [];
    }
}

export async function getCouponByCode(code: string) {
    try {
        const [coupon] = await db.select().from(couponCodes).where(eq(couponCodes.code, code));
        return coupon;
    } catch (error) {
        console.error(`Error getting coupon ${code}:`, error);
        return undefined;
    }
}

// Affiliate Earnings
export async function getAffiliateEarnings(affiliateId: number) {
    try {
        const [balance] = await db
            .select()
            .from(affiliateEarningsBalance)
            .where(eq(affiliateEarningsBalance.affiliateId, affiliateId));
        return balance;
    } catch (error) {
        console.error(`Error getting affiliate earnings for ${affiliateId}:`, error);
        return undefined;
    }
}

export async function getAffiliateTransactions(affiliateId: number) {
    try {
        return await db
            .select()
            .from(affiliateEarningsTransactions)
            .where(eq(affiliateEarningsTransactions.affiliateId, affiliateId));
    } catch (error) {
        console.error(`Error getting affiliate transactions for ${affiliateId}:`, error);
        return [];
    }
}
