/*
  # Fix RLS policies to prevent recursion

  1. Changes
    - Create materialized view for admin users
    - Drop and recreate policies to avoid conflicts
    - Implement simplified policy logic

  2. Security
    - Maintain existing security model
    - Prevent policy recursion
    - Keep admin access intact
*/

-- Create materialized view for admin users if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_matviews WHERE matviewname = 'admin_users'
  ) THEN
    CREATE MATERIALIZED VIEW admin_users AS
    SELECT id
    FROM auth.users
    WHERE is_admin = true;
  END IF;
END $$;

-- Drop existing policies if they exist
DO $$ 
BEGIN
  -- Drop auth.users policies
  DROP POLICY IF EXISTS "Users can read own profile" ON auth.users;
  DROP POLICY IF EXISTS "Admins can read all profiles" ON auth.users;
  DROP POLICY IF EXISTS "Users access policy" ON auth.users;
  
  -- Drop deposits policies
  DROP POLICY IF EXISTS "Users can read deposits" ON deposits;
  DROP POLICY IF EXISTS "Deposits access policy" ON deposits;
END $$;

-- Create simplified user policies
CREATE POLICY "Users access policy"
ON auth.users
FOR SELECT
TO authenticated
USING (
  id = auth.uid() OR
  auth.uid() IN (SELECT id FROM admin_users)
);

-- Create simplified deposits policies
CREATE POLICY "Deposits access policy"
ON deposits
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR
  auth.uid() IN (SELECT id FROM admin_users)
);