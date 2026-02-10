import { Router } from 'express';
import type { Request, Response } from 'express';
import * as languagesRepo from '../repositories/languages.repository';
import { ensureAuthenticated } from '../../../middleware';

const router = Router();

router.get('/languages', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const languages = await languagesRepo.getAllLanguages();
        res.json(languages);
    } catch (error) {
        console.error('Error fetching languages:', error);
        res.status(500).json({ error: 'Failed to fetch languages' });
    }
});

router.get('/languages/:code', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const { code } = req.params;
        const language = await languagesRepo.getLanguageByCode(code);

        if (!language) {
            return res.status(404).json({ error: 'Language not found' });
        }

        res.json(language);
    } catch (error) {
        console.error('Error fetching language:', error);
        res.status(500).json({ error: 'Failed to fetch language' });
    }
});

router.get('/namespaces', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const namespaces = await languagesRepo.getAllNamespaces();
        res.json(namespaces);
    } catch (error) {
        console.error('Error fetching namespaces:', error);
        res.status(500).json({ error: 'Failed to fetch namespaces' });
    }
});

router.get('/keys', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const { namespaceId } = req.query;
        const keys = await languagesRepo.getAllKeys(namespaceId ? parseInt(namespaceId as string) : undefined);
        res.json(keys);
    } catch (error) {
        console.error('Error fetching keys:', error);
        res.status(500).json({ error: 'Failed to fetch keys' });
    }
});

router.get('/translations', ensureAuthenticated, async (req: Request, res: Response) => {
    try {
        const { languageId, keyId } = req.query;
        const translations = await languagesRepo.getAllTranslations(
            languageId ? parseInt(languageId as string) : undefined,
            keyId ? parseInt(keyId as string) : undefined
        );
        res.json(translations);
    } catch (error) {
        console.error('Error fetching translations:', error);
        res.status(500).json({ error: 'Failed to fetch translations' });
    }
});

export default router;
