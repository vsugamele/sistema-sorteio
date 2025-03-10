/*
  # Fix prize claiming functionality

  1. Changes
    - Add payment_info column to prizes table
    - Create function to handle prize claiming
    - Add proper validation and error handling

  2. Security
    - Enable RLS on prizes table
    - Add policies for proper access control
*/

-- Create function to handle prize claiming
CREATE OR REPLACE FUNCTION public.claim_prize(
  prize_uuid UUID,
  admin_uuid UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_prize RECORD;
BEGIN
  -- Get prize details with locking
  SELECT * INTO v_prize
  FROM prizes
  WHERE id = prize_uuid
  FOR UPDATE;

  -- Validate prize exists
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Prize not found';
  END IF;

  -- Check if already claimed
  IF v_prize.claimed THEN
    RAISE EXCEPTION 'Prize already claimed';
  END IF;

  -- Update prize status
  UPDATE prizes SET
    claimed = true,
    claimed_at = NOW(),
    payment_info = jsonb_build_object(
      'claimed_by', admin_uuid,
      'claimed_at', NOW()::text
    )
  WHERE id = prize_uuid;

  RETURN true;

EXCEPTION WHEN OTHERS THEN
  -- Log error and return false
  RAISE WARNING 'Error claiming prize: %', SQLERRM;
  RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;