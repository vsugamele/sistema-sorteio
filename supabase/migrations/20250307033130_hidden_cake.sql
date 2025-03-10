/*
  # Update Mission Points and Add Missing Missions

  1. Changes
    - Update points for existing missions:
      - Cadastro Goldbet (5 points)
      - Cadastro Onabet (5 points)
      - Cadastro McGames (5 points)
      - Cadastro BR4Bet (5 points)
      - Comentar em 10 fotos do perfil @laise (10 points)
      - Entre no nosso Telegram (5 points)
      - Participar do Grupo VIP (10 points)

  2. Security
    - Maintain existing RLS policies
    - No changes to security model needed
*/

-- Update points for registration missions
UPDATE missions
SET points_reward = 5
WHERE title IN (
  'Cadastro na Goldbet',
  'Cadastro na Onabet',
  'Cadastro McGames',
  'Cadastro na Br4Bet'
);

-- Update points for social missions
UPDATE missions
SET points_reward = 10
WHERE title = 'Comentar em 10 fotos do perfil @laise';

-- Update points for Telegram missions
UPDATE missions
SET points_reward = 5
WHERE title = 'Entre no nosso Telegram';

UPDATE missions
SET points_reward = 10
WHERE title = 'Participar do Grupo VIP';