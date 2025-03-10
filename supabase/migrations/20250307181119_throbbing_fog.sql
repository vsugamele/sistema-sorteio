/*
  # Update Points Calculation Functions

  1. Overview
    - Fixes ambiguous column references in points calculation
    - Updates functions to properly qualify all column references
    - Maintains existing functionality with improved reliability

  2. Changes
    - Qualifies all column references with table names
    - Improves error handling
    - Adds better comments and documentation

  3. Security
    - Maintains existing security settings
    - Functions remain SECURITY DEFINER
    - Proper RLS policies preserved
*/

-- Drop existing functions to recreate them
DROP FUNCTION IF EXISTS get_available_points_v2(uuid);
DROP FUNCTION IF EXISTS get_pending_points_v2(uuid);

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points_v2(user_uuid uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  total_points integer := 0;
  spent_points integer := 0;
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
  SELECT COALESCE(SUM(rs.points_spent), 0)
  INTO spent_points
  FROM roulette_spins rs
  WHERE rs.user_id = user_uuid;

  -- Return available points (never negative)
  RETURN GREATEST(total_points - spent_points, 0);
END;
$$;

-- Function to get pending points
CREATE OR REPLACE FUNCTION get_pending_points_v2(user_uuid uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  pending_points integer := 0;
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

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_available_points_v2(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_pending_points_v2(uuid) TO authenticated;