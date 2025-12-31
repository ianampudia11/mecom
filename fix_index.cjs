const fs = require('fs');
const path = require('path');

const targetPath = path.join(__dirname, 'server', 'index.ts');
try {
    const content = fs.readFileSync(targetPath, 'utf8');
    const lines = content.split(/\r?\n/);

    if (lines.length > 409) {
        const newContent = lines.slice(0, 409).join('\n');
        fs.writeFileSync(targetPath, newContent);
        console.log(`Successfully truncated ${targetPath} to 409 lines.`);
    } else {
        console.log('File is already short, no truncation needed. Length: ' + lines.length);
    }
} catch (err) {
    console.error('Error fixing file:', err);
    process.exit(1);
}
