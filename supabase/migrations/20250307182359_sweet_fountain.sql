/*
  # Points Calculation System V2

  1. Overview
    - Implements points calculation functions for user balances
    - Handles points deduction for roulette spins
    - Ensures data consistency and proper security

  2. Functions
    - get_available_points_v2: Calculates total available points
    - get_pending_points_v2: Calculates pending points
    - handle_points_deduction: Manages points deduction for roulette spins

  3. Security
    - All functions are SECURITY DEFINER
    - Proper permissions granted to authenticated users
    - Safe error handling
*/

-- First drop the trigger that depends on the function
DROP TRIGGER IF EXISTS handle_roulette_spin_trigger ON roulette_spins CASCADE;

-- Now we can safely drop the functions
DROP FUNCTION IF EXISTS handle_points_deduction() CASCADE;
DROP FUNCTION IF EXISTS get_available_points_v2(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_pending_points_v2(UUID) CASCADE;

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points_v2(user_uuid UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  total_points INTEGER;
  spent_points INTEGER;
BEGIN
  -- Get points from approved deposits
  SELECT COALESCE(SUM(d.points), 0)
  INTO total_points
  FROM deposits d
  WHERE d.user_id = user_uuid
  AND d.status = 'approved';

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

  RETURN GREATEST(total_points - spent_points, 0);
END;
$$;

-- Function to get pending points
CREATE OR REPLACE FUNCTION get_pending_points_v2(user_uuid UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  pending_points INTEGER := 0;
BEGIN
  -- Get points from pending deposits
  SELECT COALESCE(SUM(FLOOR(d.amount)), 0)
  INTO pending_points
  FROM deposits d
  WHERE d.user_id = user_uuid
  AND d.status = 'pending';

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

-- Update roulette spin trigger
CREATE OR REPLACE FUNCTION handle_points_deduction()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  available_points INTEGER;
BEGIN
  -- Get available points
  SELECT get_available_points_v2(NEW.user_id) INTO available_points;

  -- Check if user has enough points
  IF available_points < NEW.points_spent THEN
    RAISE EXCEPTION 'Insufficient points available. Required: %, Available: %', 
      NEW.points_spent, available_points;
  END IF;

  RETURN NEW;
END;
$$;

-- Create new trigger
CREATE TRIGGER handle_roulette_spin_trigger
  BEFORE INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION handle_points_deduction();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_available_points_v2(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_pending_points_v2(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION handle_points_deduction() TO authenticated;