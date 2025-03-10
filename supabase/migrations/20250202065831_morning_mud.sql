/*
  # Fix database relationships and views

  1. Changes
    - Drop dependent policies first
    - Update views and materialized views
    - Add proper indexes
    - Recreate policies with correct dependencies

  2. Security
    - Maintain RLS policies
    - Ensure proper access control
*/

-- First drop all dependent policies
DROP POLICY IF EXISTS "Users access policy" ON auth.users;
DROP POLICY IF EXISTS "Deposits access policy" ON deposits;
DROP POLICY IF EXISTS "Admins can update deposit status" ON deposits;
DROP POLICY IF EXISTS "Users can read deposits" ON deposits;
DROP POLICY IF EXISTS "Users can insert own deposits" ON deposits;

-- Now we can safely drop the views
DROP VIEW IF EXISTS users CASCADE;
DROP MATERIALIZED VIEW IF EXISTS admin_users CASCADE;

-- Create users view with proper fields
CREATE OR REPLACE VIEW users AS
SELECT 
  id,
  email,
  raw_user_meta_data,
  COALESCE(is_admin, false) as is_admin
FROM auth.users;

-- Create index on auth.users for is_admin
CREATE INDEX IF NOT EXISTS idx_users_is_admin ON auth.users(is_admin);

-- Update deposits table
ALTER TABLE deposits
DROP CONSTRAINT IF EXISTS deposits_user_id_fkey,
ADD CONSTRAINT deposits_user_id_fkey 
  FOREIGN KEY (user_id) 
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

-- Create index on deposits for user_id
CREATE INDEX IF NOT EXISTS idx_deposits_user_id ON deposits(user_id);

-- Recreate admin users view
CREATE MATERIALIZED VIEW admin_users AS
SELECT id
FROM auth.users
WHERE is_admin = true;

-- Create index on admin_users
CREATE UNIQUE INDEX IF NOT EXISTS idx_admin_users_id ON admin_users(id);

-- Recreate the policies
CREATE POLICY "Users access policy"
ON auth.users
FOR SELECT
TO authenticated
USING (
  id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND is_admin = true
  )
);

CREATE POLICY "Deposits access policy"
ON deposits
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND is_admin = true
  )
);

CREATE POLICY "Users can insert own deposits"
ON deposits
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id
);

CREATE POLICY "Admins can update deposit status"
ON deposits
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND is_admin = true
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND is_admin = true
  )
);

-- Refresh materialized view
REFRESH MATERIALIZED VIEW admin_users;