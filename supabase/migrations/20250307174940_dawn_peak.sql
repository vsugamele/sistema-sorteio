/*
  # Fix Points System V4

  1. Changes
    - Drop existing triggers and functions with CASCADE
    - Create new functions for points calculation with improved logic
    - Add proper triggers for points calculation and balance updates
    - Fix points calculation logic to prevent points from being zeroed

  2. Functions
    - get_pending_points_v2: Calculate pending points from deposits and missions
    - get_available_points_v2: Calculate available points considering spent points
    - calculate_deposit_points_v2: Calculate points for deposits
    - update_points_balance_v2: Update points balance
    - handle_points_deduction: Handle points deduction for roulette spins

  3. Security
    - All functions are SECURITY DEFINER to ensure proper access control
*/

-- Drop existing triggers and functions with CASCADE
DROP TRIGGER IF EXISTS calculate_deposit_points_trigger ON deposits CASCADE;
DROP TRIGGER IF EXISTS update_points_balance_trigger ON deposits CASCADE;
DROP TRIGGER IF EXISTS update_points_balance_mission_trigger ON user_missions CASCADE;
DROP TRIGGER IF EXISTS handle_roulette_spin_trigger ON roulette_spins CASCADE;

DROP FUNCTION IF EXISTS get_pending_points_v2(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_available_points_v2(UUID) CASCADE;
DROP FUNCTION IF EXISTS calculate_deposit_points_v2() CASCADE;
DROP FUNCTION IF EXISTS update_points_balance_v2() CASCADE;
DROP FUNCTION IF EXISTS handle_points_deduction() CASCADE;

-- Function to get pending points
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

-- Function to get available points
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

-- Function to calculate points for deposits
CREATE OR REPLACE FUNCTION calculate_deposit_points_v2()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate points based on amount for new deposits or status changes
  IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.status != NEW.status) THEN
    -- Set points when status is approved
    IF NEW.status = 'approved' THEN
      NEW.points = FLOOR(NEW.amount)::integer;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update points balance
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

-- Function to handle points deduction for roulette spins
CREATE OR REPLACE FUNCTION handle_points_deduction()
RETURNS TRIGGER AS $$
DECLARE
  available_points integer;
BEGIN
  -- Get available points
  SELECT get_available_points_v2(NEW.user_id) INTO available_points;
  
  -- Check if user has enough points
  IF available_points < NEW.points_spent THEN
    RAISE EXCEPTION 'Insufficient points available';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers
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

CREATE TRIGGER handle_roulette_spin_trigger
  BEFORE INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION handle_points_deduction();