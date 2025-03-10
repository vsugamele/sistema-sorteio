/*
  # Fix Prize Claiming System

  1. Changes
    - Add function to handle prize claiming with proper validation
    - Add trigger to prevent modifications to claimed prizes
    - Add audit fields for tracking

  2. Security
    - Add RLS policies for prize management
*/

-- Add audit fields if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'prizes' AND column_name = 'claimed_by') THEN
    ALTER TABLE prizes ADD COLUMN claimed_by uuid REFERENCES auth.users(id);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'prizes' AND column_name = 'claim_transaction_id') THEN
    ALTER TABLE prizes ADD COLUMN claim_transaction_id uuid;
  END IF;
END $$;

-- Create function to handle prize claiming
CREATE OR REPLACE FUNCTION claim_prize(
  prize_uuid UUID,
  admin_uuid UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_prize RECORD;
BEGIN
  -- Lock the prize row for update
  SELECT * INTO v_prize
  FROM prizes
  WHERE id = prize_uuid
  FOR UPDATE SKIP LOCKED;

  -- Validate prize exists and is not claimed
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Prize not found or is being processed';
  END IF;

  IF v_prize.claimed THEN
    RAISE EXCEPTION 'Prize already claimed';
  END IF;

  -- Update prize status
  UPDATE prizes SET
    claimed = true,
    claimed_at = NOW(),
    claimed_by = admin_uuid,
    claim_transaction_id = gen_random_uuid()
  WHERE id = prize_uuid;

  RETURN true;
END;
$$;

-- Create trigger to prevent updates to claimed prizes
CREATE OR REPLACE FUNCTION prevent_claimed_prize_updates()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF OLD.claimed AND OLD.claimed_at IS NOT NULL AND TG_OP = 'UPDATE' THEN
    RAISE EXCEPTION 'Cannot update claimed prizes';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS prevent_claimed_prize_updates ON prizes;
CREATE TRIGGER prevent_claimed_prize_updates
  BEFORE UPDATE ON prizes
  FOR EACH ROW
  EXECUTE FUNCTION prevent_claimed_prize_updates();

-- Update RLS policies
ALTER TABLE prizes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own prizes" ON prizes;
CREATE POLICY "Users can view own prizes"
  ON prizes
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR auth.uid() IN (
    SELECT id FROM users WHERE is_admin = true
  ));

DROP POLICY IF EXISTS "Admins can update prizes" ON prizes;
CREATE POLICY "Admins can update prizes"
  ON prizes
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IN (
    SELECT id FROM users WHERE is_admin = true
  ))
  WITH CHECK (auth.uid() IN (
    SELECT id FROM users WHERE is_admin = true
  ));