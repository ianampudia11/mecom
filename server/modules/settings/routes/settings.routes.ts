import { Router } from 'express';
import type { Request, Response } from 'express';
import * as settingsRepo from '../repositories/settings.repository';
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

// App Settings
router.get('/app/:key', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const { key } = req.params;
        const setting = await settingsRepo.getAppSetting(key);

        if (!setting) {
            return res.status(404).json({ error: 'Setting not found' });
        }

        res.json(setting);
    } catch (error) {
        console.error('Error fetching app setting:', error);
        res.status(500).json({ error: 'Failed to fetch setting' });
    }
});

router.get('/app', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const settings = await settingsRepo.getAllAppSettings();
        res.json(settings);
    } catch (error) {
        console.error('Error fetching app settings:', error);
        res.status(500).json({ error: 'Failed to fetch settings' });
    }
});

router.post('/app/:key', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const { key } = req.params;
        const { value } = req.body;

        const setting = await settingsRepo.saveAppSetting(key, value);
        res.json(setting);
    } catch (error) {
        console.error('Error saving app setting:', error);
        res.status(500).json({ error: 'Failed to save setting' });
    }
});

router.delete('/app/:key', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const { key } = req.params;
        const success = await settingsRepo.deleteAppSetting(key);
        res.json({ success });
    } catch (error) {
        console.error('Error deleting app setting:', error);
        res.status(500).json({ error: 'Failed to delete setting' });
    }
});

// Company Settings
router.get('/company/:companyId/:key', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const companyId = parseInt(req.params.companyId);
        const { key } = req.params;

        const setting = await settingsRepo.getCompanySetting(companyId, key);

        if (!setting) {
            return res.status(404).json({ error: 'Setting not found' });
        }

        res.json(setting);
    } catch (error) {
        console.error('Error fetching company setting:', error);
        res.status(500).json({ error: 'Failed to fetch setting' });
    }
});

router.get('/company/:companyId', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const companyId = parseInt(req.params.companyId);
        const settings = await settingsRepo.getAllCompanySettings(companyId);
        res.json(settings);
    } catch (error) {
        console.error('Error fetching company settings:', error);
        res.status(500).json({ error: 'Failed to fetch settings' });
    }
});

router.post('/company/:companyId/:key', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const companyId = parseInt(req.params.companyId);
        const { key } = req.params;
        const { value } = req.body;

        const setting = await settingsRepo.saveCompanySetting(companyId, key, value);
        res.json(setting);
    } catch (error) {
        console.error('Error saving company setting:', error);
        res.status(500).json({ error: 'Failed to save setting' });
    }
});

router.delete('/company/:companyId/:key', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const companyId = parseInt(req.params.companyId);
        const { key } = req.params;

        const success = await settingsRepo.deleteCompanySetting(companyId, key);
        res.json({ success });
    } catch (error) {
        console.error('Error deleting company setting:', error);
        res.status(500).json({ error: 'Failed to delete setting' });
    }
});

export default router;
