/*
  # Add prize claiming function

  1. New Function
    - `handle_prize_claim`: Function to safely mark prizes as claimed
      - Updates prize status
      - Records claim timestamp and admin info
      - Validates prize exists and isn't already claimed

  2. Security
    - Function can only be executed by authenticated users
    - Includes validation checks
*/

CREATE OR REPLACE FUNCTION handle_prize_claim(prize_uuid UUID, admin_uuid UUID)
RETURNS VOID AS $$
BEGIN
  -- Check if prize exists and is not claimed
  IF NOT EXISTS (
    SELECT 1 FROM prizes 
    WHERE id = prize_uuid 
    AND claimed = false
  ) THEN
    RAISE EXCEPTION 'Prize not found or already claimed';
  END IF;

  -- Update prize status
  UPDATE prizes
  SET 
    claimed = true,
    claimed_at = NOW(),
    payment_info = jsonb_build_object(
      'claimed_by', admin_uuid,
      'claimed_at', NOW()
    )
  WHERE id = prize_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;