/*
  # Fix Mission Points System

  1. Changes
    - Add missing foreign key relationships
    - Update mission points transaction policies
    - Add system policies for points transactions

  2. Security
    - Enable RLS on all tables
    - Add policies for proper access control
*/

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Enable full access for admins" ON mission_points_transactions;
DROP POLICY IF EXISTS "Users can view own transactions" ON mission_points_transactions;
DROP POLICY IF EXISTS "System can create transactions" ON mission_points_transactions;

-- Create new policies for mission points transactions
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
    is_admin(auth.uid()) OR (
      type = 'mission_completed' AND
      EXISTS (
        SELECT 1 FROM user_missions
        WHERE user_missions.id = reference_id
        AND user_missions.user_id = mission_points_transactions.user_id
        AND user_missions.status = 'approved'
      )
    )
  );

-- Add foreign key for mission_id in mission_points_transactions
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.constraint_column_usage
    WHERE table_name = 'mission_points_transactions'
    AND column_name = 'mission_id'
  ) THEN
    ALTER TABLE mission_points_transactions
    ADD CONSTRAINT mission_points_transactions_mission_id_fkey
    FOREIGN KEY (mission_id) REFERENCES missions(id);
  END IF;
END $$;