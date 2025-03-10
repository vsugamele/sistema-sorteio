/*
  # Update Prize Calculations and Structure

  1. Changes
    - Update roulette prizes to use ticket system for R$1,000 prizes
    - Adjust probabilities and values
    - Maintain existing smaller prizes
    
  2. Security
    - Maintains existing RLS policies
    - No changes to access control needed
*/

-- First, disable all existing prizes
UPDATE roulette_prizes 
SET active = false;

-- Insert new prize configuration with proper UUIDs
INSERT INTO roulette_prizes (id, name, type, value, probability, active)
VALUES 
  -- Regular money prizes
  (gen_random_uuid(), 'R$ 20,00', 'money', 20, 15, true),
  (gen_random_uuid(), 'R$ 100,00', 'money', 100, 5, true),
  -- Ticket prize for R$1,000 draw
  (gen_random_uuid(), '1 Ticket para Sorteio de R$ 1.000,00', 'ticket', 1000, 1, true),
  -- No prize result
  (gen_random_uuid(), 'Tente Novamente', 'none', 0, 79, true);

-- Create function to calculate pending prizes value
CREATE OR REPLACE FUNCTION get_pending_prizes_value(user_uuid uuid)
RETURNS numeric AS $$
BEGIN
  RETURN COALESCE(
    (SELECT SUM(value)
     FROM prizes
     WHERE user_id = user_uuid 
     AND claimed = false),
    0
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to count pending prizes
CREATE OR REPLACE FUNCTION get_pending_prizes_count(user_uuid uuid)
RETURNS integer AS $$
BEGIN
  RETURN COALESCE(
    (SELECT COUNT(*)
     FROM prizes
     WHERE user_id = user_uuid 
     AND claimed = false),
    0
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;