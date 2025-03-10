/*
  # Add Deposit Missions

  1. New Missions
    - Add deposit missions with different point rewards:
      - R$ 30 = 1 point
      - R$ 50 = 3 points
      - R$ 100 = 5 points
      - R$ 300 = 20 points

  2. Function Updates
    - Update the deposit points calculation function
    - Update the deposit points trigger

  3. Security
    - Maintain existing RLS policies
*/

-- Update or create the function to calculate deposit points
CREATE OR REPLACE FUNCTION calculate_deposit_points(amount numeric)
RETURNS integer AS $$
BEGIN
  -- Calculate points based on deposit amount
  IF amount >= 300 THEN
    RETURN 20;
  ELSIF amount >= 100 THEN
    RETURN 5;
  ELSIF amount >= 50 THEN
    RETURN 3;
  ELSIF amount >= 30 THEN
    RETURN 1;
  ELSE
    RETURN 0;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Update the deposit points trigger function
CREATE OR REPLACE FUNCTION update_deposit_points()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update points when status changes to approved
  IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
    NEW.points = calculate_deposit_points(NEW.amount);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Insert new deposit missions
INSERT INTO missions (title, description, points_reward, type, requirements, active)
VALUES 
  (
    'Depósito de R$ 30',
    'Faça um depósito de R$ 30 e ganhe 1 ponto',
    1,
    'deposit',
    jsonb_build_object('amount', 30),
    true
  ),
  (
    'Depósito de R$ 50',
    'Faça um depósito de R$ 50 e ganhe 3 pontos',
    3,
    'deposit',
    jsonb_build_object('amount', 50),
    true
  ),
  (
    'Depósito de R$ 100',
    'Faça um depósito de R$ 100 e ganhe 5 pontos',
    5,
    'deposit',
    jsonb_build_object('amount', 100),
    true
  ),
  (
    'Depósito de R$ 300',
    'Faça um depósito de R$ 300 e ganhe 20 pontos',
    20,
    'deposit',
    jsonb_build_object('amount', 300),
    true
  );