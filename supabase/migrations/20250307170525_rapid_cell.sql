/*
  # Update Points System Functions v2
  
  1. Changes
    - Fix points calculation for deposits and missions
    - Add proper error handling
    - Optimize queries for better performance
    - Add function to handle points deduction
*/

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points(user_uuid UUID)
RETURNS integer AS $$
DECLARE
  total_points integer;
  spent_points integer;
BEGIN
  -- Get points from approved deposits
  SELECT COALESCE(SUM(points), 0)::integer
  INTO total_points
  FROM deposits
  WHERE user_id = user_uuid AND status = 'approved';

  -- Add points from approved missions
  SELECT total_points + COALESCE(SUM(m.points_reward), 0)::integer
  INTO total_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid AND um.status = 'approved';

  -- Get points spent on roulette
  SELECT COALESCE(SUM(points_spent), 0)::integer
  INTO spent_points
  FROM roulette_spins
  WHERE user_id = user_uuid;

  -- Return available points (never negative)
  RETURN GREATEST(total_points - spent_points, 0);
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error in get_available_points: %', SQLERRM;
    RETURN 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get pending points
CREATE OR REPLACE FUNCTION get_pending_points(user_uuid UUID)
RETURNS integer AS $$
DECLARE
  pending_points integer;
BEGIN
  -- Get points from pending deposits
  SELECT COALESCE(FLOOR(SUM(amount)), 0)::integer
  INTO pending_points
  FROM deposits
  WHERE user_id = user_uuid AND status = 'pending';

  -- Add points from submitted missions
  SELECT pending_points + COALESCE(SUM(m.points_reward), 0)::integer
  INTO pending_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid AND um.status = 'submitted';

  RETURN GREATEST(pending_points, 0);
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error in get_pending_points: %', SQLERRM;
    RETURN 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle points deduction
CREATE OR REPLACE FUNCTION handle_points_deduction()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if user has enough points
  IF (SELECT get_available_points(NEW.user_id)) < NEW.points_spent THEN
    RAISE EXCEPTION 'Insufficient points available';
  END IF;

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for points deduction
DROP TRIGGER IF EXISTS check_points_availability ON roulette_spins;
CREATE TRIGGER check_points_availability
  BEFORE INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION handle_points_deduction();