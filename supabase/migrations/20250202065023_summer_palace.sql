/*
  # Fix RLS policies for deposits table

  1. Changes
    - Drop existing policies
    - Create new comprehensive policies for deposits table
    - Add proper admin access controls

  2. Security
    - Admins can view and manage all deposits
    - Regular users can only view and insert their own deposits
    - Proper user_id validation on insert
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can read deposits" ON deposits;
DROP POLICY IF EXISTS "Users can insert own deposits" ON deposits;

-- Create new policies
CREATE POLICY "Users can read deposits"
  ON deposits
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id 
    OR 
    EXISTS (
      SELECT 1 FROM auth.users 
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

-- Add default user_id on insert
ALTER TABLE deposits 
ALTER COLUMN user_id 
SET DEFAULT auth.uid();