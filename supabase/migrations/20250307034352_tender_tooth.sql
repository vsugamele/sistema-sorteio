/*
  # Fix Missions Schema

  1. Changes
    - Drop existing policies before recreating them
    - Create mission types enum
    - Create mission status enum
    - Create missions and user_missions tables
    - Add RLS policies
    - Insert initial missions data

  2. Security
    - Enable RLS on all tables
    - Add policies for users to:
      - Read active missions
      - Submit and update their own missions
    - Add policies for admins to manage all missions
*/

-- Drop existing policies if they exist
DO $$ 
BEGIN
  -- Drop policies from missions table
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'missions' AND policyname = 'Enable read access for active missions'
  ) THEN
    DROP POLICY IF EXISTS "Enable read access for active missions" ON missions;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'missions' AND policyname = 'Enable full access for admins'
  ) THEN
    DROP POLICY IF EXISTS "Enable full access for admins" ON missions;
  END IF;

  -- Drop policies from user_missions table
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'user_missions' AND policyname = 'Users can read own missions'
  ) THEN
    DROP POLICY IF EXISTS "Users can read own missions" ON user_missions;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'user_missions' AND policyname = 'Users can submit own missions'
  ) THEN
    DROP POLICY IF EXISTS "Users can submit own missions" ON user_missions;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'user_missions' AND policyname = 'Users can update own missions'
  ) THEN
    DROP POLICY IF EXISTS "Users can update own missions" ON user_missions;
  END IF;
END $$;

-- Create mission types enum
DO $$ BEGIN
  CREATE TYPE mission_type AS ENUM (
    'deposit',
    'daily_login',
    'invite',
    'play_games',
    'registration',
    'instagram',
    'telegram'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create mission status enum
DO $$ BEGIN
  CREATE TYPE mission_status AS ENUM (
    'pending',
    'submitted',
    'approved',
    'rejected'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create missions table
CREATE TABLE IF NOT EXISTS missions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  points_reward integer NOT NULL CHECK (points_reward > 0),
  type mission_type NOT NULL,
  requirements jsonb DEFAULT '{}'::jsonb NOT NULL,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create user missions table
CREATE TABLE IF NOT EXISTS user_missions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mission_id uuid NOT NULL REFERENCES missions(id),
  proof_url text,
  status mission_status DEFAULT 'pending',
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, mission_id)
);

-- Enable RLS
ALTER TABLE missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_missions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Enable read access for active missions" ON missions
  FOR SELECT
  TO authenticated
  USING ((active = true) OR is_admin(auth.uid()));

CREATE POLICY "Enable full access for admins" ON missions
  FOR ALL
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

CREATE POLICY "Users can read own missions" ON user_missions
  FOR SELECT
  TO authenticated
  USING ((user_id = auth.uid()) OR is_admin(auth.uid()));

CREATE POLICY "Users can submit own missions" ON user_missions
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own missions" ON user_missions
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_missions_active ON missions(active) WHERE active = true;
CREATE INDEX IF NOT EXISTS idx_user_missions_user ON user_missions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_missions_status ON user_missions(status);
CREATE INDEX IF NOT EXISTS idx_user_missions_completed ON user_missions(completed_at) WHERE completed_at IS NOT NULL;

-- Insert initial missions
INSERT INTO missions (title, points_reward, type, requirements) VALUES
  -- Deposit missions
  ('Depósito de R$ 30', 1, 'deposit', '{"amount": 30}'::jsonb),
  ('Depósito de R$ 50', 3, 'deposit', '{"amount": 50}'::jsonb),
  ('Depósito de R$ 100', 5, 'deposit', '{"amount": 100}'::jsonb),
  ('Depósito de R$ 300', 20, 'deposit', '{"amount": 300}'::jsonb),
  
  -- Social missions  
  ('Seguir @laise no Instagram', 5, 'instagram', '{}'::jsonb),
  ('Comentar em 10 fotos do perfil @laise', 10, 'instagram', '{}'::jsonb),
  ('Entre no nosso Telegram', 5, 'telegram', '{}'::jsonb),
  ('Participar do Grupo VIP', 10, 'telegram', '{}'::jsonb),
  
  -- Registration missions
  ('Cadastro Goldbet', 5, 'registration', '{}'::jsonb),
  ('Cadastro Onabet', 5, 'registration', '{}'::jsonb),
  ('Cadastro McGames', 5, 'registration', '{}'::jsonb),
  ('Cadastro BR4BET', 5, 'registration', '{}'::jsonb);