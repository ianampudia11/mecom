# Script to clean storage.ts by removing corrupted duplicate code
with open(r'c:\Users\ianam\.gemini\antigravity\scratch\ianampudia11\server\storage.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Keep lines 1-6497 (head) and 11724-end (tail)
# Arrays are 0-indexed, so line 6497 is index 6496
head = lines[0:6497]  # Lines 1-6497
tail = lines[11723:]  # Lines 11724-end (index 11723 is line 11724)

# Write cleaned content
with open(r'c:\Users\ianam\.gemini\antigravity\scratch\ianampudia11\server\storage.ts', 'w', encoding='utf-8') as f:
    f.writelines(head)
    f.write('\n')  # Add blank line between class and export
    f.writelines(tail)

print(f"Cleaned storage.ts: kept {len(head)} + {len(tail)} lines, removed {len(lines) - len(head) - len(tail)} lines")
