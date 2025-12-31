const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'server', 'index.ts');
const content = fs.readFileSync(filePath, 'utf8');
const lines = content.split('\n');

if (lines.length > 409) {
    // Keep first 409 lines only. 
    // Line 409 in the file is index 408.
    // Wait, view_file says "409: })(); ...". That is the 409th line (1-indexed).
    // So we want line indices 0 to 408.

    const validLines = lines.slice(0, 409);

    // Ensure the last line is clean (it might have " / /" appended)
    // Line 409 content: "})();/ /"
    // We need to trim line 409 to just "})();"

    let lastLine = validLines[408];
    const endMarker = '})();';
    if (lastLine.includes(endMarker)) {
        validLines[408] = endMarker;
    }

    const newContent = validLines.join('\n');
    fs.writeFileSync(filePath, newContent);
    console.log('Successfully truncated server/index.ts to 409 lines');
} else {
    console.log('File is already short enough, checking for garbage on last line');
    // Logic to clean last line if needed...
}
