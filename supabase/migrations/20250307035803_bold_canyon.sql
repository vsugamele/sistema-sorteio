/*
  # Fix Points RLS Policies

  1. Changes
    - Add RLS policies for mission points transactions
    - Allow admins to create transactions
    - Allow system to create transactions for mission completion

  2. Security
    - Enable RLS on mission_points_transactions table
    - Add policies for transaction creation
*/

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own transactions" ON mission_points_transactions;

-- Create new policies
CREATE POLICY "Enable full access for admins"
  ON mission_points_transactions
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

CREATE POLICY "Users can view own transactions"
  ON mission_points_transactions
  FOR SELECT
  TO authenticated
  USING ((user_id = auth.uid()) OR is_admin(auth.uid()));

CREATE POLICY "System can create transactions"
  ON mission_points_transactions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Allow admins to create transactions
    is_admin(auth.uid())
    OR
    -- Allow transactions for mission completion
    (
      type = 'mission_completed'
      AND EXISTS (
        SELECT 1 FROM user_missions
        WHERE user_missions.id = reference_id
        AND user_missions.user_id = mission_points_transactions.user_id
        AND user_missions.status = 'approved'
      )
    )
  );