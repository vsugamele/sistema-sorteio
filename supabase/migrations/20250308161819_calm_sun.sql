/*
  # Fix Points Calculation Functions

  1. Updates
    - Fix ambiguous column reference in get_available_points_v2
    - Improve points calculation for pending deposits and missions
    - Add better error handling

  2. Changes
    - Modified get_available_points_v2 to use explicit table references
    - Updated get_pending_points_v2 to properly calculate pending points
    - Added proper column references to avoid ambiguity
*/

-- Function to get pending points including deposits and missions
CREATE OR REPLACE FUNCTION get_pending_points_v2(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  pending_deposit_points INTEGER;
  pending_mission_points INTEGER;
BEGIN
  -- Get points from pending deposits
  SELECT COALESCE(SUM(d.points), 0)
  INTO pending_deposit_points
  FROM deposits d
  WHERE d.user_id = user_uuid 
  AND d.status = 'pending';

  -- Get points from pending missions
  SELECT COALESCE(SUM(m.points_reward), 0)
  INTO pending_mission_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid 
  AND um.status = 'submitted';

  -- Return total pending points
  RETURN pending_deposit_points + pending_mission_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points_v2(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  approved_points INTEGER;
  used_points INTEGER;
BEGIN
  -- Get points from approved deposits
  SELECT COALESCE(SUM(d.points), 0)
  INTO approved_points
  FROM deposits d
  WHERE d.user_id = user_uuid 
  AND d.status = 'approved';

  -- Add points from completed missions
  approved_points := approved_points + (
    SELECT COALESCE(SUM(m.points_reward), 0)
    FROM user_missions um
    JOIN missions m ON m.id = um.mission_id
    WHERE um.user_id = user_uuid 
    AND um.status = 'approved'
  );

  -- Get points used in roulette spins
  SELECT COALESCE(SUM(rs.points_spent), 0)
  INTO used_points
  FROM roulette_spins rs
  WHERE rs.user_id = user_uuid;

  -- Return available points
  RETURN GREATEST(0, approved_points - used_points);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;