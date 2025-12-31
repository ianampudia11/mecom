const fs = require('fs');
const path = require('path');

const targetPath = path.join(__dirname, 'server', 'index.ts');
try {
    const content = fs.readFileSync(targetPath, 'utf8');
    // Split by newline and take the first 409 lines (0 to 409, so slice(0, 409))
    // The split might result in \r\n handling issues if we aren't careful, but splitting by \n is usually safe enough for read/write cycle if we join back with \n
    const lines = content.split(/\r?\n/);

    if (lines.length > 409) {
        const newContent = lines.slice(0, 409).join('\n');
        fs.writeFileSync(targetPath, newContent);
        console.log(`Successfully truncated ${targetPath} to 409 lines.`);
    } else {
        console.log('File is already short, no truncation needed.');
    }
} catch (err) {
    console.error('Error fixing file:', err);
}
