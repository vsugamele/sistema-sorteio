/*
  # Fix Prize Claiming System

  1. Changes
    - Add indexes for better performance
    - Add trigger for prize claiming
    - Add audit fields for tracking
    - Create function to handle prize claiming with proper validation

  2. Security
    - Add RLS policies
    - Add validation checks
*/

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_prizes_user_id ON prizes(user_id);
CREATE INDEX IF NOT EXISTS idx_prizes_claimed ON prizes(claimed) WHERE claimed = false;
CREATE INDEX IF NOT EXISTS idx_prizes_created_at ON prizes(created_at);

-- Add audit fields
ALTER TABLE prizes 
ADD COLUMN IF NOT EXISTS claimed_by uuid REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS claim_transaction_id uuid;

-- Create function to handle prize claiming
CREATE OR REPLACE FUNCTION claim_prize(
  prize_uuid UUID,
  admin_uuid UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_prize RECORD;
  v_transaction_id UUID;
BEGIN
  -- Lock the prize row for update
  SELECT * INTO v_prize
  FROM prizes
  WHERE id = prize_uuid
  FOR UPDATE SKIP LOCKED;

  -- Validate prize exists
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Prize not found or is being processed';
  END IF;

  -- Check if already claimed
  IF v_prize.claimed THEN
    RAISE EXCEPTION 'Prize already claimed';
  END IF;

  -- Generate transaction ID
  v_transaction_id := gen_random_uuid();

  -- Update prize status
  UPDATE prizes SET
    claimed = true,
    claimed_at = NOW(),
    claimed_by = admin_uuid,
    claim_transaction_id = v_transaction_id,
    updated_at = NOW()
  WHERE id = prize_uuid;

  -- Return success
  RETURN true;

EXCEPTION WHEN OTHERS THEN
  -- Log error and return false
  RAISE WARNING 'Error claiming prize: %', SQLERRM;
  RETURN false;
END;
$$;

-- Create trigger to prevent direct updates to claimed prizes
CREATE OR REPLACE FUNCTION prevent_claimed_prize_updates()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF OLD.claimed AND TG_OP = 'UPDATE' THEN
    RAISE EXCEPTION 'Cannot update claimed prizes';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER prevent_claimed_prize_updates
  BEFORE UPDATE ON prizes
  FOR EACH ROW
  EXECUTE FUNCTION prevent_claimed_prize_updates();

-- Add RLS policies
ALTER TABLE prizes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own prizes"
  ON prizes
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR auth.uid() IN (
    SELECT id FROM users WHERE is_admin = true
  ));

CREATE POLICY "Admins can claim prizes"
  ON prizes
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IN (
    SELECT id FROM users WHERE is_admin = true
  ))
  WITH CHECK (auth.uid() IN (
    SELECT id FROM users WHERE is_admin = true
  ));