import { execSync } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.log(`Starting production build... Timestamp: ${new Date().toISOString()}`);

try {
    // Execute the actual production build command
    // This aligns with "build:production": "cross-env NODE_ENV=production vite build && node scripts/esbuild.config.js production"
    execSync('npm run build:production', {
        stdio: 'inherit',
        cwd: path.join(__dirname, '..')
    });

    console.log('Production build completed successfully.');
} catch (error) {
    console.error('Build failed:', error.message);
    process.exit(1);
}
