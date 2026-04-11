-- Enable RLS on profiles table and create policies
-- Requirements: 5.1, 5.2, 5.3, 5.4

-- Enable Row Level Security on profiles table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- SELECT policy: Everyone can view all profiles
CREATE POLICY "Profiles are viewable by everyone"
  ON profiles
  FOR SELECT
  USING (true);

-- INSERT policy: Users can only insert their own profile
CREATE POLICY "Users can insert their own profile"
  ON profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- UPDATE policy: Users can only update their own profile
CREATE POLICY "Users can update their own profile"
  ON profiles
  FOR UPDATE
  USING (auth.uid() = id);

-- Add comments for documentation
COMMENT ON POLICY "Profiles are viewable by everyone" ON profiles IS 'Allow all users to view any profile';
COMMENT ON POLICY "Users can insert their own profile" ON profiles IS 'Users can only create their own profile record';
COMMENT ON POLICY "Users can update their own profile" ON profiles IS 'Users can only update their own profile information';
