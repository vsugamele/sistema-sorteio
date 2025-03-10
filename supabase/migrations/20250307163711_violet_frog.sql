/*
  # Add Points Calculation Functions
  
  1. New Functions
    - get_available_points: Calculates total available points for a user
    - get_pending_points: Calculates total pending points for a user
  
  2. Changes
    - Improves points calculation consistency across the application
    - Considers both deposits and missions points
*/

-- Function to get available (approved) points
CREATE OR REPLACE FUNCTION get_available_points(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  deposit_points INTEGER;
  mission_points INTEGER;
BEGIN
  -- Get approved deposit points
  SELECT COALESCE(SUM(points), 0)
  INTO deposit_points
  FROM deposits
  WHERE user_id = user_uuid AND status = 'approved';

  -- Get approved mission points
  SELECT COALESCE(SUM(m.points_reward), 0)
  INTO mission_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid AND um.status = 'approved';

  -- Return total available points
  RETURN deposit_points + mission_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get pending points
CREATE OR REPLACE FUNCTION get_pending_points(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  pending_deposit_points INTEGER;
  pending_mission_points INTEGER;
BEGIN
  -- Get pending deposit points
  SELECT COALESCE(SUM(FLOOR(amount)), 0)
  INTO pending_deposit_points
  FROM deposits
  WHERE user_id = user_uuid AND status = 'pending';

  -- Get pending mission points
  SELECT COALESCE(SUM(m.points_reward), 0)
  INTO pending_mission_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid AND um.status = 'submitted';

  -- Return total pending points
  RETURN pending_deposit_points + pending_mission_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;