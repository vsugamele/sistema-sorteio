/*
  # Update deposit points calculation

  1. Changes
    - Updates points calculation logic for deposits
    - Points are now awarded 1:1 with deposit amount
    - Example: R$ 30 deposit = 30 points
    - Points are automatically calculated when deposit is approved
    - Points are reset when deposit is rejected

  2. Security
    - Function runs with security definer to ensure proper access control
*/

-- Function to calculate points based on deposit amount (1:1 ratio)
CREATE OR REPLACE FUNCTION calculate_deposit_points(amount numeric)
RETURNS integer AS $$
BEGIN
  -- Convert amount to integer points (1:1 ratio)
  RETURN floor(amount)::integer;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update deposit points
CREATE OR REPLACE FUNCTION update_deposit_points()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update points when status changes to approved
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    NEW.points := calculate_deposit_points(NEW.amount);
  END IF;

  -- Reset points if not approved
  IF NEW.status != 'approved' THEN
    NEW.points := 0;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS deposit_points_trigger ON deposits;

-- Create trigger for points calculation
CREATE TRIGGER deposit_points_trigger
  BEFORE UPDATE OF status ON deposits
  FOR EACH ROW
  EXECUTE FUNCTION update_deposit_points();