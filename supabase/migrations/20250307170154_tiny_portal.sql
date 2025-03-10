/*
  # Update Points Calculation Functions
  
  1. Changes
    - Fix points calculation for deposits and missions
    - Add trigger to update points on deposit status change
    - Ensure points are calculated correctly when deposits are approved
*/

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points(user_uuid UUID)
RETURNS integer AS $$
DECLARE
  total_points integer;
  spent_points integer;
BEGIN
  -- Get points from approved deposits
  SELECT COALESCE(SUM(points), 0)::integer
  INTO total_points
  FROM deposits
  WHERE user_id = user_uuid AND status = 'approved';

  -- Add points from approved missions
  SELECT total_points + COALESCE(SUM(m.points_reward), 0)::integer
  INTO total_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid AND um.status = 'approved';

  -- Get points spent on roulette
  SELECT COALESCE(SUM(points_spent), 0)::integer
  INTO spent_points
  FROM roulette_spins
  WHERE user_id = user_uuid;

  -- Return available points (never negative)
  RETURN GREATEST(total_points - spent_points, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get pending points
CREATE OR REPLACE FUNCTION get_pending_points(user_uuid UUID)
RETURNS integer AS $$
DECLARE
  pending_points integer;
BEGIN
  -- Get points from pending deposits
  SELECT COALESCE(FLOOR(SUM(amount)), 0)::integer
  INTO pending_points
  FROM deposits
  WHERE user_id = user_uuid AND status = 'pending';

  -- Add points from submitted missions
  SELECT pending_points + COALESCE(SUM(m.points_reward), 0)::integer
  INTO pending_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid AND um.status = 'submitted';

  RETURN pending_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update deposit points
CREATE OR REPLACE FUNCTION update_deposit_points()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update points when status changes to approved
  IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
    -- Set points equal to the deposit amount (1 point per real)
    NEW.points = FLOOR(NEW.amount)::integer;
  END IF;

  -- Clear points if status changes from approved
  IF NEW.status != 'approved' AND OLD.status = 'approved' THEN
    NEW.points = 0;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;