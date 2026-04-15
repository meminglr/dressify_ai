-- Extend media table to support Trendyol products
-- Migration: 20260415000002_extend_media_table_for_trendyol

-- Check if media_type enum exists and add TRENDYOL_PRODUCT if not present
DO $$ 
BEGIN
  -- Check if the enum type exists
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'media_type') THEN
    -- Check if TRENDYOL_PRODUCT value already exists
    IF NOT EXISTS (
      SELECT 1 FROM pg_enum 
      WHERE enumtypid = 'media_type'::regtype 
      AND enumlabel = 'TRENDYOL_PRODUCT'
    ) THEN
      -- Add new enum value
      ALTER TYPE media_type ADD VALUE IF NOT EXISTS 'TRENDYOL_PRODUCT';
    END IF;
  ELSE
    -- Create the enum type if it doesn't exist
    CREATE TYPE media_type AS ENUM ('UPLOAD', 'MODEL', 'AI_LOOK', 'TRENDYOL_PRODUCT');
  END IF;
END $$;

-- Add trendyol_product_id column to media table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'media' 
    AND column_name = 'trendyol_product_id'
  ) THEN
    ALTER TABLE media ADD COLUMN trendyol_product_id TEXT;
  END IF;
END $$;

-- Create index for Trendyol products if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_media_trendyol_product_id 
  ON media(trendyol_product_id) 
  WHERE trendyol_product_id IS NOT NULL;

-- Create index for media type if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_media_type 
  ON media(type);

-- Add comment to new column
COMMENT ON COLUMN media.trendyol_product_id IS 'Trendyol product ID for TRENDYOL_PRODUCT type media';

-- Add check constraint to ensure trendyol_product_id is set for TRENDYOL_PRODUCT type
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'media_trendyol_product_id_check'
  ) THEN
    ALTER TABLE media ADD CONSTRAINT media_trendyol_product_id_check 
      CHECK (
        (type = 'TRENDYOL_PRODUCT' AND trendyol_product_id IS NOT NULL) OR
        (type != 'TRENDYOL_PRODUCT')
      );
  END IF;
END $$;
