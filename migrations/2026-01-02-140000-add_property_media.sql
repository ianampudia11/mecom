-- Migration: Add Property Media System
-- Description: Creates property_media table for unlimited photos, videos, flyers
-- Author: CRM Inmobiliario System
-- Date: 2024-12-16

-- Create ENUM type for media types
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'media_type') THEN
    CREATE TYPE media_type AS ENUM (
      'image',          -- Regular photo
      'flyer',          -- Professional flyer
      'video',          -- Video
      'floor_plan',     -- Floor plan
      'document',       -- PDF, contracts
      'virtual_tour'    -- For future 360° tours
    );
  END IF;
END$$;

-- Create property_media table
CREATE TABLE IF NOT EXISTS property_media (
  id SERIAL PRIMARY KEY,
  property_id INTEGER NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  
  media_type media_type NOT NULL DEFAULT 'image',
  file_url TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_size INTEGER NOT NULL,              -- In bytes
  mime_type TEXT NOT NULL,
  
  -- Metadata
  title TEXT,
  description TEXT,
  order_num INTEGER DEFAULT 0,
  is_primary BOOLEAN DEFAULT false,        -- Featured image
  is_flyer BOOLEAN DEFAULT false,          -- Mark as flyer
  
  -- Image dimensions (for images)
  width INTEGER,
  height INTEGER,
  
  -- Video metadata
  duration INTEGER,                        -- Seconds
  thumbnail_url TEXT,                      -- Video thumbnail
  
  uploaded_by INTEGER REFERENCES users(id),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_property_media_property ON property_media(property_id);
CREATE INDEX IF NOT EXISTS idx_property_media_type ON property_media(media_type);
CREATE INDEX IF NOT EXISTS idx_property_media_order ON property_media(property_id, order_num);
CREATE INDEX IF NOT EXISTS idx_property_media_primary ON property_media(property_id, is_primary) 
  WHERE is_primary = true;

-- Only one primary image per property
CREATE UNIQUE INDEX IF NOT EXISTS idx_property_media_one_primary 
  ON property_media(property_id) 
  WHERE is_primary = true;

-- Function to auto-update primary image when deleting
CREATE OR REPLACE FUNCTION update_primary_image_on_delete()
RETURNS TRIGGER AS $$
BEGIN
  -- If we're deleting the primary image, set the next one as primary
  IF OLD.is_primary = true THEN
    UPDATE property_media 
    SET is_primary = true
    WHERE id = (
      SELECT id
      FROM property_media
      WHERE property_id = OLD.property_id 
        AND id != OLD.id 
        AND media_type = 'image'
      ORDER BY order_num ASC
      LIMIT 1
    );
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update primary image
DROP TRIGGER IF EXISTS trigger_update_primary_on_delete ON property_media;
CREATE TRIGGER trigger_update_primary_on_delete
  BEFORE DELETE ON property_media
  FOR EACH ROW
  EXECUTE FUNCTION update_primary_image_on_delete();
