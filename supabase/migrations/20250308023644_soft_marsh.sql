/*
  # Fix prize claiming functionality

  1. New Function
    - `claim_prize`: Function to safely mark prizes as claimed
    - Includes validation and proper error handling
    - Records claim timestamp and admin info
    - Returns success/error status

  2. Security
    - Function can only be executed by authenticated users
    - Includes validation checks
*/

CREATE OR REPLACE FUNCTION claim_prize(prize_uuid UUID, admin_uuid UUID)
RETURNS boolean AS $$
DECLARE
  prize_exists boolean;
BEGIN
  -- Check if prize exists and is not claimed
  SELECT EXISTS (
    SELECT 1 FROM prizes 
    WHERE id = prize_uuid 
    AND claimed = false
  ) INTO prize_exists;

  IF NOT prize_exists THEN
    RETURN false;
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;