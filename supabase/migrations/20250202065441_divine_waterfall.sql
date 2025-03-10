/*
  # Fix admin users view and policies

  1. Changes
    - Create public users view for accessing auth.users data
    - Update policies to use the new view
    - Fix admin access checks
  
  2. Security
    - Maintain RLS security
    - Ensure proper admin access
*/

-- Create a view to safely access auth.users data
CREATE OR REPLACE VIEW users AS
SELECT id, email, is_admin, raw_user_meta_data
FROM auth.users;

-- Create materialized view for admin users
CREATE MATERIALIZED VIEW IF NOT EXISTS admin_users AS
SELECT id
FROM auth.users
WHERE is_admin = true;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can read own profile" ON auth.users;
DROP POLICY IF EXISTS "Admins can read all profiles" ON auth.users;
DROP POLICY IF EXISTS "Users access policy" ON auth.users;
DROP POLICY IF EXISTS "Users can read deposits" ON deposits;
DROP POLICY IF EXISTS "Deposits access policy" ON deposits;

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

-- Refresh materialized view
REFRESH MATERIALIZED VIEW admin_users;