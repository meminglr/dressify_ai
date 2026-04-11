-- Create media table
-- Requirements: 2.1, 2.2, 2.3, 2.4

CREATE TABLE IF NOT EXISTS media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('AI_CREATION', 'MODEL', 'UPLOAD')),
  style_tag TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index on user_id and created_at for performance
CREATE INDEX IF NOT EXISTS idx_media_user_created ON media(user_id, created_at DESC);

-- Add comments to table
COMMENT ON TABLE media IS 'User media content (AI creations, uploads, models)';
COMMENT ON COLUMN media.id IS 'Unique media identifier';
COMMENT ON COLUMN media.user_id IS 'User ID from auth.users who owns this media';
COMMENT ON COLUMN media.image_url IS 'URL to media image in storage';
COMMENT ON COLUMN media.type IS 'Media type: AI_CREATION, MODEL, or UPLOAD';
COMMENT ON COLUMN media.style_tag IS 'Optional style tag for categorization';
COMMENT ON COLUMN media.created_at IS 'Timestamp when media was created';
