
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Load env vars
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '../.env') });

// Mock secureEnv before importing db if needed, or ensure ENV is set
process.env.NODE_ENV = 'development';

async function check() {
    try {
        console.log('Importing db...');
        const { db } = await import('../server/db');
        const { properties } = await import('../shared/schema');

        console.log('Querying properties table...');
        const result = await db.select().from(properties).limit(1);
        console.log('Query successful. Result:', result);
        process.exit(0);
    } catch (error) {
        console.error('Health check failed:', error);
        process.exit(1);
    }
}

check();
