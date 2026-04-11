-- Enable RLS on media table and create policies
-- Requirements: 6.1, 6.2, 6.3, 6.4

-- Enable Row Level Security on media table
ALTER TABLE media ENABLE ROW LEVEL SECURITY;

-- SELECT policy: Users can only view their own media
CREATE POLICY "Users can view their own media"
  ON media
  FOR SELECT
  USING (auth.uid() = user_id);

-- INSERT policy: Users can only insert their own media
CREATE POLICY "Users can insert their own media"
  ON media
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- DELETE policy: Users can only delete their own media
CREATE POLICY "Users can delete their own media"
  ON media
  FOR DELETE
  USING (auth.uid() = user_id);

-- Add comments for documentation
COMMENT ON POLICY "Users can view their own media" ON media IS 'Users can only view media they own';
COMMENT ON POLICY "Users can insert their own media" ON media IS 'Users can only create media records for themselves';
COMMENT ON POLICY "Users can delete their own media" ON media IS 'Users can only delete their own media records';
