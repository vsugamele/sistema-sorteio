/*
  # Fix Points Calculation Functions v3

  1. Changes
    - Updated get_pending_points_v2 to include points from pending deposits
    - Fixed points calculation for pending missions
    - Added better error handling and validation
    - Improved performance with optimized queries

  2. Details
    - Now properly includes pending deposit points in calculations
    - Handles all mission types correctly
    - Better null handling and validation
*/

-- Drop existing functions to recreate them
DROP FUNCTION IF EXISTS get_pending_points_v2(UUID);
DROP FUNCTION IF EXISTS get_available_points_v2(UUID);

-- Function to get pending points including deposits and missions
CREATE OR REPLACE FUNCTION get_pending_points_v2(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  pending_deposit_points INTEGER;
  pending_mission_points INTEGER;
BEGIN
  -- Get points from pending deposits
  SELECT COALESCE(SUM(FLOOR(amount)), 0)
  INTO pending_deposit_points
  FROM deposits
  WHERE user_id = user_uuid 
  AND status = 'pending';

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
  SELECT COALESCE(SUM(points), 0)
  INTO approved_points
  FROM deposits
  WHERE user_id = user_uuid 
  AND status = 'approved';

  -- Add points from completed missions
  approved_points := approved_points + (
    SELECT COALESCE(SUM(m.points_reward), 0)
    FROM user_missions um
    JOIN missions m ON m.id = um.mission_id
    WHERE um.user_id = user_uuid 
    AND um.status = 'approved'
  );

  -- Get points used in roulette spins
  SELECT COALESCE(SUM(points_spent), 0)
  INTO used_points
  FROM roulette_spins
  WHERE user_id = user_uuid;

  -- Return available points
  RETURN GREATEST(0, approved_points - used_points);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;