/*
  # Add deposit missions
  
  1. New Content
    - Add deposit missions with different amounts and rewards
    - Enable RLS policies
    
  2. Mission Details:
    - R$ 30 deposit = 1 point
    - R$ 50 deposit = 3 points
    - R$ 100 deposit = 5 points
    - R$ 300 deposit = 20 points
*/

-- Insert deposit missions
INSERT INTO missions (title, description, points_reward, type, requirements, active)
VALUES 
  (
    'Depósito de R$ 30',
    'Faça um depósito de R$ 30 e ganhe 1 ponto',
    1,
    'deposit',
    '{"amount": 30}',
    true
  ),
  (
    'Depósito de R$ 50',
    'Faça um depósito de R$ 50 e ganhe 3 pontos',
    3,
    'deposit',
    '{"amount": 50}',
    true
  ),
  (
    'Depósito de R$ 100',
    'Faça um depósito de R$ 100 e ganhe 5 pontos',
    5,
    'deposit',
    '{"amount": 100}',
    true
  ),
  (
    'Depósito de R$ 300',
    'Faça um depósito de R$ 300 e ganhe 20 pontos',
    20,
    'deposit',
    '{"amount": 300}',
    true
  );