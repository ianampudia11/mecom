#!/usr/bin/env tsx
/**
 * Schema Validation Script
 * 
 * Detecta definiciones duplicadas en shared/schema.ts para prevenir errores de compilación.
 * Puede ejecutarse manualmente o como pre-commit hook.
 */

import fs from 'fs';
import path from 'path';

interface DuplicateInfo {
    name: string;
    type: 'table' | 'enum' | 'export' | 'type';
    lines: number[];
}

function validateSchema(): { valid: boolean; duplicates: DuplicateInfo[] } {
    const schemaPath = path.join(process.cwd(), 'shared', 'schema.ts');

    if (!fs.existsSync(schemaPath)) {
        console.error('❌ No se encontró shared/schema.ts');
        process.exit(1);
    }

    const content = fs.readFileSync(schemaPath, 'utf-8');
    const lines = content.split('\n');

    const duplicates: DuplicateInfo[] = [];

    // Patrones a detectar
    const patterns = [
        { regex: /export const (\w+) = pgTable\(/g, type: 'table' as const },
        { regex: /export const (\w+) = pgEnum\(/g, type: 'enum' as const },
        { regex: /export const (insert\w+Schema) = createInsertSchema\(/g, type: 'export' as const },
        { regex: /export type (\w+) =/g, type: 'type' as const },
    ];

    for (const pattern of patterns) {
        const found = new Map<string, number[]>();

        lines.forEach((line, index) => {
            const matches = [...line.matchAll(pattern.regex)];
            matches.forEach(match => {
                const name = match[1];
                if (!found.has(name)) {
                    found.set(name, []);
                }
                found.get(name)!.push(index + 1); // 1-indexed
            });
        });

        // Detectar duplicados
        found.forEach((lineNumbers, name) => {
            if (lineNumbers.length > 1) {
                duplicates.push({
                    name,
                    type: pattern.type,
                    lines: lineNumbers,
                });
            }
        });
    }

    return { valid: duplicates.length === 0, duplicates };
}

function main() {
    console.log('🔍 Validando shared/schema.ts...\n');

    const { valid, duplicates } = validateSchema();

    if (valid) {
        console.log('✅ No se encontraron duplicados en el esquema');
        console.log('✅ Validación exitosa\n');
        process.exit(0);
    } else {
        console.log('❌ Se encontraron definiciones duplicadas:\n');

        duplicates.forEach(dup => {
            const typeLabel = {
                table: 'Tabla',
                enum: 'Enum',
                export: 'Schema Export',
                type: 'Tipo',
            }[dup.type];

            console.log(`  ${typeLabel}: "${dup.name}"`);
            console.log(`  Líneas: ${dup.lines.join(', ')}`);
            console.log('');
        });

        console.log('💡 Solución: Elimina las definiciones duplicadas o renómbralas\n');
        process.exit(1);
    }
}

main();
