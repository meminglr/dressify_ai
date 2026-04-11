-- Create database triggers
-- Requirements: 1.3, 1.4

-- Function to handle new user creation
-- Automatically creates a profile when a new user is created in auth.users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Trigger to automatically create profile on user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Add comment to function
COMMENT ON FUNCTION handle_new_user() IS 'Automatically creates a profile record when a new user is created in auth.users';

-- Function to handle profile updates
-- Automatically updates the updated_at timestamp when a profile is updated
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Trigger to automatically update timestamp on profile update
CREATE TRIGGER on_profile_updated
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- Add comment to function
COMMENT ON FUNCTION handle_updated_at() IS 'Automatically updates the updated_at timestamp when a profile is updated';
