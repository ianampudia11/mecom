import { Router } from 'express';
import type { Request, Response } from 'express';
import * as paymentsRepo from '../repositories/payments.repository';
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

// Payment Transactions
router.get('/transactions', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const transactions = await paymentsRepo.getPaymentTransactionsByCompany(user.companyId);
        res.json(transactions);
    } catch (error) {
        console.error('Error fetching transactions:', error);
        res.status(500).json({ error: 'Failed to fetch transactions' });
    }
});

router.get('/transactions/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const transaction = await paymentsRepo.getPaymentTransaction(id);

        if (!transaction) {
            return res.status(404).json({ error: 'Transaction not found' });
        }

        res.json(transaction);
    } catch (error) {
        console.error('Error fetching transaction:', error);
        res.status(500).json({ error: 'Failed to fetch transaction' });
    }
});

// Coupons
router.get('/coupons', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const coupons = await paymentsRepo.getAllCoupons();
        res.json(coupons);
    } catch (error) {
        console.error('Error fetching coupons:', error);
        res.status(500).json({ error: 'Failed to fetch coupons' });
    }
});

router.get('/coupons/:code', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const { code } = req.params;
        const coupon = await paymentsRepo.getCouponByCode(code);

        if (!coupon) {
            return res.status(404).json({ error: 'Coupon not found' });
        }

        res.json(coupon);
    } catch (error) {
        console.error('Error fetching coupon:', error);
        res.status(500).json({ error: 'Failed to fetch coupon' });
    }
});

// Affiliate Earnings
router.get('/affiliate/:id/earnings', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const affiliateId = parseInt(req.params.id);
        const earnings = await paymentsRepo.getAffiliateEarnings(affiliateId);
        res.json(earnings || { balance: 0 });
    } catch (error) {
        console.error('Error fetching affiliate earnings:', error);
        res.status(500).json({ error: 'Failed to fetch earnings' });
    }
});

router.get('/affiliate/:id/transactions', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const affiliateId = parseInt(req.params.id);
        const transactions = await paymentsRepo.getAffiliateTransactions(affiliateId);
        res.json(transactions);
    } catch (error) {
        console.error('Error fetching affiliate transactions:', error);
        res.status(500).json({ error: 'Failed to fetch transactions' });
    }
});

export default router;
