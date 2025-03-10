/*
  # Add Points Tracking for Roulette Spins

  1. New Functions
    - `get_available_points`: Calculates total available points for a user
    - `handle_roulette_spin`: Validates and processes point deduction for spins
    - `update_points_after_spin`: Updates point balances after a spin

  2. Changes
    - Add points tracking for roulette spins
    - Add validation to ensure users have enough points
    - Add automatic point deduction on spin

  3. Security
    - Functions run with SECURITY DEFINER to ensure proper access control
*/

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points(user_uuid uuid)
RETURNS integer AS $$
DECLARE
  total_points integer;
  used_points integer;
BEGIN
  -- Get points from approved deposits
  SELECT COALESCE(SUM(points), 0)
  INTO total_points
  FROM deposits
  WHERE user_id = user_uuid
    AND status = 'approved';

  -- Add points from approved missions
  total_points := total_points + COALESCE((
    SELECT SUM(m.points_reward)
    FROM user_missions um
    JOIN missions m ON m.id = um.mission_id
    WHERE um.user_id = user_uuid
      AND um.status = 'approved'
  ), 0);

  -- Get points used in spins
  SELECT COALESCE(SUM(points_spent), 0)
  INTO used_points
  FROM roulette_spins
  WHERE user_id = user_uuid;

  -- Return available points
  RETURN total_points - used_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle roulette spin
CREATE OR REPLACE FUNCTION handle_roulette_spin()
RETURNS TRIGGER AS $$
DECLARE
  available_points integer;
BEGIN
  -- Get available points
  available_points := get_available_points(NEW.user_id);

  -- Check if user has enough points
  IF available_points < NEW.points_spent THEN
    RAISE EXCEPTION 'Insufficient points available';
  END IF;

  -- Validate prize exists and is active
  IF NOT EXISTS (
    SELECT 1 FROM roulette_prizes
    WHERE id = NEW.prize_id AND active = true
  ) THEN
    RAISE EXCEPTION 'Invalid or inactive prize';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update points after spin
CREATE OR REPLACE FUNCTION update_points_after_spin()
RETURNS TRIGGER AS $$
BEGIN
  -- Points are automatically tracked by get_available_points
  -- This function can be extended for additional point processing if needed
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS handle_roulette_spin_trigger ON roulette_spins;
DROP TRIGGER IF EXISTS points_update_trigger ON roulette_spins;

-- Create triggers
CREATE TRIGGER handle_roulette_spin_trigger
  BEFORE INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION handle_roulette_spin();

CREATE TRIGGER points_update_trigger
  AFTER INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION update_points_after_spin();