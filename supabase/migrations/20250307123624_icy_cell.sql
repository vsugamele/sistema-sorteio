/*
  # Fix Points System

  1. Changes
    - Drop and recreate points calculation function with proper validation
    - Add better error handling for insufficient points
    - Fix points deduction logic
    - Add transaction support for point operations

  2. Security
    - Functions use SECURITY DEFINER to ensure proper access control
    - Proper validation of user points before deduction
*/

-- Drop existing functions and triggers
DROP TRIGGER IF EXISTS handle_roulette_spin_trigger ON roulette_spins;
DROP FUNCTION IF EXISTS handle_roulette_spin();
DROP FUNCTION IF EXISTS get_available_points(uuid);

-- Function to get available points
CREATE FUNCTION get_available_points(user_uuid uuid)
RETURNS integer AS $$
DECLARE
  total_points integer;
  used_points integer;
BEGIN
  -- Get total points from approved deposits
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

  -- Get points used in spins
  SELECT COALESCE(SUM(points_spent), 0)::integer
  INTO used_points
  FROM roulette_spins
  WHERE user_id = user_uuid;

  RETURN total_points - used_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle roulette spin with transaction
CREATE FUNCTION handle_roulette_spin()
RETURNS TRIGGER AS $$
DECLARE
  available_points integer;
BEGIN
  -- Get available points within transaction
  available_points := get_available_points(NEW.user_id);

  -- Validate points
  IF available_points < NEW.points_spent THEN
    RAISE EXCEPTION 'Pontos insuficientes para jogar. Disponível: %, Necessário: %', available_points, NEW.points_spent
      USING HINT = 'Faça mais depósitos ou complete missões para ganhar pontos';
  END IF;

  -- Validate prize
  IF NOT EXISTS (
    SELECT 1 FROM roulette_prizes
    WHERE id = NEW.prize_id AND active = true
  ) THEN
    RAISE EXCEPTION 'Prêmio inválido ou inativo'
      USING HINT = 'O prêmio selecionado não está disponível';
  END IF;

  -- Set default values if not provided
  NEW.created_at := COALESCE(NEW.created_at, now());
  NEW.claimed := COALESCE(NEW.claimed, false);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for spin validation
CREATE TRIGGER handle_roulette_spin_trigger
  BEFORE INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION handle_roulette_spin();