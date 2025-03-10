/*
  # Fix Points Calculation Functions

  1. Updates
    - Improve get_pending_points_v2 function to include pending deposits
    - Add trigger to recalculate points when deposits are updated
    - Add function to calculate total pending points including missions

  2. Changes
    - Modified get_pending_points_v2 to include pending deposits
    - Added deposit status change trigger
    - Added mission points calculation
*/

-- Function to get pending points including deposits and missions
CREATE OR REPLACE FUNCTION get_pending_points_v2(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  pending_deposit_points INTEGER;
  pending_mission_points INTEGER;
BEGIN
  -- Get points from pending deposits
  SELECT COALESCE(SUM(points), 0)
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
  total_points INTEGER;
  used_points INTEGER;
BEGIN
  -- Get total points from approved deposits and completed missions
  SELECT COALESCE(total_points, 0)
  INTO total_points
  FROM mission_points_balance
  WHERE user_id = user_uuid;

  -- Get points used in roulette spins
  SELECT COALESCE(SUM(points_spent), 0)
  INTO used_points
  FROM roulette_spins
  WHERE user_id = user_uuid;

  -- Return available points
  RETURN GREATEST(0, total_points - used_points);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger function to update points when deposit status changes
CREATE OR REPLACE FUNCTION update_points_on_deposit_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Notify points_changes channel
  PERFORM pg_notify(
    'points_changes',
    json_build_object(
      'user_id', NEW.user_id,
      'type', 'deposit_status_change',
      'old_status', OLD.status,
      'new_status', NEW.status
    )::text
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for deposit status changes
DROP TRIGGER IF EXISTS deposit_points_update_trigger ON deposits;
CREATE TRIGGER deposit_points_update_trigger
  AFTER UPDATE OF status
  ON deposits
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION update_points_on_deposit_change();