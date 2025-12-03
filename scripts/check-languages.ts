import 'dotenv/config';
import { storage } from '../server/storage';

async function main() {
    try {
        console.log('Checking languages...');
        const languages = await storage.getAllLanguages();

        console.log('Available languages:');
        languages.forEach(lang => {
            console.log(`- ${lang.code} (${lang.name}): Default=${lang.isDefault}, Active=${lang.isActive}`);
        });

        const defaultLang = await storage.getDefaultLanguage();
        if (defaultLang) {
            console.log(`\nCurrent default language: ${defaultLang.code}`);
        } else {
            console.log('\nNo default language set.');
        }

        process.exit(0);
    } catch (error) {
        console.error('Error checking languages:', error);
        process.exit(1);
    }
}

main();
