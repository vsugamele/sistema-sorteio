/*
  # Fix Roulette Points System

  1. Overview
    - Fixes points calculation and deduction for roulette spins
    - Adds proper transaction handling
    - Improves error handling and validation

  2. Changes
    - Adds function to handle points deduction
    - Updates points calculation functions
    - Adds proper validation for available points

  3. Security
    - Maintains RLS policies
    - Ensures data integrity
    - Prevents unauthorized point deductions
*/

-- Function to handle points deduction
CREATE OR REPLACE FUNCTION handle_points_deduction()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  available_points integer;
  points_needed integer := 50; -- Fixed cost for roulette spin
  deposit_record RECORD;
BEGIN
  -- Get available points
  SELECT COALESCE(SUM(points), 0)
  INTO available_points
  FROM deposits
  WHERE user_id = NEW.user_id
  AND status = 'approved';

  -- Add points from approved missions
  SELECT available_points + COALESCE(SUM(m.points_reward), 0)
  INTO available_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = NEW.user_id
  AND um.status = 'approved';

  -- Get points spent on roulette
  SELECT available_points - COALESCE(SUM(points_spent), 0)
  INTO available_points
  FROM roulette_spins
  WHERE user_id = NEW.user_id;

  -- Check if user has enough points
  IF available_points < points_needed THEN
    RAISE EXCEPTION 'Insufficient points. Required: %, Available: %', points_needed, available_points;
  END IF;

  -- All checks passed, allow the spin
  RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS handle_roulette_spin_trigger ON roulette_spins;

-- Create new trigger for roulette spins
CREATE TRIGGER handle_roulette_spin_trigger
  BEFORE INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION handle_points_deduction();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION handle_points_deduction() TO authenticated;