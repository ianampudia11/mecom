import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
    test: {
        globals: true,
        environment: 'node',
        setupFiles: ['./server/test/setup.ts'],
        coverage: {
            provider: 'v8',
            reporter: ['text', 'json', 'html'],
            include: ['server/modules/**/*.ts'],
            exclude: [
                'server/**/*.test.ts',
                'server/**/__tests__/**',
                'server/test/**'
            ]
        },
        testTimeout: 10000,
    },
    resolve: {
        alias: {
            '@shared': path.resolve(__dirname, './shared'),
        },
    },
});
