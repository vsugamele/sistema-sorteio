/*
  # Update Deposit Points Calculation

  1. Function Updates
    - Update the deposit points calculation function to match new point tiers:
      - R$ 30 = 1 point
      - R$ 50 = 3 points
      - R$ 100 = 5 points
      - R$ 300 = 20 points

  2. Security
    - Maintain existing RLS policies
*/

-- Update the function to calculate deposit points
CREATE OR REPLACE FUNCTION calculate_deposit_points(amount numeric)
RETURNS integer AS $$
BEGIN
  -- Calculate points based on deposit amount tiers
  IF amount >= 300 THEN
    RETURN 20;
  ELSIF amount >= 100 THEN
    RETURN 5;
  ELSIF amount >= 50 THEN
    RETURN 3;
  ELSIF amount >= 30 THEN
    RETURN 1;
  ELSE
    RETURN 0;
  END IF;
END;
$$ LANGUAGE plpgsql;