const fs = require('fs');

// Read the file
const content = fs.readFileSync('c:\\Users\\ianam\\.gemini\\antigravity\\scratch\\ianampudia11\\server\\storage.ts', 'utf8');
const lines = content.split('\n');

console.log(`Total lines in file: ${lines.length}`);

// Keep only lines 1-6497 (indices 0-6496)
const validLines = lines.slice(0, 6497);

// Add the closing brace for the DatabaseStorage class and the export statement
validLines.push('}');  // Close the DatabaseStorage class
validLines.push('');
validLines.push('export const storage = new DatabaseStorage();');

// Write back to file
const newContent = validLines.join('\n');
fs.writeFileSync('c:\\Users\\ianam\\.gemini\\antigravity\\scratch\\ianampudia11\\server\\storage.ts', newContent, 'utf8');

console.log(`File cleaned: ${validLines.length} lines kept, ${lines.length - validLines.length} lines removed`);
console.log('Added closing brace and export statement');
