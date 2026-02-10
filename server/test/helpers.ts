// Test helpers and utilities
export const mockDeal = {
    id: 1,
    title: 'Test Deal',
    value: 5000,
    status: 'open' as const,
    priority: 'medium' as const,
    companyId: 1,
    pipelineId: 1,
    stageId: 1,
    contactId: null,
    assignedToUserId: null,
    description: 'Test description',
    expectedCloseDate: new Date(),
    tags: [],
    customFields: {},
    createdAt: new Date(),
    updatedAt: new Date(),
};

export const mockContact = {
    id: 1,
    firstName: 'John',
    lastName: 'Doe',
    email: 'john@example.com',
    phone: '+1234567890',
    companyId: 1,
    tags: [],
    customFields: {},
    createdAt: new Date(),
    updatedAt: new Date(),
};

export const createMockDeal = (overrides?: Partial<typeof mockDeal>) => ({
    ...mockDeal,
    ...overrides,
});

export const createMockContact = (overrides?: Partial<typeof mockContact>) => ({
    ...mockContact,
    ...overrides,
});
