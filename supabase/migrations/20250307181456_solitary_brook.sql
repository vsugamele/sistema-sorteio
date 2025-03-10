/*
  # Fix Points Calculation System

  1. Overview
    - Adds improved points calculation functions
    - Fixes points validation and deduction
    - Adds proper error handling

  2. Changes
    - Creates get_available_points_v2 function
    - Creates get_pending_points_v2 function
    - Updates points deduction handling

  3. Security
    - Maintains RLS policies
    - Ensures data integrity
*/

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points_v2(user_uuid UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  total_points INTEGER;
  points_spent INTEGER;
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

  -- Subtract points spent on roulette
  SELECT COALESCE(SUM(points_spent), 0)
  INTO points_spent
  FROM roulette_spins
  WHERE user_id = user_uuid;

  RETURN total_points - points_spent;
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

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_available_points_v2(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_pending_points_v2(UUID) TO authenticated;

-- Update roulette spin trigger
CREATE OR REPLACE FUNCTION handle_points_deduction()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  available_points INTEGER;
BEGIN
  -- Get available points using the new function
  SELECT get_available_points_v2(NEW.user_id) INTO available_points;

  -- Check if user has enough points
  IF available_points < NEW.points_spent THEN
    RAISE EXCEPTION 'Insufficient points available. Required: %, Available: %', 
      NEW.points_spent, available_points;
  END IF;

  RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS handle_roulette_spin_trigger ON roulette_spins;

-- Create new trigger
CREATE TRIGGER handle_roulette_spin_trigger
  BEFORE INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION handle_points_deduction();

-- Grant execute permission
GRANT EXECUTE ON FUNCTION handle_points_deduction() TO authenticated;