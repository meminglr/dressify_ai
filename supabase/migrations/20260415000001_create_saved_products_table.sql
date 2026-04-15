-- Create saved_products table for Trendyol products saved to wardrobe
-- Migration: 20260415000001_create_saved_products_table

-- Create saved_products table
CREATE TABLE IF NOT EXISTS saved_products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  product_image TEXT NOT NULL,
  product_price NUMERIC(10, 2) NOT NULL,
  product_url TEXT NOT NULL,
  saved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure a user can't save the same product twice
  UNIQUE(user_id, product_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_saved_products_user_id 
  ON saved_products(user_id);

CREATE INDEX IF NOT EXISTS idx_saved_products_saved_at 
  ON saved_products(saved_at DESC);

CREATE INDEX IF NOT EXISTS idx_saved_products_product_id 
  ON saved_products(product_id);

-- Enable Row Level Security
ALTER TABLE saved_products ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own saved products
CREATE POLICY "Users can view their own saved products"
  ON saved_products
  FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own saved products
CREATE POLICY "Users can insert their own saved products"
  ON saved_products
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can delete their own saved products
CREATE POLICY "Users can delete their own saved products"
  ON saved_products
  FOR DELETE
  USING (auth.uid() = user_id);

-- RLS Policy: Users can update their own saved products (optional, for future use)
CREATE POLICY "Users can update their own saved products"
  ON saved_products
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Add comment to table
COMMENT ON TABLE saved_products IS 'Stores Trendyol products saved by users to their wardrobe';

-- Add comments to columns
COMMENT ON COLUMN saved_products.id IS 'Primary key';
COMMENT ON COLUMN saved_products.user_id IS 'Reference to auth.users';
COMMENT ON COLUMN saved_products.product_id IS 'Trendyol product ID';
COMMENT ON COLUMN saved_products.product_name IS 'Product name from Trendyol';
COMMENT ON COLUMN saved_products.product_image IS 'Product image URL from Trendyol';
COMMENT ON COLUMN saved_products.product_price IS 'Product price at the time of saving';
COMMENT ON COLUMN saved_products.product_url IS 'Trendyol product URL';
COMMENT ON COLUMN saved_products.saved_at IS 'Timestamp when product was saved';
