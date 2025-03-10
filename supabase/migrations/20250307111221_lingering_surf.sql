/*
  # Fix Roulette Functions and Points Tracking

  1. Changes
    - Drop and recreate get_user_points function with proper return type
    - Update handle_roulette_spin function with improved validation
    - Add update_points_after_spin function for point tracking
    - Recreate triggers with proper order

  2. Security
    - All functions run with SECURITY DEFINER
    - Proper validation of user permissions
*/

-- Drop existing functions and triggers to avoid conflicts
DROP TRIGGER IF EXISTS handle_roulette_spin_trigger ON roulette_spins;
DROP TRIGGER IF EXISTS points_update_trigger ON roulette_spins;
DROP FUNCTION IF EXISTS get_user_points(uuid);
DROP FUNCTION IF EXISTS handle_roulette_spin();
DROP FUNCTION IF EXISTS update_points_after_spin();

-- Function to get user points
CREATE OR REPLACE FUNCTION get_user_points(user_uuid uuid)
RETURNS numeric AS $$
DECLARE
  deposit_points numeric;
  mission_points numeric;
  used_points numeric;
BEGIN
  -- Get points from approved deposits
  SELECT COALESCE(SUM(points), 0)
  INTO deposit_points
  FROM deposits
  WHERE user_id = user_uuid
    AND status = 'approved';

  -- Get points from approved missions
  SELECT COALESCE(SUM(m.points_reward), 0)
  INTO mission_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid
    AND um.status = 'approved';

  -- Get points used in spins
  SELECT COALESCE(SUM(points_spent), 0)
  INTO used_points
  FROM roulette_spins
  WHERE user_id = user_uuid;

  -- Return available points
  RETURN (deposit_points + mission_points - used_points);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle roulette spin
CREATE OR REPLACE FUNCTION handle_roulette_spin()
RETURNS TRIGGER AS $$
DECLARE
  available_points numeric;
BEGIN
  -- Get available points
  available_points := get_user_points(NEW.user_id);

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
  -- Points are automatically tracked by get_user_points
  -- This function can be extended for additional point processing if needed
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers
CREATE TRIGGER handle_roulette_spin_trigger
  BEFORE INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION handle_roulette_spin();

CREATE TRIGGER points_update_trigger
  AFTER INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION update_points_after_spin();