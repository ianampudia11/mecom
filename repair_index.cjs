const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'server', 'index.ts');
const content = fs.readFileSync(filePath, 'utf8');
const lines = content.split('\n');

if (lines.length > 409) {
    const validLines = lines.slice(0, 409);

    // Clean the last line (index 408)
    let lastLine = validLines[408];
    const endMarker = '})();';
    if (lastLine.includes(endMarker)) {
        // Keep only up to the end marker
        validLines[408] = endMarker;
    }

    const newContent = validLines.join('\n');
    fs.writeFileSync(filePath, newContent);
    console.log('Successfully truncated server/index.ts to 409 lines');
} else {
    console.log('File length is ' + lines.length + ', checking last line...');
    // If exact length match or shorter, ensure it ends clean
    if (lines.length >= 409) {
        let lastLine = lines[408];
        if (lastLine.includes('})();')) {
            lines[408] = '})();';
            // If there are extra garbage lines (like what we saw 409-429), slicing should have caught them.
            // Logic check: if lines.length > 409, we sliced. If <= 409, we might still have garbage on the same line.
            // But viewing the file showed garbage starting AFTER.
        }
        // Re-write to fail-safe
        // Actually, if we are unsure, just write strictly the first 409 lines if index 408 has the marker.
    }
}
