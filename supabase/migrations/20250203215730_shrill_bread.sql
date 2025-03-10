/*
  # Fix recursive policies with optimized approach
  
  1. Changes
    - Remove all recursive policy dependencies
    - Create admin check function for better performance
    - Simplify policy conditions
    - Maintain same security model with optimized implementation
*/

-- Create a function to check if a user is admin
CREATE OR REPLACE FUNCTION is_admin(user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT COALESCE(is_admin, false)
  FROM auth.users
  WHERE id = user_id;
$$;

-- Drop existing policies
DROP POLICY IF EXISTS "Users access policy" ON auth.users;
DROP POLICY IF EXISTS "Deposits access policy" ON deposits;
DROP POLICY IF EXISTS "Admins can update deposit status" ON deposits;
DROP POLICY IF EXISTS "Admins can manage prizes" ON roulette_prizes;
DROP POLICY IF EXISTS "Admins can view all spins" ON roulette_spins;
DROP POLICY IF EXISTS "Users can read own tickets" ON tickets;
DROP POLICY IF EXISTS "Admins can update tickets" ON tickets;

-- Create optimized policies using the is_admin function
CREATE POLICY "Users access policy"
ON auth.users
FOR SELECT
TO authenticated
USING (
  id = auth.uid() OR
  is_admin(auth.uid())
);

CREATE POLICY "Deposits access policy"
ON deposits
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR
  is_admin(auth.uid())
);

CREATE POLICY "Admins can update deposit status"
ON deposits
FOR UPDATE
TO authenticated
USING (is_admin(auth.uid()))
WITH CHECK (is_admin(auth.uid()));

CREATE POLICY "Admins can manage prizes"
ON roulette_prizes
FOR ALL
TO authenticated
USING (is_admin(auth.uid()))
WITH CHECK (is_admin(auth.uid()));

CREATE POLICY "Admins can view all spins"
ON roulette_spins
FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

CREATE POLICY "Users can read own tickets"
ON tickets
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR
  is_admin(auth.uid())
);

CREATE POLICY "Admins can update tickets"
ON tickets
FOR UPDATE
TO authenticated
USING (is_admin(auth.uid()))
WITH CHECK (is_admin(auth.uid()));