/*
  # Add Deposit Missions

  1. New Missions
    - Add deposit-based missions with different tiers:
      - R$ 30 = 1 ponto
      - R$ 50 = 3 pontos
      - R$ 100 = 5 pontos
      - R$ 300 = 20 pontos

  2. Security
    - Maintain existing RLS policies
*/

-- Insert deposit missions
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