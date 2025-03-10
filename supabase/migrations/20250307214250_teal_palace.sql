/*
  # Add video and social sharing missions

  1. New Missions
    - Video proof mission (100 points)
    - Facebook groups sharing mission (150 points)
    - Friend referral mission (200 points)

  2. Changes
    - Adds three new missions to the missions table
    - Each mission has specific points rewards
    - All missions are active by default
    - Uses registration type for verification-based tasks

  3. Security
    - Inherits existing RLS policies from missions table
*/

INSERT INTO missions (title, points_reward, type, active)
VALUES 
  ('Faça um vídeo com um ganho seu e envie no suporte', 100, 'registration', true),
  ('Poste seu link em 10 Grupos do Facebook', 150, 'registration', true),
  ('Indique nosso Grupo para 10 amigos', 200, 'registration', true);