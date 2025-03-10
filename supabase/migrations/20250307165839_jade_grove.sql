/*
  # Update Points Calculation Functions
  
  1. Changes
    - Ensure points never go below zero
    - Add GREATEST function to prevent negative values
    - Improve points calculation logic
*/

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points(user_uuid UUID)
RETURNS integer AS $$
DECLARE
  total_points integer;
  spent_points integer;
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

  -- Calculate points spent on roulette
  SELECT COALESCE(SUM(points_spent)::integer, 0)
  INTO spent_points
  FROM roulette_spins
  WHERE user_id = user_uuid;

  -- Ensure result is never negative
  RETURN GREATEST(total_points - spent_points, 0);
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

  -- Ensure result is never negative
  RETURN GREATEST(pending_points, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;