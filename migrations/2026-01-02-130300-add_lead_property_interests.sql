-- Migration: Add Lead Property Interests System
-- Description: Creates tables for linking leads to properties and tracking interest history
-- Author: CRM Inmobiliario System
-- Date: 2024-12-20

-- Create ENUM for interest level
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'interest_level') THEN
    CREATE TYPE interest_level AS ENUM (
      'inquired',         -- Preguntó
      'interested',       -- Interesado
      'very_interested',  -- Muy interesado
      'scheduled_viewing',-- Cita agendada
      'viewed',           -- Visitó la propiedad
      'offer_made',       -- Hizo oferta
      'rejected',         -- Descartada
      'purchased'         -- Comprada/Rentada
    );
  END IF;
END$$;

-- Create table for active links between leads (deals) and properties
CREATE TABLE IF NOT EXISTS lead_property_interests (
  id SERIAL PRIMARY KEY,
  deal_id INTEGER NOT NULL REFERENCES deals(id) ON DELETE CASCADE,
  property_id INTEGER NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  
  status interest_level NOT NULL DEFAULT 'inquired',
  notes TEXT,
  
  -- Metadata
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  created_by INTEGER REFERENCES users(id)
);

-- Unique constraint to prevent duplicate active links
CREATE UNIQUE INDEX IF NOT EXISTS idx_lead_property_unique 
  ON lead_property_interests(deal_id, property_id);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_interests_deal ON lead_property_interests(deal_id);
CREATE INDEX IF NOT EXISTS idx_interests_property ON lead_property_interests(property_id);
CREATE INDEX IF NOT EXISTS idx_interests_status ON lead_property_interests(status);

-- Create table for history of changes (Audit Log)
CREATE TABLE IF NOT EXISTS lead_property_interest_history (
  id SERIAL PRIMARY KEY,
  interest_id INTEGER NOT NULL REFERENCES lead_property_interests(id) ON DELETE CASCADE,
  
  previous_status interest_level,
  new_status interest_level NOT NULL,
  
  note_added TEXT,
  
  changed_by INTEGER REFERENCES users(id),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Index for history
CREATE INDEX IF NOT EXISTS idx_interest_history_interest ON lead_property_interest_history(interest_id);

-- Function to update timestamp
CREATE OR REPLACE FUNCTION update_interest_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for timestamp
DROP TRIGGER IF EXISTS trigger_update_interest_timestamp ON lead_property_interests;
CREATE TRIGGER trigger_update_interest_timestamp
  BEFORE UPDATE ON lead_property_interests
  FOR EACH ROW
  EXECUTE FUNCTION update_interest_timestamp();
