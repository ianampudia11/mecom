-- Add missing assigned_to_user_id column to conversations table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'conversations' 
        AND column_name = 'assigned_to_user_id'
    ) THEN
        ALTER TABLE conversations 
        ADD COLUMN assigned_to_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL;
        
        RAISE NOTICE 'Added assigned_to_user_id column to conversations table';
    END IF;
    
    -- Also check for indices that might be missing
    IF NOT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE tablename = 'conversations'
        AND indexname = 'idx_conversations_assigned_to_user_id'
    ) THEN
        CREATE INDEX idx_conversations_assigned_to_user_id ON conversations(assigned_to_user_id);
    END IF;
END $$;
