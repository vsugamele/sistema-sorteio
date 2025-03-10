/*
  # Fix Pending Points Calculation

  1. Changes
    - Update get_pending_points_v2 function to correctly calculate pending points from:
      - Pending deposits
      - Submitted missions
    - Add proper error handling and null checks
    - Optimize performance with better query structure

  2. Security
    - Maintain existing RLS policies
    - Keep function as SECURITY DEFINER
*/

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_pending_points_v2(uuid);

-- Create improved function for calculating pending points
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
  -- Calculate pending points from deposits
  SELECT COALESCE(SUM(points), 0)::integer
  INTO deposit_points
  FROM deposits
  WHERE user_id = user_uuid 
  AND status = 'pending';

  -- Calculate pending points from submitted missions
  SELECT COALESCE(SUM(m.points_reward), 0)::integer
  INTO mission_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid 
  AND um.status = 'submitted';

  -- Return total pending points
  RETURN deposit_points + mission_points;
END;
$$;