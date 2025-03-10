/*
  # Update Social Missions

  1. Changes
    - Add new social missions:
      - Comment on 10 photos (10 points)
      - Join Telegram (5 points)
      - Join VIP Group (10 points)
    - Remove missions:
      - Complete Registration
      - Follow Instagram

  2. Security
    - Maintain existing RLS policies
    - No changes to security model needed
*/

-- Delete old missions
DELETE FROM social_missions 
WHERE title IN ('Complete seu Cadastro', 'Siga nosso Instagram');

-- Insert new missions
INSERT INTO social_missions (title, points, type, platform, active) VALUES
  ('Comentar em 10 fotos do perfil @laise', 10, 'instagram', 'Instagram', true),
  ('Entre no nosso Telegram', 5, 'telegram', 'Telegram', true),
  ('Participar do Grupo VIP', 10, 'telegram', 'Telegram', true);