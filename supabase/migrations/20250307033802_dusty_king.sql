/*
  # Create Missions Schema

  1. New Tables
    - `missions`
      - `id` (uuid, primary key)
      - `title` (text)
      - `points_reward` (integer)
      - `type` (mission_type)
      - `requirements` (jsonb)
      - `active` (boolean)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

    - `user_missions`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key to auth.users)
      - `mission_id` (uuid, foreign key to missions)
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

-- Create mission status enum if not exists
DO $$ BEGIN
  CREATE TYPE mission_status AS ENUM ('pending', 'submitted', 'approved', 'rejected');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create mission type enum if not exists
DO $$ BEGIN
  CREATE TYPE mission_type AS ENUM ('deposit', 'daily_login', 'invite', 'play_games');
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

-- Create policies if they don't exist
DO $$ BEGIN
  -- Missions Policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'missions' 
    AND policyname = 'Enable read access for active missions'
  ) THEN
    CREATE POLICY "Enable read access for active missions"
      ON missions
      FOR SELECT
      TO authenticated
      USING ((active = true) OR is_admin(auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'missions' 
    AND policyname = 'Enable full access for admins'
  ) THEN
    CREATE POLICY "Enable full access for admins"
      ON missions
      FOR ALL
      TO authenticated
      USING (is_admin(auth.uid()))
      WITH CHECK (is_admin(auth.uid()));
  END IF;

  -- User Missions Policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'user_missions' 
    AND policyname = 'Users can read own missions'
  ) THEN
    CREATE POLICY "Users can read own missions"
      ON user_missions
      FOR SELECT
      TO authenticated
      USING ((user_id = auth.uid()) OR is_admin(auth.uid()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'user_missions' 
    AND policyname = 'Users can submit own missions'
  ) THEN
    CREATE POLICY "Users can submit own missions"
      ON user_missions
      FOR INSERT
      TO authenticated
      WITH CHECK (user_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'user_missions' 
    AND policyname = 'Users can update own missions'
  ) THEN
    CREATE POLICY "Users can update own missions"
      ON user_missions
      FOR UPDATE
      TO authenticated
      USING (user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- Insert initial deposit missions
INSERT INTO missions (title, points_reward, type, requirements) VALUES
  ('Depósito de R$ 30', 1, 'deposit', '{"amount": 30}'::jsonb),
  ('Depósito de R$ 50', 3, 'deposit', '{"amount": 50}'::jsonb),
  ('Depósito de R$ 100', 5, 'deposit', '{"amount": 100}'::jsonb),
  ('Depósito de R$ 300', 20, 'deposit', '{"amount": 300}'::jsonb);