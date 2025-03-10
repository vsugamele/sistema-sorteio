/*
  # Fix Points Schema and Transactions

  1. Changes
    - Add point transaction type enum
    - Add mission points transactions table
    - Add mission points balance table
    - Add triggers and functions for points management

  2. Security
    - Enable RLS on new tables
    - Add policies for user access
    - Add validation triggers
*/

-- Create point transaction type enum if it doesn't exist
DO $$ BEGIN
  CREATE TYPE point_transaction_type AS ENUM (
    'mission_completed',
    'mission_revoked',
    'points_expired',
    'points_adjusted'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create mission points transactions table
CREATE TABLE IF NOT EXISTS mission_points_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  mission_id uuid REFERENCES missions(id),
  amount integer NOT NULL,
  type point_transaction_type NOT NULL,
  reference_id uuid,
  metadata jsonb,
  description text,
  created_at timestamptz DEFAULT now(),
  created_by uuid NOT NULL REFERENCES auth.users(id)
);

-- Create mission points balance table
CREATE TABLE IF NOT EXISTS mission_points_balance (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id),
  total_points integer NOT NULL DEFAULT 0 CHECK (total_points >= 0),
  pending_points integer NOT NULL DEFAULT 0 CHECK (pending_points >= 0),
  last_updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE mission_points_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE mission_points_balance ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_mission_points_transactions_user ON mission_points_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_mission_points_transactions_mission ON mission_points_transactions(mission_id);
CREATE INDEX IF NOT EXISTS idx_mission_points_transactions_type ON mission_points_transactions(type);
CREATE INDEX IF NOT EXISTS idx_mission_points_transactions_created_at ON mission_points_transactions(created_at);

-- Create function to validate mission points transaction
CREATE OR REPLACE FUNCTION validate_mission_points_transaction()
RETURNS TRIGGER AS $$
BEGIN
  -- Ensure amount is positive for additions and negative for deductions
  IF NEW.type IN ('mission_completed', 'points_adjusted') AND NEW.amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be positive for mission completion and adjustments';
  END IF;
  
  IF NEW.type IN ('mission_revoked', 'points_expired') AND NEW.amount >= 0 THEN
    RAISE EXCEPTION 'Amount must be negative for revocations and expirations';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for validation
DROP TRIGGER IF EXISTS validate_mission_points_transaction_trigger ON mission_points_transactions;
CREATE TRIGGER validate_mission_points_transaction_trigger
  BEFORE INSERT ON mission_points_transactions
  FOR EACH ROW
  EXECUTE FUNCTION validate_mission_points_transaction();

-- Create function to update points balance
CREATE OR REPLACE FUNCTION update_mission_points_balance()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert or update points balance
  INSERT INTO mission_points_balance (user_id, total_points, last_updated_at)
  VALUES (NEW.user_id, NEW.amount, now())
  ON CONFLICT (user_id) DO UPDATE
  SET 
    total_points = CASE 
      WHEN NEW.type IN ('mission_completed', 'points_adjusted') THEN 
        mission_points_balance.total_points + NEW.amount
      ELSE 
        mission_points_balance.total_points - ABS(NEW.amount)
    END,
    last_updated_at = now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for points balance update
DROP TRIGGER IF EXISTS update_mission_points_balance_trigger ON mission_points_transactions;
CREATE TRIGGER update_mission_points_balance_trigger
  AFTER INSERT ON mission_points_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_mission_points_balance();

-- Create policies (only if they don't exist)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'mission_points_transactions' 
    AND policyname = 'Users can view own transactions'
  ) THEN
    CREATE POLICY "Users can view own transactions" ON mission_points_transactions
      FOR SELECT
      TO authenticated
      USING ((user_id = auth.uid()) OR is_admin(auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'mission_points_balance' 
    AND policyname = 'Users can view own balance'
  ) THEN
    CREATE POLICY "Users can view own balance" ON mission_points_balance
      FOR SELECT
      TO authenticated
      USING ((user_id = auth.uid()) OR is_admin(auth.uid()));
  END IF;
END $$;