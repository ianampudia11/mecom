import { Router } from 'express';
import type { Request, Response } from 'express';
import * as adminRepo from '../repositories/admin.repository';
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

// ============ USER ROUTES ============

/**
 * GET /api/admin/users/company/:companyId
 * Get all users for a company
 */
router.get('/users/company/:companyId', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const companyId = parseInt(req.params.companyId);
        const users = await adminRepo.getCompanyUsers(companyId);
        res.json(users);
    } catch (error) {
        console.error('Error fetching company users:', error);
        res.status(500).json({ error: 'Failed to fetch users' });
    }
});

/**
 * GET /api/admin/users/:id
 * Get single user
 */
router.get('/users/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const user = await adminRepo.getUser(id);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json(user);
    } catch (error) {
        console.error('Error fetching user:', error);
        res.status(500).json({ error: 'Failed to fetch user' });
    }
});

/**
 * POST /api/admin/users
 * Create new user
 */
router.post('/users', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const userData = req.body;
        const newUser = await adminRepo.createUser(userData);
        res.status(201).json(newUser);
    } catch (error) {
        console.error('Error creating user:', error);
        res.status(500).json({ error: 'Failed to create user' });
    }
});

/**
 * PATCH /api/admin/users/:id
 * Update user
 */
router.patch('/users/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const updates = req.body;

        const updatedUser = await adminRepo.updateUser(id, updates);
        res.json(updatedUser);
    } catch (error) {
        console.error('Error updating user:', error);
        res.status(500).json({ error: 'Failed to update user' });
    }
});

/**
 * DELETE /api/admin/users/:id
 * Delete user
 */
router.delete('/users/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const success = await adminRepo.deleteUser(id);

        if (!success) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json({ message: 'User deleted successfully' });
    } catch (error) {
        console.error('Error deleting user:', error);
        res.status(500).json({ error: 'Failed to delete user' });
    }
});

// ============ COMPANY ROUTES ============

/**
 * GET /api/admin/companies
 * Get all companies
 */
router.get('/companies', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const companies = await adminRepo.getCompanies();
        res.json(companies);
    } catch (error) {
        console.error('Error fetching companies:', error);
        res.status(500).json({ error: 'Failed to fetch companies' });
    }
});

/**
 * GET /api/admin/companies/:id
 * Get single company
 */
router.get('/companies/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const company = await adminRepo.getCompany(id);

        if (!company) {
            return res.status(404).json({ error: 'Company not found' });
        }

        res.json(company);
    } catch (error) {
        console.error('Error fetching company:', error);
        res.status(500).json({ error: 'Failed to fetch company' });
    }
});

/**
 * POST /api/admin/companies
 * Create new company
 */
router.post('/companies', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const companyData = req.body;
        const newCompany = await adminRepo.createCompany(companyData);
        res.status(201).json(newCompany);
    } catch (error) {
        console.error('Error creating company:', error);
        res.status(500).json({ error: 'Failed to create company' });
    }
});

/**
 * PATCH /api/admin/companies/:id
 * Update company
 */
router.patch('/companies/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const updates = req.body;

        const updatedCompany = await adminRepo.updateCompany(id, updates);
        res.json(updatedCompany);
    } catch (error) {
        console.error('Error updating company:', error);
        res.status(500).json({ error: 'Failed to update company' });
    }
});

/**
 * DELETE /api/admin/companies/:id
 * Delete company
 */
router.delete('/companies/:id', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const id = parseInt(req.params.id);
        const success = await adminRepo.deleteCompany(id);

        if (!success) {
            return res.status(404).json({ error: 'Company not found' });
        }

        res.json({ message: 'Company deleted successfully' });
    } catch (error) {
        console.error('Error deleting company:', error);
        res.status(500).json({ error: 'Failed to delete company' });
    }
});

export default router;
