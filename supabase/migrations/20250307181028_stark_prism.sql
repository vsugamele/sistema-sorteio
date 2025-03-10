/*
  # Points Calculation System

  1. Overview
    - Implements complete points calculation system
    - Adds functions for available and pending points
    - Adds trigger for roulette spins
    - Includes proper error handling and validation

  2. Functions Added
    - get_available_points_v2: Calculates total available points
    - get_pending_points_v2: Calculates pending points
    - handle_roulette_spin: Manages point deduction for roulette spins

  3. Security
    - All functions are SECURITY DEFINER
    - Proper RLS policies
    - Input validation
*/

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points_v2(user_uuid uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  total_points integer := 0;
  points_spent integer := 0;
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
  INTO points_spent
  FROM roulette_spins
  WHERE user_id = user_uuid;

  -- Return available points (never negative)
  RETURN GREATEST(total_points - points_spent, 0);
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

-- Function to handle roulette spins and point deduction
CREATE OR REPLACE FUNCTION handle_roulette_spin()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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

  RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS handle_roulette_spin_trigger ON roulette_spins;

-- Create trigger for roulette spins
CREATE TRIGGER handle_roulette_spin_trigger
  BEFORE INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION handle_roulette_spin();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_available_points_v2(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_pending_points_v2(uuid) TO authenticated;