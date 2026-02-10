// Test setup and global configurations
import { beforeAll, afterAll, beforeEach, afterEach } from 'vitest';

// Global test setup
beforeAll(async () => {
    // Setup test database connection if needed
    console.log('🧪 Test suite starting...');
});

afterAll(async () => {
    // Cleanup test database connection
    console.log('✅ Test suite complete');
});

beforeEach(async () => {
    // Reset test database state before each test
});

afterEach(async () => {
    // Cleanup after each test
});

// Export test utilities
export const mockUser = {
    id: 1,
    email: 'test@example.com',
    companyId: 1,
    role: 'admin',
};

export const generateAuthToken = (userId: number = 1) => {
    // Mock JWT token for testing
    return `Bearer mock-token-${userId}`;
};
