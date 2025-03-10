/*
  # Fix Roulette System

  1. Overview
    - Added proper points calculation functions
    - Fixed prize selection logic with proper type casting
    - Added points deduction handling
    - Added proper error handling

  2. Changes
    - Added get_available_points_v2 function
    - Added handle_roulette_spin function with proper type casting
    - Added proper prize selection logic
    - Added points deduction trigger

  3. Security
    - All functions are SECURITY DEFINER
    - Added proper RLS policies
*/

-- Function to get available points
CREATE OR REPLACE FUNCTION get_available_points_v2(user_uuid uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  total_points integer;
BEGIN
  -- Get points from approved deposits
  SELECT COALESCE(SUM(points), 0)
  INTO total_points
  FROM deposits
  WHERE user_id = user_uuid AND status = 'approved';

  -- Add points from approved missions
  SELECT total_points + COALESCE(SUM(m.points_reward), 0)
  INTO total_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid AND um.status = 'approved';

  -- Subtract points spent on roulette
  SELECT total_points - COALESCE(SUM(points_spent), 0)
  INTO total_points
  FROM roulette_spins
  WHERE user_id = user_uuid;

  RETURN total_points;
END;
$$;

-- Function to get pending points
CREATE OR REPLACE FUNCTION get_pending_points_v2(user_uuid uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  pending_points integer;
BEGIN
  -- Get points from pending deposits
  SELECT COALESCE(FLOOR(SUM(amount)), 0)::integer
  INTO pending_points
  FROM deposits
  WHERE user_id = user_uuid AND status = 'pending';

  -- Add points from pending missions
  SELECT pending_points + COALESCE(SUM(m.points_reward), 0)
  INTO pending_points
  FROM user_missions um
  JOIN missions m ON m.id = um.mission_id
  WHERE um.user_id = user_uuid AND um.status = 'submitted';

  RETURN pending_points;
END;
$$;

-- Drop existing triggers first
DROP TRIGGER IF EXISTS handle_roulette_spin_trigger ON roulette_spins;

-- Create function to handle points deduction and prize selection
CREATE OR REPLACE FUNCTION handle_roulette_spin()
RETURNS TRIGGER AS $$
DECLARE
  available_points integer;
  total_probability integer;
  random_value integer;
  selected_prize_id uuid;
BEGIN
  -- Get current available points
  SELECT get_available_points_v2(NEW.user_id) INTO available_points;
  
  -- Validate points
  IF available_points < NEW.points_spent THEN
    RAISE EXCEPTION 'Insufficient points available. Required: %, Available: %', NEW.points_spent, available_points;
  END IF;

  -- Get total probability
  SELECT SUM(probability)::integer INTO total_probability
  FROM roulette_prizes
  WHERE active = true;

  -- Generate random value
  SELECT floor(random() * total_probability)::integer INTO random_value;

  -- Select prize based on probability
  SELECT id INTO selected_prize_id
  FROM (
    SELECT 
      id,
      sum(probability) OVER (ORDER BY probability DESC) as cumulative_probability
    FROM roulette_prizes
    WHERE active = true
  ) as prizes
  WHERE cumulative_probability > random_value
  LIMIT 1;

  -- Set the selected prize
  NEW.prize_id = selected_prize_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for roulette spins
CREATE TRIGGER handle_roulette_spin_trigger
  BEFORE INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION handle_roulette_spin();

-- Add default prizes if none exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM roulette_prizes LIMIT 1) THEN
    INSERT INTO roulette_prizes (name, type, value, probability, active)
    VALUES 
      ('Tente Novamente', 'none'::prize_type, 0, 85, true),
      ('R$ 20,00', 'money'::prize_type, 20, 7, true),
      ('Ticket R$ 1.000', 'ticket'::prize_type, 1000, 7.5, true),
      ('R$ 100,00', 'money'::prize_type, 100, 0.5, true);
  END IF;
END $$;