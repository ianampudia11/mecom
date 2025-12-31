
import fs from 'fs';
const content = fs.readFileSync('shared/schema.ts', 'utf8');
const lines = content.split('\n');
lines.forEach((line, index) => {
    if (line.includes('export const deals =')) {
        console.log(`Found at line: ${index + 1}`);
        console.log(line);
    }
});
