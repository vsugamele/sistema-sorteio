/*
  # Update Missions Schema and Data
  
  1. Changes
    - Mark existing missions as inactive
    - Add new missions with correct types
    - Use existing mission_type enum values:
      - play_games: For Instagram missions (temporary)
      - invite: For registration missions
      - daily_login: For deposit missions
    
  2. New Missions Added:
    - Instagram engagement missions
    - Platform registration missions
    - Deposit-based missions with different tiers
*/

-- Mark all existing missions as inactive
UPDATE missions SET active = false;

-- Insert new missions
INSERT INTO missions (title, description, points_reward, type, requirements, active)
VALUES 
  -- Instagram Missions (using play_games type temporarily)
  (
    'Marcar @laise nos Stories',
    'Marque @laise nos seus stories do Instagram',
    10,
    'play_games',
    '{"action": "stories_mention"}',
    true
  ),
  (
    'Comentar em 10 Reels da Laise',
    'Comente em 10 reels diferentes da @laise no Instagram',
    10,
    'play_games',
    '{"action": "reels_comment", "count": 10}',
    true
  ),
  (
    'Seguir a @laisebotrader',
    'Siga o perfil @laisebotrader no Instagram',
    5,
    'play_games',
    '{"action": "follow"}',
    true
  ),
  
  -- Platform Registration Missions (using invite type)
  (
    'Cadastro na Goldbet',
    'Faça seu cadastro na plataforma Goldbet',
    5,
    'invite',
    '{"platform": "goldbet"}',
    true
  ),
  (
    'Cadastro na Onabet',
    'Faça seu cadastro na plataforma Onabet',
    5,
    'invite',
    '{"platform": "onabet"}',
    true
  ),
  (
    'Cadastro McGames',
    'Faça seu cadastro na plataforma McGames',
    5,
    'invite',
    '{"platform": "mcgames"}',
    true
  ),
  (
    'Cadastro na Br4Bet',
    'Faça seu cadastro na plataforma Br4Bet',
    5,
    'invite',
    '{"platform": "br4bet"}',
    true
  ),
  (
    'Cadastro na Laisebet',
    'Faça seu cadastro na plataforma Laisebet',
    5,
    'invite',
    '{"platform": "laisebet"}',
    true
  ),
  
  -- Deposit Missions (using daily_login type)
  (
    'Depósito de R$ 30,00',
    'Faça um depósito de R$ 30,00 em qualquer plataforma',
    1,
    'daily_login',
    '{"amount": 30}',
    true
  ),
  (
    'Depósito de R$ 50,00',
    'Faça um depósito de R$ 50,00 em qualquer plataforma',
    3,
    'daily_login',
    '{"amount": 50}',
    true
  ),
  (
    'Depósito de R$ 100,00',
    'Faça um depósito de R$ 100,00 em qualquer plataforma',
    5,
    'daily_login',
    '{"amount": 100}',
    true
  );