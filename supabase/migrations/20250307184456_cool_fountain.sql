/*
  # Points Management Functions V2

  1. New Functions
    - get_available_points_v2: Returns total available points for a user
    - get_pending_points_v2: Returns total pending points for a user
    - handle_points_deduction: Handles point deduction for roulette spins

  2. Changes
    - Drops existing trigger before function
    - Recreates functions with improved logic
    - Maintains security and data integrity

  3. Security
    - Functions are accessible only to authenticated users
    - Points calculations consider only approved transactions
*/

-- First drop the trigger that depends on the function
DROP TRIGGER IF EXISTS handle_roulette_spin_trigger ON roulette_spins;

-- Now we can safely drop the functions
DROP FUNCTION IF EXISTS get_available_points_v2(UUID);
DROP FUNCTION IF EXISTS get_pending_points_v2(UUID);
DROP FUNCTION IF EXISTS handle_points_deduction();

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points_v2(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  total_points INTEGER;
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
  SELECT total_points - COALESCE(SUM(points_spent), 0)
  INTO total_points
  FROM roulette_spins
  WHERE user_id = user_uuid;

  RETURN GREATEST(total_points, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get pending points
CREATE OR REPLACE FUNCTION get_pending_points_v2(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  pending_points INTEGER;
BEGIN
  -- Get points from pending deposits
  SELECT COALESCE(SUM(FLOOR(amount)), 0)
  INTO pending_points
  FROM deposits
  WHERE user_id = user_uuid
    AND status = 'pending';

  -- Add points from submitted missions
  SELECT pending_points + COALESCE(SUM(m.points_reward), 0)
  INTO pending_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid
    AND um.status = 'submitted';

  RETURN pending_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle points deduction for roulette spins
CREATE OR REPLACE FUNCTION handle_points_deduction()
RETURNS TRIGGER AS $$
DECLARE
  available_points INTEGER;
BEGIN
  -- Get available points
  SELECT get_available_points_v2(NEW.user_id) INTO available_points;

  -- Check if user has enough points
  IF available_points < NEW.points_spent THEN
    RAISE EXCEPTION 'Insufficient points available';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER handle_roulette_spin_trigger
  BEFORE INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION handle_points_deduction();