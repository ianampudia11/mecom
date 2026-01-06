-- Migration: Repair missing tables (tags, contact_tags, contact_tasks, task_categories)
-- Description: Ensures these tables exist if they were missed by previous migrations

-- 1. Tags Table
CREATE TABLE IF NOT EXISTS tags (
  id SERIAL PRIMARY KEY,
  name VARCHAR NOT NULL,
  color VARCHAR,
  company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(company_id, name)
);

-- 2. Contact Tags (Join Table)
CREATE TABLE IF NOT EXISTS contact_tags (
  id SERIAL PRIMARY KEY,
  contact_id INTEGER REFERENCES contacts(id) ON DELETE CASCADE,
  tag_id INTEGER REFERENCES tags(id) ON DELETE CASCADE,
  UNIQUE(contact_id, tag_id)
);

-- 3. Task Categories
CREATE TABLE IF NOT EXISTS task_categories (
  id SERIAL PRIMARY KEY,
  company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT,
  icon TEXT,
  created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 4. Contact Tasks
CREATE TABLE IF NOT EXISTS contact_tasks (
  id SERIAL PRIMARY KEY,
  contact_id INTEGER NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
  company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  
  -- Task details
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  status TEXT NOT NULL DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed', 'cancelled')),
  
  -- Scheduling
  due_date TIMESTAMP,
  completed_at TIMESTAMP,
  
  -- Assignment and categorization
  assigned_to TEXT,
  category TEXT,
  tags TEXT[], -- Keeping for backward compatibility if used, though contact_tags is better
  
  -- Audit
  created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
  updated_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
  
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

  -- New columns found in dump
  background_color VARCHAR DEFAULT '#ffffff',
  checklist JSONB DEFAULT '[]'::jsonb
);

-- Indexes for contact_tasks
CREATE INDEX IF NOT EXISTS idx_contact_tasks_contact_id ON contact_tasks(contact_id);
CREATE INDEX IF NOT EXISTS idx_contact_tasks_company_id ON contact_tasks(company_id);
CREATE INDEX IF NOT EXISTS idx_contact_tasks_status ON contact_tasks(status);

-- Indexes for tags
CREATE INDEX IF NOT EXISTS idx_tags_company_id ON tags(company_id);

-- Indexes for contact_tags
CREATE INDEX IF NOT EXISTS idx_contact_tags_contact_id ON contact_tags(contact_id);
CREATE INDEX IF NOT EXISTS idx_contact_tags_tag_id ON contact_tags(tag_id);
