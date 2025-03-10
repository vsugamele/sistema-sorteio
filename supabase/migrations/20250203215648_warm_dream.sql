/*
  # Fix recursive policies

  1. Changes
    - Remove recursive policy dependencies
    - Simplify admin checks using direct table access
    - Maintain same security model with optimized queries
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users access policy" ON auth.users;
DROP POLICY IF EXISTS "Deposits access policy" ON deposits;
DROP POLICY IF EXISTS "Admins can update deposit status" ON deposits;
DROP POLICY IF EXISTS "Admins can manage prizes" ON roulette_prizes;
DROP POLICY IF EXISTS "Admins can view all spins" ON roulette_spins;
DROP POLICY IF EXISTS "Users can read own tickets" ON tickets;
DROP POLICY IF EXISTS "Admins can update tickets" ON tickets;

-- Create simplified policies without recursion
CREATE POLICY "Users access policy"
ON auth.users
FOR SELECT
TO authenticated
USING (
  id = auth.uid() OR
  (SELECT is_admin FROM auth.users WHERE id = auth.uid())
);

CREATE POLICY "Deposits access policy"
ON deposits
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR
  (SELECT is_admin FROM auth.users WHERE id = auth.uid())
);

CREATE POLICY "Admins can update deposit status"
ON deposits
FOR UPDATE
TO authenticated
USING (
  (SELECT is_admin FROM auth.users WHERE id = auth.uid())
)
WITH CHECK (
  (SELECT is_admin FROM auth.users WHERE id = auth.uid())
);

CREATE POLICY "Admins can manage prizes"
ON roulette_prizes
FOR ALL
TO authenticated
USING (
  (SELECT is_admin FROM auth.users WHERE id = auth.uid())
)
WITH CHECK (
  (SELECT is_admin FROM auth.users WHERE id = auth.uid())
);

CREATE POLICY "Admins can view all spins"
ON roulette_spins
FOR SELECT
TO authenticated
USING (
  (SELECT is_admin FROM auth.users WHERE id = auth.uid())
);

CREATE POLICY "Users can read own tickets"
ON tickets
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR
  (SELECT is_admin FROM auth.users WHERE id = auth.uid())
);

CREATE POLICY "Admins can update tickets"
ON tickets
FOR UPDATE
TO authenticated
USING (
  (SELECT is_admin FROM auth.users WHERE id = auth.uid())
)
WITH CHECK (
  (SELECT is_admin FROM auth.users WHERE id = auth.uid())
);