/*
  # Fix Points Calculation and Roulette Functionality

  1. Overview
    - Fixes points calculation for roulette spins
    - Adds proper handling of points deduction
    - Improves error handling and validation

  2. Changes
    - Adds trigger to handle points deduction
    - Updates points calculation functions
    - Adds proper validation for available points

  3. Security
    - Maintains RLS policies
    - Ensures data integrity
    - Prevents unauthorized point deductions
*/

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS handle_roulette_spin CASCADE;
DROP FUNCTION IF EXISTS get_available_points_v2 CASCADE;
DROP FUNCTION IF EXISTS get_pending_points_v2 CASCADE;

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points_v2(user_uuid uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  total_points integer := 0;
  spent_points integer := 0;
BEGIN
  -- Get points from approved deposits
  SELECT COALESCE(SUM(points), 0)
  INTO total_points
  FROM deposits
  WHERE user_id = user_uuid
  AND status = 'approved';

  -- Add points from approved missions
  SELECT total_points + COALESCE(SUM(m.points_reward), 0)
  INTO total_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid
  AND um.status = 'approved';

  -- Get points spent on roulette
  SELECT COALESCE(SUM(points_spent), 0)
  INTO spent_points
  FROM roulette_spins
  WHERE user_id = user_uuid;

  -- Return available points (never negative)
  RETURN GREATEST(total_points - spent_points, 0);
END;
$$;

-- Function to get pending points
CREATE OR REPLACE FUNCTION get_pending_points_v2(user_uuid uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  pending_points integer := 0;
BEGIN
  -- Get points from pending deposits
  SELECT COALESCE(SUM(FLOOR(amount)), 0)
  INTO pending_points
  FROM deposits
  WHERE user_id = user_uuid
  AND status = 'pending';

  -- Add points from pending missions
  SELECT pending_points + COALESCE(SUM(m.points_reward), 0)
  INTO pending_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid
  AND um.status = 'submitted';

  RETURN pending_points;
END;
$$;

-- Function to handle roulette spin
CREATE OR REPLACE FUNCTION handle_roulette_spin()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  available_points integer;
BEGIN
  -- Get available points
  SELECT get_available_points_v2(NEW.user_id) INTO available_points;

  -- Check if user has enough points
  IF available_points < NEW.points_spent THEN
    RAISE EXCEPTION 'Insufficient points available. Required: %, Available: %', NEW.points_spent, available_points;
  END IF;

  -- All checks passed, allow the spin
  RETURN NEW;
END;
$$;

-- Create trigger for roulette spins
CREATE TRIGGER handle_roulette_spin_trigger
  BEFORE INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION handle_roulette_spin();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_available_points_v2(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_pending_points_v2(uuid) TO authenticated;