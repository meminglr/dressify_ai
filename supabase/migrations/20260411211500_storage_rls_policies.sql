-- Enable RLS on storage.objects and create policies for avatars and gallery buckets
-- Requirements: 7.1, 7.2, 7.3, 7.4

-- Enable Row Level Security on storage.objects table
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- ============================================
-- AVATARS BUCKET POLICIES
-- ============================================

-- SELECT policy: Users can view their own avatars
CREATE POLICY "Users can view their own avatars"
  ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'avatars' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- INSERT policy: Users can upload their own avatars
CREATE POLICY "Users can upload their own avatars"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- DELETE policy: Users can delete their own avatars
CREATE POLICY "Users can delete their own avatars"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'avatars' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- ============================================
-- GALLERY BUCKET POLICIES
-- ============================================

-- SELECT policy: Users can view their own gallery
CREATE POLICY "Users can view their own gallery"
  ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'gallery' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- INSERT policy: Users can upload to their own gallery
CREATE POLICY "Users can upload to their own gallery"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'gallery' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- DELETE policy: Users can delete from their own gallery
CREATE POLICY "Users can delete from their own gallery"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'gallery' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Add comments for documentation
COMMENT ON POLICY "Users can view their own avatars" ON storage.objects IS 'Users can only view avatars in their own folder';
COMMENT ON POLICY "Users can upload their own avatars" ON storage.objects IS 'Users can only upload avatars to their own folder';
COMMENT ON POLICY "Users can delete their own avatars" ON storage.objects IS 'Users can only delete avatars from their own folder';
COMMENT ON POLICY "Users can view their own gallery" ON storage.objects IS 'Users can only view gallery images in their own folder';
COMMENT ON POLICY "Users can upload to their own gallery" ON storage.objects IS 'Users can only upload gallery images to their own folder';
COMMENT ON POLICY "Users can delete from their own gallery" ON storage.objects IS 'Users can only delete gallery images from their own folder';
