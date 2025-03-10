/*
  # Add new social missions

  1. New Missions
    - Video proof mission
    - Facebook groups mission
    - Friend referral mission

  2. Changes
    - Adds three new missions to the social_missions table
    - Each mission has specific points rewards
    - All missions are active by default

  3. Security
    - Inherits existing RLS policies from social_missions table
*/

-- Add new missions
INSERT INTO social_missions (title, points, type, active)
VALUES 
  ('Faça um vídeo com um ganho seu e envie no suporte', 100, 'registration', true),
  ('Poste seu link em 10 Grupos do Facebook', 150, 'registration', true),
  ('Indique nosso Grupo para 10 amigos', 200, 'registration', true);