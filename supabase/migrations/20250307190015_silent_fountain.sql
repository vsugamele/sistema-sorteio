/*
  # Fix Points Calculation Functions v3

  1. Changes
    - Improved points calculation functions
    - Added better error handling
    - Fixed points deduction logic
    - Added transaction support for roulette spins

  2. Functions Modified
    - get_available_points_v2
    - get_pending_points_v2
    - handle_points_deduction
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS handle_roulette_spin_trigger ON roulette_spins;

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points_v2(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  total_points INTEGER := 0;
  deposit_points INTEGER := 0;
  mission_points INTEGER := 0;
  spent_points INTEGER := 0;
BEGIN
  -- Get points from approved deposits
  SELECT COALESCE(SUM(points), 0)
  INTO deposit_points
  FROM deposits
  WHERE user_id = user_uuid
    AND status = 'approved';

  -- Add points from approved missions
  SELECT COALESCE(SUM(m.points_reward), 0)
  INTO mission_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid
    AND um.status = 'approved';

  -- Get points spent on roulette
  SELECT COALESCE(SUM(points_spent), 0)
  INTO spent_points
  FROM roulette_spins
  WHERE user_id = user_uuid;

  -- Calculate total available points
  total_points := deposit_points + mission_points - spent_points;

  RETURN GREATEST(total_points, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get pending points
CREATE OR REPLACE FUNCTION get_pending_points_v2(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  pending_points INTEGER := 0;
  deposit_points INTEGER := 0;
  mission_points INTEGER := 0;
BEGIN
  -- Get points from pending deposits
  SELECT COALESCE(SUM(FLOOR(amount)), 0)
  INTO deposit_points
  FROM deposits
  WHERE user_id = user_uuid
    AND status = 'pending';

  -- Add points from submitted missions
  SELECT COALESCE(SUM(m.points_reward), 0)
  INTO mission_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid
    AND um.status = 'submitted';

  -- Calculate total pending points
  pending_points := deposit_points + mission_points;

  RETURN pending_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle points deduction
CREATE OR REPLACE FUNCTION handle_points_deduction()
RETURNS TRIGGER AS $$
DECLARE
  available_points INTEGER;
BEGIN
  -- Get available points
  SELECT get_available_points_v2(NEW.user_id) INTO available_points;

  -- Check if user has enough points
  IF available_points < NEW.points_spent THEN
    RAISE EXCEPTION 'Insufficient points available. Required: %, Available: %', NEW.points_spent, available_points;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER handle_roulette_spin_trigger
  BEFORE INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION handle_points_deduction();