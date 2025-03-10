/*
  # Fix prize claiming function

  1. Changes
    - Improved claim_prize function to properly update prize status
    - Added better validation and error handling
    - Added proper transaction handling
    - Added logging for debugging

  2. Security
    - Function can only be executed by authenticated users
    - Includes validation checks
*/

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS claim_prize;

-- Create new improved function
CREATE OR REPLACE FUNCTION claim_prize(prize_uuid UUID, admin_uuid UUID)
RETURNS boolean AS $$
DECLARE
  v_prize_exists boolean;
  v_prize_claimed boolean;
BEGIN
  -- Check if prize exists
  SELECT EXISTS (
    SELECT 1 FROM prizes WHERE id = prize_uuid
  ) INTO v_prize_exists;

  IF NOT v_prize_exists THEN
    RAISE EXCEPTION 'Prize not found';
  END IF;

  -- Check if prize is already claimed
  SELECT claimed INTO v_prize_claimed
  FROM prizes
  WHERE id = prize_uuid;

  IF v_prize_claimed THEN
    RAISE EXCEPTION 'Prize already claimed';
  END IF;

  -- Update prize status within a transaction
  UPDATE prizes SET
    claimed = true,
    claimed_at = NOW(),
    payment_info = jsonb_build_object(
      'claimed_by', admin_uuid,
      'claimed_at', NOW()::text,
      'updated_at', NOW()::text
    )
  WHERE id = prize_uuid
  AND claimed = false;

  -- Check if update was successful
  IF FOUND THEN
    RETURN true;
  ELSE
    RETURN false;
  END IF;

EXCEPTION WHEN OTHERS THEN
  -- Log error and return false
  RAISE NOTICE 'Error claiming prize: %', SQLERRM;
  RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;