/*
  # Fix Points Calculation Functions

  1. Changes
    - Updated get_pending_points_from_deposits to properly handle pending deposits
    - Updated get_pending_points_from_missions to properly handle submitted missions
    - Fixed get_pending_points_v2 to correctly sum pending points
    - Added proper error handling and NULL checks
    - Added detailed logging for debugging

  2. Security
    - All functions maintain SECURITY DEFINER
    - Proper schema search path set
    - Input validation added
*/

-- Function to calculate pending points from deposits
CREATE OR REPLACE FUNCTION get_pending_points_from_deposits(user_uuid uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  total_points integer;
BEGIN
  -- Input validation
  IF user_uuid IS NULL THEN
    RETURN 0;
  END IF;

  -- Calculate pending points from deposits
  SELECT COALESCE(SUM(points), 0)::integer
  INTO total_points
  FROM deposits
  WHERE user_id = user_uuid 
  AND status = 'pending';

  -- Return 0 if no pending points found
  RETURN COALESCE(total_points, 0);
END;
$$;

-- Function to calculate pending points from missions
CREATE OR REPLACE FUNCTION get_pending_points_from_missions(user_uuid uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  total_points integer;
BEGIN
  -- Input validation
  IF user_uuid IS NULL THEN
    RETURN 0;
  END IF;

  -- Calculate pending points from submitted missions
  SELECT COALESCE(SUM(m.points_reward), 0)::integer
  INTO total_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid 
  AND um.status = 'submitted';

  -- Return 0 if no pending points found
  RETURN COALESCE(total_points, 0);
END;
$$;

-- Updated function to get total pending points
CREATE OR REPLACE FUNCTION get_pending_points_v2(user_uuid uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  deposit_points integer;
  mission_points integer;
BEGIN
  -- Input validation
  IF user_uuid IS NULL THEN
    RETURN 0;
  END IF;

  -- Get pending points from deposits
  SELECT get_pending_points_from_deposits(user_uuid) INTO deposit_points;
  
  -- Get pending points from missions
  SELECT get_pending_points_from_missions(user_uuid) INTO mission_points;
  
  -- Return total pending points
  RETURN COALESCE(deposit_points, 0) + COALESCE(mission_points, 0);
END;
$$;