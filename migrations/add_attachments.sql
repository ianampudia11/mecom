-- Migration: Add Attachments System
-- Description: Creates table for deal file attachments

CREATE TABLE IF NOT EXISTS deal_attachments (
  id SERIAL PRIMARY KEY,
  deal_id INTEGER NOT NULL REFERENCES deals(id) ON DELETE CASCADE,
  uploaded_by INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  filename TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  mime_type TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Index for faster queries by deal
CREATE INDEX IF NOT EXISTS idx_deal_attachments_deal_id ON deal_attachments(deal_id);

-- Index for queries by uploader
CREATE INDEX IF NOT EXISTS idx_deal_attachments_uploaded_by ON deal_attachments(uploaded_by);

-- Index for ordering by creation date
CREATE INDEX IF NOT EXISTS idx_deal_attachments_created_at ON deal_attachments(created_at DESC);
