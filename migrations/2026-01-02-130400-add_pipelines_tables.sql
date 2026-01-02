-- Create pipelines table
CREATE TABLE IF NOT EXISTS pipelines (
  id SERIAL PRIMARY KEY,
  company_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create pipeline_stages if not exists (for fresh installs)
CREATE TABLE IF NOT EXISTS pipeline_stages (
  id SERIAL PRIMARY KEY,
  pipeline_id INTEGER REFERENCES pipelines(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT DEFAULT '#3B82F6',
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Safely add pipeline_id to pipeline_stages if it was missing (for existing installs)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='pipeline_stages' AND column_name='pipeline_id') THEN
        ALTER TABLE pipeline_stages ADD COLUMN pipeline_id INTEGER REFERENCES pipelines(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_pipelines_company_id ON pipelines(company_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_stages_pipeline_id ON pipeline_stages(pipeline_id);

-- Migration: Create a default pipeline for existing companies if they have none
-- This ensures 'pipeline_stages' rows without pipeline_id are assigned to a default pipeline
DO $$
DECLARE
    comp RECORD;
    new_pipeline_id INTEGER;
BEGIN
    FOR comp IN SELECT DISTINCT company_id FROM users LOOP
        -- Check if company has a pipeline
        IF NOT EXISTS (SELECT 1 FROM pipelines WHERE company_id = comp.company_id) THEN
            INSERT INTO pipelines (company_id, name, description, is_default)
            VALUES (comp.company_id, 'Default Pipeline', 'Pipeline por defecto', TRUE)
            RETURNING id INTO new_pipeline_id;
            
            -- Link orphan stages to this new pipeline? 
            -- If pipeline_stages were global before (no company_id), valid for all? 
            -- Assuming they belong to the company context implicitly or we leave them null?
            -- If strictly necessary, we'd update them here.
             UPDATE pipeline_stages SET pipeline_id = new_pipeline_id WHERE pipeline_id IS NULL;
        END IF;
    END LOOP;
END $$;
