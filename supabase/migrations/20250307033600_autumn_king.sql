/*
  # Create Social Missions Schema

  1. New Tables
    - `social_missions`
      - `id` (uuid, primary key)
      - `title` (text)
      - `points` (integer)
      - `platform` (text)
      - `type` (social_mission_type)
      - `active` (boolean)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on social_missions table
    - Add policies for:
      - Anyone can read active missions
      - Admins can manage all missions

  3. Initial Data
    - Add all required social missions with points
*/

-- Create social mission type enum if not exists
DO $$ BEGIN
  CREATE TYPE social_mission_type AS ENUM ('registration', 'instagram', 'telegram');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create social missions table
CREATE TABLE IF NOT EXISTS social_missions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  points integer NOT NULL CHECK (points > 0),
  platform text NOT NULL,
  type social_mission_type NOT NULL,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE social_missions ENABLE ROW LEVEL SECURITY;

-- Create policies if they don't exist
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'social_missions' 
    AND policyname = 'Anyone can read active social missions'
  ) THEN
    CREATE POLICY "Anyone can read active social missions"
      ON social_missions
      FOR SELECT
      TO authenticated
      USING ((active = true) OR is_admin(auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'social_missions' 
    AND policyname = 'Admins can manage social missions'
  ) THEN
    CREATE POLICY "Admins can manage social missions"
      ON social_missions
      FOR ALL
      TO authenticated
      USING (is_admin(auth.uid()))
      WITH CHECK (is_admin(auth.uid()));
  END IF;
END $$;

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