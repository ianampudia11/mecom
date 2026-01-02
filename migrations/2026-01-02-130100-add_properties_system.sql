-- Migration: Add Properties System
-- Description: Creates properties, property types, and related structures
-- Author: CRM Inmobiliario System
-- Date: 2024-12-10

-- Create ENUM types for property
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'property_type') THEN
    CREATE TYPE property_type AS ENUM (
      'house',
      'apartment', 
      'land',
      'commercial',
      'office',
      'warehouse',
      'other'
    );
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'property_status') THEN
    CREATE TYPE property_status AS ENUM (
      'available',
      'reserved',
      'sold',
      'rented',
      'pending',
      'inactive'
    );
  END IF;
END$$;

-- Create properties table
CREATE TABLE IF NOT EXISTS properties (
  id SERIAL PRIMARY KEY,
  company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  
  -- Basic Information
  title TEXT NOT NULL,
  property_type property_type NOT NULL DEFAULT 'house',
  status property_status DEFAULT 'available',
  reference_code TEXT,                      -- REF-001, PROP-123, etc.
  
  -- Description
  description TEXT,
  sales_speech TEXT,                        -- Long speech for agents
  quick_description TEXT,                   -- For WhatsApp (max 300 chars)
  
  -- Pricing
  price NUMERIC(12, 2),
  currency TEXT DEFAULT 'USD',
  price_per_m2 NUMERIC(10, 2),
  negotiable BOOLEAN DEFAULT true,
  
  -- Location
  address TEXT,
  city TEXT,
  state TEXT,
  country TEXT,
  zip_code TEXT,
  neighborhood TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  
  -- Characteristics
  bedrooms INTEGER,
  bathrooms INTEGER,
  half_bathrooms INTEGER DEFAULT 0,
  parking_spaces INTEGER DEFAULT 0,
  area_m2 NUMERIC(10, 2),
  area_ft2 NUMERIC(10, 2),
  lot_size_m2 NUMERIC(10, 2),
  construction_year INTEGER,
  floors INTEGER DEFAULT 1,
  
  -- Amenities (flexible JSON structure)
  features JSONB DEFAULT '{}',
  -- Example: {
  --   "pool": true,
  --   "garden": true,
  --   "elevator": false,
  --   "security": "24/7",
  --   "furnished": "partial",
  --   "air_conditioning": true
  -- }
  
  -- Metadata
  tags TEXT[],
  assigned_agent_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  created_by INTEGER REFERENCES users(id),
  
  -- SEO/Portal (for future use)
  slug TEXT,
  is_featured BOOLEAN DEFAULT false,
  views_count INTEGER DEFAULT 0,
  
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_properties_company ON properties(company_id);
CREATE INDEX IF NOT EXISTS idx_properties_status ON properties(status);
CREATE INDEX IF NOT EXISTS idx_properties_type ON properties(property_type);
CREATE INDEX IF NOT EXISTS idx_properties_agent ON properties(assigned_agent_id);
CREATE INDEX IF NOT EXISTS idx_properties_city ON properties(city);
CREATE INDEX IF NOT EXISTS idx_properties_created ON properties(created_at DESC);

-- Unique constraint for reference_code per company
CREATE UNIQUE INDEX IF NOT EXISTS idx_properties_company_reference 
  ON properties(company_id, reference_code) 
  WHERE reference_code IS NOT NULL;

-- Unique constraint for slug (for future portal)
CREATE UNIQUE INDEX IF NOT EXISTS idx_properties_slug 
  ON properties(slug) 
  WHERE slug IS NOT NULL;

-- Function to auto-generate slug from title
CREATE OR REPLACE FUNCTION generate_property_slug()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.slug IS NULL AND NEW.title IS NOT NULL THEN
    NEW.slug := lower(regexp_replace(NEW.title, '[^a-zA-Z0-9]+', '-', 'g'));
    NEW.slug := regexp_replace(NEW.slug, '-+', '-', 'g');
    NEW.slug := trim(both '-' from NEW.slug);
    -- Add ID suffix to ensure uniqueness
    NEW.slug := NEW.slug || '-' || NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate slug
DROP TRIGGER IF EXISTS trigger_generate_property_slug ON properties;
CREATE TRIGGER trigger_generate_property_slug
  BEFORE INSERT ON properties
  FOR EACH ROW
  EXECUTE FUNCTION generate_property_slug();

-- Function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_property_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update timestamp
DROP TRIGGER IF EXISTS trigger_update_property_timestamp ON properties;
CREATE TRIGGER trigger_update_property_timestamp
  BEFORE UPDATE ON properties
  FOR EACH ROW
  EXECUTE FUNCTION update_property_timestamp();
