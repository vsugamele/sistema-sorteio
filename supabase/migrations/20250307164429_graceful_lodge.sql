/*
  # Add Points Calculation Functions

  1. New Functions
    - `calculate_total_points`: Calculates total points from deposits and missions
    - `get_available_points`: Gets available points for a user
    - `get_pending_points`: Gets pending points for a user

  2. Changes
    - Adds proper handling of points from both deposits and missions
    - Ensures consistent point calculation across the application
*/

-- Function to calculate total points
CREATE OR REPLACE FUNCTION calculate_total_points(user_uuid UUID)
RETURNS TABLE (
  available_points INTEGER,
  pending_points INTEGER
) AS $$
BEGIN
  RETURN QUERY
  WITH deposit_points AS (
    SELECT 
      COALESCE(SUM(points) FILTER (WHERE status = 'approved'), 0) as approved_deposit_points,
      COALESCE(SUM(FLOOR(amount)) FILTER (WHERE status = 'pending'), 0) as pending_deposit_points
    FROM deposits
    WHERE user_id = user_uuid
  ),
  mission_points AS (
    SELECT 
      COALESCE(SUM(m.points_reward) FILTER (WHERE um.status = 'approved'), 0) as approved_mission_points,
      COALESCE(SUM(m.points_reward) FILTER (WHERE um.status = 'submitted'), 0) as pending_mission_points
    FROM user_missions um
    JOIN missions m ON m.id = um.mission_id
    WHERE um.user_id = user_uuid
  )
  SELECT 
    (dp.approved_deposit_points + mp.approved_mission_points) as available_points,
    (dp.pending_deposit_points + mp.pending_mission_points) as pending_points
  FROM deposit_points dp
  CROSS JOIN mission_points mp;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points(user_uuid UUID)
RETURNS INTEGER AS $$
  SELECT (result.available_points)::INTEGER
  FROM calculate_total_points(user_uuid) result;
$$ LANGUAGE sql SECURITY DEFINER;

-- Function to get pending points
CREATE OR REPLACE FUNCTION get_pending_points(user_uuid UUID)
RETURNS INTEGER AS $$
  SELECT (result.pending_points)::INTEGER
  FROM calculate_total_points(user_uuid) result;
$$ LANGUAGE sql SECURITY DEFINER;