/*
  # Fix Points Calculation System
  
  1. Changes
    - Fix points calculation for deposits and missions
    - Add proper triggers for real-time updates
    - Ensure points are correctly updated across all components
    
  2. Security
    - Maintain RLS policies
    - Ensure data integrity
*/

-- Function to calculate deposit points
CREATE OR REPLACE FUNCTION calculate_deposit_points(amount numeric)
RETURNS integer AS $$
BEGIN
  -- Round down to nearest integer
  RETURN FLOOR(amount)::integer;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle deposit points
CREATE OR REPLACE FUNCTION handle_deposit_points()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate points based on amount
  NEW.points = calculate_deposit_points(NEW.amount);
  
  -- Update points balance
  IF (TG_OP = 'UPDATE' AND OLD.status != NEW.status) THEN
    -- If approved, add points transaction
    IF (NEW.status = 'approved') THEN
      INSERT INTO mission_points_transactions (
        user_id,
        amount,
        type,
        created_by,
        description,
        reference_id
      ) VALUES (
        NEW.user_id,
        NEW.points,
        'mission_completed',
        NEW.approved_by,
        'Depósito aprovado: ' || NEW.points || ' pontos',
        NEW.id
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS deposit_points_trigger ON deposits;

-- Create new trigger for deposit points
CREATE TRIGGER deposit_points_trigger
  BEFORE UPDATE OF status ON deposits
  FOR EACH ROW
  EXECUTE FUNCTION handle_deposit_points();

-- Function to get pending points
CREATE OR REPLACE FUNCTION get_pending_points(user_uuid UUID)
RETURNS integer AS $$
DECLARE
  pending_points integer;
BEGIN
  -- Get points from pending deposits
  SELECT COALESCE(SUM(points), 0)::integer
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

  RETURN GREATEST(total_points - spent_points, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update points balance
CREATE OR REPLACE FUNCTION update_points_balance()
RETURNS TRIGGER AS $$
BEGIN
  -- Update mission_points_balance
  INSERT INTO mission_points_balance (
    user_id,
    total_points,
    pending_points,
    last_updated_at
  ) VALUES (
    NEW.user_id,
    (SELECT get_available_points(NEW.user_id)),
    (SELECT get_pending_points(NEW.user_id)),
    now()
  )
  ON CONFLICT (user_id) DO UPDATE
  SET 
    total_points = (SELECT get_available_points(NEW.user_id)),
    pending_points = (SELECT get_pending_points(NEW.user_id)),
    last_updated_at = now();
    
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing triggers
DROP TRIGGER IF EXISTS update_points_balance_trigger ON deposits;
DROP TRIGGER IF EXISTS update_points_balance_mission_trigger ON user_missions;

-- Create triggers for points balance updates
CREATE TRIGGER update_points_balance_trigger
  AFTER INSERT OR UPDATE OF status ON deposits
  FOR EACH ROW
  EXECUTE FUNCTION update_points_balance();

CREATE TRIGGER update_points_balance_mission_trigger
  AFTER INSERT OR UPDATE OF status ON user_missions
  FOR EACH ROW
  EXECUTE FUNCTION update_points_balance();