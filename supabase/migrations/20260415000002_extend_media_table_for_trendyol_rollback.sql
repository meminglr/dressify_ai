-- Rollback migration: 20260415000002_extend_media_table_for_trendyol
-- This script removes Trendyol-related extensions from media table

-- Drop check constraint
ALTER TABLE media DROP CONSTRAINT IF EXISTS media_trendyol_product_id_check;

-- Drop indexes
DROP INDEX IF EXISTS idx_media_type;
DROP INDEX IF EXISTS idx_media_trendyol_product_id;

-- Drop column
ALTER TABLE media DROP COLUMN IF EXISTS trendyol_product_id;

-- Note: We don't remove the TRENDYOL_PRODUCT enum value as PostgreSQL
-- doesn't support removing enum values directly. If you need to remove it,
-- you would need to:
-- 1. Create a new enum without TRENDYOL_PRODUCT
-- 2. Alter the column to use the new enum
-- 3. Drop the old enum
-- This is complex and risky, so we leave the enum value in place.
