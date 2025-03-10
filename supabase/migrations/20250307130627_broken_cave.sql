/*
  # Add function to get pending points

  1. New Functions
    - `get_pending_points`: Returns the total pending points for a user
      - Includes points from pending deposits and submitted missions
      - Takes user_uuid as parameter
      - Returns integer

  2. Changes
    - Creates a new function to calculate pending points from:
      - Pending deposits (amount is converted to points)
      - Submitted missions (points_reward)
*/

CREATE OR REPLACE FUNCTION get_pending_points(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  deposit_points INTEGER;
  mission_points INTEGER;
BEGIN
  -- Get points from pending deposits
  SELECT COALESCE(SUM(FLOOR(amount)), 0)::INTEGER INTO deposit_points
  FROM deposits
  WHERE user_id = user_uuid AND status = 'pending';

  -- Get points from submitted missions
  SELECT COALESCE(SUM(m.points_reward), 0)::INTEGER INTO mission_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid AND um.status = 'submitted';

  RETURN deposit_points + mission_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;