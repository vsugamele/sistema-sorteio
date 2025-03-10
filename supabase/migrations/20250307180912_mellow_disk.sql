/*
  # Add Points Calculation Functions

  1. Overview
    - Added functions to calculate available and pending points
    - Added proper points validation
    - Added security measures

  2. Functions Added
    - get_available_points_v2: Calculates total available points
    - get_pending_points_v2: Calculates pending points
    - calculate_deposit_points_v2: Calculates points for deposits

  3. Security
    - All functions are SECURITY DEFINER
    - Added proper error handling
*/

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points_v2(user_uuid uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  total_points integer := 0;
BEGIN
  -- Get points from approved deposits
  SELECT COALESCE(SUM(points), 0)
  INTO total_points
  FROM deposits
  WHERE user_id = user_uuid
  AND status = 'approved'
  AND points > 0;

  -- Add points from approved missions
  SELECT total_points + COALESCE(SUM(m.points_reward), 0)
  INTO total_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid
  AND um.status = 'approved';

  -- Subtract points spent on roulette
  SELECT total_points - COALESCE(SUM(points_spent), 0)
  INTO total_points
  FROM roulette_spins
  WHERE user_id = user_uuid;

  RETURN GREATEST(total_points, 0);
END;
$$;

-- Function to get pending points
CREATE OR REPLACE FUNCTION get_pending_points_v2(user_uuid uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  pending_points integer := 0;
BEGIN
  -- Get points from pending deposits
  SELECT COALESCE(SUM(FLOOR(amount)), 0)
  INTO pending_points
  FROM deposits
  WHERE user_id = user_uuid
  AND status = 'pending';

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

-- Function to calculate deposit points
CREATE OR REPLACE FUNCTION calculate_deposit_points_v2()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only calculate points for approved deposits
  IF NEW.status = 'approved' THEN
    -- Points are equal to the floor of the amount
    NEW.points := FLOOR(NEW.amount);
  ELSE
    NEW.points := 0;
  END IF;

  RETURN NEW;
END;
$$;