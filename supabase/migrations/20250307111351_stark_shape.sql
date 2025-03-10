/*
  # Fix Roulette Points Functions

  1. Changes
    - Drop and recreate points calculation function with proper return type
    - Update roulette spin handling functions
    - Fix triggers for better error handling

  2. Security
    - Functions use SECURITY DEFINER to ensure proper access control
    - Proper error messages for better debugging
*/

-- Drop existing functions and triggers
DROP TRIGGER IF EXISTS handle_roulette_spin_trigger ON roulette_spins;
DROP TRIGGER IF EXISTS points_update_trigger ON roulette_spins;
DROP FUNCTION IF EXISTS handle_roulette_spin();
DROP FUNCTION IF EXISTS update_points_after_spin();
DROP FUNCTION IF EXISTS get_available_points(uuid);

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points(user_uuid uuid)
RETURNS integer AS $$
DECLARE
  total_points integer;
  used_points integer;
BEGIN
  -- Get total points from approved deposits and missions
  SELECT COALESCE(
    (
      SELECT SUM(points)::integer
      FROM deposits
      WHERE user_id = user_uuid AND status = 'approved'
    ) +
    (
      SELECT COALESCE(SUM(m.points_reward), 0)::integer
      FROM user_missions um
      JOIN missions m ON m.id = um.mission_id
      WHERE um.user_id = user_uuid AND um.status = 'approved'
    ),
    0
  ) INTO total_points;

  -- Get points used in spins
  SELECT COALESCE(SUM(points_spent), 0)::integer
  INTO used_points
  FROM roulette_spins
  WHERE user_id = user_uuid;

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
    RAISE EXCEPTION 'Insufficient points available. Required: %, Available: %', NEW.points_spent, available_points;
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

-- Function to update points balance
CREATE OR REPLACE FUNCTION update_points_after_spin()
RETURNS TRIGGER AS $$
BEGIN
  -- Points are automatically tracked by get_available_points
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