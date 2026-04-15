-- Rollback migration: 20260415000001_create_saved_products_table
-- This script removes the saved_products table and all related objects

-- Drop RLS policies
DROP POLICY IF EXISTS "Users can update their own saved products" ON saved_products;
DROP POLICY IF EXISTS "Users can delete their own saved products" ON saved_products;
DROP POLICY IF EXISTS "Users can insert their own saved products" ON saved_products;
DROP POLICY IF EXISTS "Users can view their own saved products" ON saved_products;

-- Drop indexes
DROP INDEX IF EXISTS idx_saved_products_product_id;
DROP INDEX IF EXISTS idx_saved_products_saved_at;
DROP INDEX IF EXISTS idx_saved_products_user_id;

-- Drop table
DROP TABLE IF EXISTS saved_products;
