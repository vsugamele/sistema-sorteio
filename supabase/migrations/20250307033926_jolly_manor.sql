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

    - `user_social_missions`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key to auth.users)
      - `mission_id` (uuid, foreign key to social_missions)
      - `proof_url` (text)
      - `status` (mission_status)
      - `completed_at` (timestamp)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on both tables
    - Add policies for:
      - Users can read active missions
      - Users can manage their own mission progress
      - Admins can manage all missions
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

-- Create user social missions table
CREATE TABLE IF NOT EXISTS user_social_missions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  mission_id uuid NOT NULL REFERENCES social_missions(id),
  proof_url text,
  status mission_status DEFAULT 'pending',
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, mission_id)
);

-- Enable RLS
ALTER TABLE social_missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_social_missions ENABLE ROW LEVEL SECURITY;

-- Create policies if they don't exist
DO $$ BEGIN
  -- Social Missions Policies
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

  -- User Social Missions Policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'user_social_missions' 
    AND policyname = 'Users can read own social missions'
  ) THEN
    CREATE POLICY "Users can read own social missions"
      ON user_social_missions
      FOR SELECT
      TO authenticated
      USING ((user_id = auth.uid()) OR is_admin(auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'user_social_missions' 
    AND policyname = 'Users can insert own social missions'
  ) THEN
    CREATE POLICY "Users can insert own social missions"
      ON user_social_missions
      FOR INSERT
      TO authenticated
      WITH CHECK (user_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'user_social_missions' 
    AND policyname = 'Users can update own social missions'
  ) THEN
    CREATE POLICY "Users can update own social missions"
      ON user_social_missions
      FOR UPDATE
      TO authenticated
      USING (user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
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