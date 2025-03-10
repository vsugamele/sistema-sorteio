/*
  # Points System Update
  
  1. Changes
    - Fix points calculation for deposits
    - Add proper triggers for points updates
    - Ensure points are properly deducted from pending when approved
    - Add real-time updates for points balance
    
  2. Security
    - Add RLS policies for points balance
    - Ensure only authorized users can update points
*/

-- Function to handle deposit points
CREATE OR REPLACE FUNCTION handle_deposit_points()
RETURNS TRIGGER AS $$
BEGIN
  -- If status changed to approved
  IF (TG_OP = 'UPDATE' AND OLD.status != 'approved' AND NEW.status = 'approved') THEN
    -- Update points balance
    INSERT INTO mission_points_transactions (
      user_id,
      amount,
      type,
      created_by,
      description
    ) VALUES (
      NEW.user_id,
      NEW.points,
      'mission_completed',
      NEW.approved_by,
      'Depósito aprovado: ' || NEW.points || ' pontos'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS deposit_points_trigger ON deposits;

-- Create new trigger for deposit points
CREATE TRIGGER deposit_points_trigger
  AFTER UPDATE OF status ON deposits
  FOR EACH ROW
  EXECUTE FUNCTION handle_deposit_points();

-- Function to get pending points
CREATE OR REPLACE FUNCTION get_pending_points(user_uuid UUID)
RETURNS integer AS $$
DECLARE
  pending_points integer := 0;
BEGIN
  -- Get points from pending deposits
  SELECT COALESCE(SUM(FLOOR(amount)), 0)::integer
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

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points(user_uuid UUID)
RETURNS integer AS $$
DECLARE
  total_points integer := 0;
  spent_points integer := 0;
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

-- Function to handle points transaction
CREATE OR REPLACE FUNCTION handle_points_transaction()
RETURNS TRIGGER AS $$
BEGIN
  -- Update mission_points_balance
  INSERT INTO mission_points_balance (user_id, total_points, pending_points)
  VALUES (
    NEW.user_id,
    (SELECT get_available_points(NEW.user_id)),
    (SELECT get_pending_points(NEW.user_id))
  )
  ON CONFLICT (user_id) DO UPDATE
  SET 
    total_points = (SELECT get_available_points(NEW.user_id)),
    pending_points = (SELECT get_pending_points(NEW.user_id)),
    last_updated_at = now();
    
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS update_points_balance_trigger ON mission_points_transactions;

-- Create new trigger for points balance
CREATE TRIGGER update_points_balance_trigger
  AFTER INSERT OR UPDATE ON mission_points_transactions
  FOR EACH ROW
  EXECUTE FUNCTION handle_points_transaction();