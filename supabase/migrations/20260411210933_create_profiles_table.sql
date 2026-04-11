-- Create profiles table
-- Requirements: 1.1, 1.2, 1.4

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  bio TEXT,
  avatar_url TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index on updated_at for performance
CREATE INDEX IF NOT EXISTS idx_profiles_updated_at ON profiles(updated_at);

-- Add comment to table
COMMENT ON TABLE profiles IS 'User profile information linked to auth.users';
COMMENT ON COLUMN profiles.id IS 'User ID from auth.users';
COMMENT ON COLUMN profiles.full_name IS 'User full name';
COMMENT ON COLUMN profiles.bio IS 'User biography/description';
COMMENT ON COLUMN profiles.avatar_url IS 'URL to user avatar image in storage';
COMMENT ON COLUMN profiles.updated_at IS 'Timestamp of last profile update';
