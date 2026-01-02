-- Migration: Add Comments System
-- Description: Creates table for deal comments

CREATE TABLE IF NOT EXISTS deal_comments (
  id SERIAL PRIMARY KEY,
  deal_id INTEGER NOT NULL REFERENCES deals(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  comment TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Index for faster queries by deal
CREATE INDEX IF NOT EXISTS idx_deal_comments_deal_id ON deal_comments(deal_id);

-- Index for queries by user
CREATE INDEX IF NOT EXISTS idx_deal_comments_user_id ON deal_comments(user_id);

-- Index for ordering by creation date
CREATE INDEX IF NOT EXISTS idx_deal_comments_created_at ON deal_comments(created_at DESC);
