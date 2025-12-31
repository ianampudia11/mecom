-- Migration: Add Checklists System
-- Description: Creates tables for deal checklists and checklist items

-- Table for checklist groups
CREATE TABLE IF NOT EXISTS deal_checklists (
  id SERIAL PRIMARY KEY,
  deal_id INTEGER NOT NULL REFERENCES deals(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  order_num INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_deal_checklists_deal_id ON deal_checklists(deal_id);

-- Table for individual checklist items
CREATE TABLE IF NOT EXISTS deal_checklist_items (
  id SERIAL PRIMARY KEY,
  checklist_id INTEGER NOT NULL REFERENCES deal_checklists(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  order_num INTEGER NOT NULL DEFAULT 0,
  completed_at TIMESTAMP,
  completed_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_deal_checklist_items_checklist_id ON deal_checklist_items(checklist_id);
