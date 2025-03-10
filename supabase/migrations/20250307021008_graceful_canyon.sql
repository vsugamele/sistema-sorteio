/*
  # Add deposit missions
  
  1. New Data
    - Add deposit missions to the missions table
    - Points for different deposit amounts:
      - R$ 30 = 1 point
      - R$ 50 = 3 points
      - R$ 100 = 5 points
      - R$ 300 = 20 points

  2. Changes
    - Insert deposit missions with type 'deposit'
*/

INSERT INTO missions (id, title, description, points_reward, type, requirements, active)
VALUES 
  (
    gen_random_uuid(), 
    'Depósito de R$ 30',
    'Faça um depósito de R$ 30 e ganhe 1 ponto',
    1,
    'deposit',
    jsonb_build_object('amount', 30),
    true
  ),
  (
    gen_random_uuid(),
    'Depósito de R$ 50',
    'Faça um depósito de R$ 50 e ganhe 3 pontos',
    3,
    'deposit',
    jsonb_build_object('amount', 50),
    true
  ),
  (
    gen_random_uuid(),
    'Depósito de R$ 100',
    'Faça um depósito de R$ 100 e ganhe 5 pontos',
    5,
    'deposit',
    jsonb_build_object('amount', 100),
    true
  ),
  (
    gen_random_uuid(),
    'Depósito de R$ 300',
    'Faça um depósito de R$ 300 e ganhe 20 pontos',
    20,
    'deposit',
    jsonb_build_object('amount', 300),
    true
  );