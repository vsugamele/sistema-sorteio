/*
  # Add deposit points trigger

  1. New Function
    - `update_deposit_points`: Updates points when a deposit is approved
    - Calculates points based on deposit amount
    - Automatically triggered when deposit status changes to 'approved'

  2. Changes
    - Adds trigger to handle points calculation for approved deposits
    - Points are calculated based on deposit amount:
      - R$ 30 = 1 point
      - R$ 50 = 3 points
      - R$ 100 = 5 points
      - R$ 300 = 20 points
*/

-- Function to update deposit points
CREATE OR REPLACE FUNCTION update_deposit_points()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update points when status changes to approved
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    -- Calculate points based on amount
    NEW.points := CASE
      WHEN NEW.amount >= 300 THEN 20
      WHEN NEW.amount >= 100 THEN 5
      WHEN NEW.amount >= 50 THEN 3
      WHEN NEW.amount >= 30 THEN 1
      ELSE 0
    END;
  END IF;

  -- Reset points if not approved
  IF NEW.status != 'approved' THEN
    NEW.points := 0;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS deposit_points_trigger ON deposits;
CREATE TRIGGER deposit_points_trigger
  BEFORE UPDATE OF status ON deposits
  FOR EACH ROW
  EXECUTE FUNCTION update_deposit_points();