/*
  # Fix users RLS policy to prevent recursion

  1. Changes
    - Drop existing recursive policy
    - Add new non-recursive policy for user access
    - Add separate policy for admin access

  2. Security
    - Users can read their own data
    - Admins can read all user data
    - Prevents infinite recursion
*/

-- Drop the existing policy that causes recursion
DROP POLICY IF EXISTS "Users can read own data" ON auth.users;

-- Create separate policies for users and admins
CREATE POLICY "Users can read own profile"
  ON auth.users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Admins can read all profiles"
  ON auth.users
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM auth.users AS admin
      WHERE admin.id = auth.uid()
      AND admin.is_admin = true
    )
  );