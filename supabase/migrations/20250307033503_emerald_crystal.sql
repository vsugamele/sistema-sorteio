/*
  # Add Social Missions Data

  1. Insert Initial Data
    - Add all required social missions with points:
      - Instagram missions:
        - Comment on 10 photos (10 points)
        - Follow @laise (5 points)
      - Telegram missions:
        - Join Telegram (5 points)
        - Join VIP Group (10 points)
      - Registration missions:
        - Goldbet (5 points)
        - Onabet (5 points)
        - McGames (5 points)
        - BR4BET (5 points)
*/

-- Insert initial social missions
INSERT INTO social_missions (title, points, platform, type) VALUES
  -- Instagram missions
  ('Comentar em 10 fotos do perfil @laise', 10, 'Instagram', 'instagram'),
  ('Seguir @laise no Instagram', 5, 'Instagram', 'instagram'),
  
  -- Telegram missions
  ('Entre no nosso Telegram', 5, 'Telegram', 'telegram'),
  ('Participar do Grupo VIP', 10, 'Telegram', 'telegram'),
  
  -- Registration missions
  ('Cadastro Goldbet', 5, 'Goldbet', 'registration'),
  ('Cadastro Onabet', 5, 'Onabet', 'registration'),
  ('Cadastro McGames', 5, 'McGames', 'registration'),
  ('Cadastro BR4BET', 5, 'BR4BET', 'registration');