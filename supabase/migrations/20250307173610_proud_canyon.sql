/*
  # Points System Functions Migration

  1. Functions
    - `get_pending_points_v2`: Calculate pending points for a user
    - `get_available_points_v2`: Calculate available points for a user
    - `calculate_deposit_points_v2`: Calculate points for deposits
    - `update_points_balance_v2`: Update points balance in real-time

  2. Changes
    - Drop existing triggers safely
    - Create new functions with unique names
    - Add triggers using new functions

  3. Security
    - All functions are SECURITY DEFINER to ensure proper access control
*/

-- First, safely drop existing triggers if they exist
DO $$ BEGIN
  -- Drop triggers
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'calculate_deposit_points_trigger') THEN
    DROP TRIGGER calculate_deposit_points_trigger ON deposits;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_points_balance_trigger') THEN
    DROP TRIGGER update_points_balance_trigger ON deposits;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_points_balance_mission_trigger') THEN
    DROP TRIGGER update_points_balance_mission_trigger ON user_missions;
  END IF;

  -- Drop functions with specific signatures
  DROP FUNCTION IF EXISTS get_pending_points(UUID);
  DROP FUNCTION IF EXISTS get_available_points(UUID);
  DROP FUNCTION IF EXISTS calculate_deposit_points();
  DROP FUNCTION IF EXISTS update_points_balance();
END $$;

-- Create core functions with new names
CREATE OR REPLACE FUNCTION get_pending_points_v2(user_uuid UUID)
RETURNS integer AS $$
DECLARE
  pending_points integer;
BEGIN
  -- Get points from pending deposits
  SELECT COALESCE(SUM(FLOOR(amount)), 0)::integer
  INTO pending_points
  FROM deposits
  WHERE user_id = user_uuid AND status = 'pending';

  -- Add points from pending missions
  SELECT pending_points + COALESCE(SUM(m.points_reward), 0)::integer
  INTO pending_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid AND um.status = 'submitted';

  RETURN pending_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_available_points_v2(user_uuid UUID)
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

  RETURN GREATEST(total_points - spent_points, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION calculate_deposit_points_v2()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate points based on amount for new deposits or status changes
  IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.status != NEW.status) THEN
    -- Set points when status is approved
    IF NEW.status = 'approved' THEN
      NEW.points = FLOOR(NEW.amount)::integer;
    ELSE
      NEW.points = 0;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION update_points_balance_v2()
RETURNS TRIGGER AS $$
BEGIN
  -- Update mission_points_balance
  INSERT INTO mission_points_balance (
    user_id,
    total_points,
    pending_points,
    last_updated_at
  ) VALUES (
    COALESCE(NEW.user_id, OLD.user_id),
    (SELECT get_available_points_v2(COALESCE(NEW.user_id, OLD.user_id))),
    (SELECT get_pending_points_v2(COALESCE(NEW.user_id, OLD.user_id))),
    now()
  )
  ON CONFLICT (user_id) DO UPDATE
  SET 
    total_points = (SELECT get_available_points_v2(EXCLUDED.user_id)),
    pending_points = (SELECT get_pending_points_v2(EXCLUDED.user_id)),
    last_updated_at = now();
    
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers using new functions
CREATE TRIGGER calculate_deposit_points_trigger
  BEFORE INSERT OR UPDATE OF status ON deposits
  FOR EACH ROW
  EXECUTE FUNCTION calculate_deposit_points_v2();

CREATE TRIGGER update_points_balance_trigger
  AFTER INSERT OR UPDATE OF status ON deposits
  FOR EACH ROW
  EXECUTE FUNCTION update_points_balance_v2();

CREATE TRIGGER update_points_balance_mission_trigger
  AFTER INSERT OR UPDATE OF status ON user_missions
  FOR EACH ROW
  EXECUTE FUNCTION update_points_balance_v2();