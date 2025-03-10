/*
  # Fix admin user update

  1. Changes
    - Create function to update user admin status
    - Update existing policies to use auth.users directly
    - Maintain existing functionality while fixing the update issue
*/

-- Create function to update user admin status
CREATE OR REPLACE FUNCTION update_user_admin_status(user_id uuid, is_admin boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE auth.users
  SET is_admin = update_user_admin_status.is_admin
  WHERE id = user_id;
END;
$$;

-- Update existing policies to use auth.users directly
DROP POLICY IF EXISTS "Users access policy" ON auth.users;
CREATE POLICY "Users access policy"
ON auth.users
FOR SELECT
TO authenticated
USING (
  id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM auth.users AS admin
    WHERE admin.id = auth.uid()
    AND admin.is_admin = true
  )
);

DROP POLICY IF EXISTS "Deposits access policy" ON deposits;
CREATE POLICY "Deposits access policy"
ON deposits
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM auth.users AS admin
    WHERE admin.id = auth.uid()
    AND admin.is_admin = true
  )
);

DROP POLICY IF EXISTS "Admins can update deposit status" ON deposits;
CREATE POLICY "Admins can update deposit status"
ON deposits
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM auth.users AS admin
    WHERE admin.id = auth.uid()
    AND admin.is_admin = true
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM auth.users AS admin
    WHERE admin.id = auth.uid()
    AND admin.is_admin = true
  )
);

DROP POLICY IF EXISTS "Admins can manage prizes" ON roulette_prizes;
CREATE POLICY "Admins can manage prizes"
ON roulette_prizes
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM auth.users AS admin
    WHERE admin.id = auth.uid()
    AND admin.is_admin = true
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM auth.users AS admin
    WHERE admin.id = auth.uid()
    AND admin.is_admin = true
  )
);

DROP POLICY IF EXISTS "Admins can view all spins" ON roulette_spins;
CREATE POLICY "Admins can view all spins"
ON roulette_spins
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM auth.users AS admin
    WHERE admin.id = auth.uid()
    AND admin.is_admin = true
  )
);

DROP POLICY IF EXISTS "Users can read own tickets" ON tickets;
CREATE POLICY "Users can read own tickets"
ON tickets
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM auth.users AS admin
    WHERE admin.id = auth.uid()
    AND admin.is_admin = true
  )
);

DROP POLICY IF EXISTS "Admins can update tickets" ON tickets;
CREATE POLICY "Admins can update tickets"
ON tickets
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM auth.users AS admin
    WHERE admin.id = auth.uid()
    AND admin.is_admin = true
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM auth.users AS admin
    WHERE admin.id = auth.uid()
    AND admin.is_admin = true
  )
);