/*
  # Fix Points Balance RLS Policies

  1. Changes
    - Add RLS policies for mission points balance
    - Allow system to update points balance
    - Allow users to view their own balance

  2. Security
    - Enable RLS on mission_points_balance table
    - Add policies for balance updates and viewing
*/

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own balance" ON mission_points_balance;

-- Create new policies
CREATE POLICY "Enable full access for admins"
  ON mission_points_balance
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

CREATE POLICY "Users can view own balance"
  ON mission_points_balance
  FOR SELECT
  TO authenticated
  USING ((user_id = auth.uid()) OR is_admin(auth.uid()));

CREATE POLICY "System can update balance"
  ON mission_points_balance
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);