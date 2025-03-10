/*
  # Add Points Calculation Functions
  
  1. New Functions
    - get_available_points: Calculates total available points for a user
    - get_pending_points: Calculates pending points for a user
  
  2. Changes
    - Functions return integer instead of bigint for compatibility
*/

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points(user_uuid UUID)
RETURNS integer AS $$
DECLARE
  total_points integer;
BEGIN
  -- Get points from approved deposits
  SELECT COALESCE(SUM(points)::integer, 0)
  INTO total_points
  FROM deposits
  WHERE user_id = user_uuid AND status = 'approved';

  -- Add points from approved missions
  SELECT total_points + COALESCE(SUM(m.points_reward)::integer, 0)
  INTO total_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid AND um.status = 'approved';

  -- Subtract points spent on roulette
  SELECT total_points - COALESCE(SUM(points_spent)::integer, 0)
  INTO total_points
  FROM roulette_spins
  WHERE user_id = user_uuid;

  RETURN total_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get pending points
CREATE OR REPLACE FUNCTION get_pending_points(user_uuid UUID)
RETURNS integer AS $$
DECLARE
  pending_points integer;
BEGIN
  -- Get points from pending deposits
  SELECT COALESCE(FLOOR(SUM(amount))::integer, 0)
  INTO pending_points
  FROM deposits
  WHERE user_id = user_uuid AND status = 'pending';

  -- Add points from submitted missions
  SELECT pending_points + COALESCE(SUM(m.points_reward)::integer, 0)
  INTO pending_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid AND um.status = 'submitted';

  RETURN pending_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;