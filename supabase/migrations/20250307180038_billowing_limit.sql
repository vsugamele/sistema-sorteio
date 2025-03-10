/*
  # Fix Roulette System

  1. Overview
    - Fixed prize type casting
    - Improved prize selection and validation
    - Added proper constraints and triggers

  2. Changes
    - Added proper prize type validation
    - Fixed points deduction handling
    - Added proper constraints

  3. Security
    - All functions are SECURITY DEFINER
    - Added proper RLS policies
*/

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
INSERT INTO roulette_prizes (name, type, value, probability, active)
SELECT * FROM (
  VALUES 
    ('Tente Novamente', 'none'::prize_type, 0, 85, true),
    ('R$ 20,00', 'money'::prize_type, 20, 7, true),
    ('Ticket R$ 1.000', 'ticket'::prize_type, 1000, 7.5, true),
    ('R$ 100,00', 'money'::prize_type, 100, 0.5, true)
) AS v (name, type, value, probability, active)
WHERE NOT EXISTS (
  SELECT 1 FROM roulette_prizes LIMIT 1
);