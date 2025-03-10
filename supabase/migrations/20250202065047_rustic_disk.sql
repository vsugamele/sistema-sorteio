/*
  # Add RLS policies for users table

  1. Changes
    - Enable RLS on auth.users table
    - Add policies for user access
    - Add policies for admin access

  2. Security
    - Users can read their own data
    - Admins can read all user data
    - No direct write access to users table (managed by auth)
*/

-- Enable RLS on users table if not already enabled
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- Create policy for users to read their own data
CREATE POLICY "Users can read own data"
  ON auth.users
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = id 
    OR 
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
      AND is_admin = true
    )
  );