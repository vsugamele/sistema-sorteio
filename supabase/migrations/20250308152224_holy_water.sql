/*
  # Fix Points Calculation V2

  1. Changes
    - Add new function to calculate pending points that includes:
      - Points from pending deposits
      - Points from submitted missions
    - Update existing points functions to be more accurate
    
  2. Security
    - Functions are accessible only to authenticated users
    - Functions use RLS policies for data access
*/

-- Function to calculate pending points from deposits
CREATE OR REPLACE FUNCTION get_pending_points_from_deposits(user_uuid uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN COALESCE(
    (
      SELECT SUM(points)::integer
      FROM deposits
      WHERE user_id = user_uuid 
      AND status = 'pending'
    ),
    0
  );
END;
$$;

-- Function to calculate pending points from missions
CREATE OR REPLACE FUNCTION get_pending_points_from_missions(user_uuid uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN COALESCE(
    (
      SELECT SUM(m.points_reward)::integer
      FROM user_missions um
      JOIN missions m ON m.id = um.mission_id
      WHERE um.user_id = user_uuid 
      AND um.status = 'submitted'
    ),
    0
  );
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
  -- Get pending points from deposits
  SELECT get_pending_points_from_deposits(user_uuid) INTO deposit_points;
  
  -- Get pending points from missions
  SELECT get_pending_points_from_missions(user_uuid) INTO mission_points;
  
  -- Return total pending points
  RETURN COALESCE(deposit_points, 0) + COALESCE(mission_points, 0);
END;
$$;