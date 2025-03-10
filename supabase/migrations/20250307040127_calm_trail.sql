/*
  # Fix Missions Schema

  1. New Tables
    - `missions` table for storing mission definitions
    - `user_missions` table for tracking user mission progress

  2. Changes
    - Update mission points transaction policies
    - Add proper foreign key relationships
    - Add mission type enum

  3. Security
    - Enable RLS on all tables
    - Add policies for proper access control
*/

-- Create mission type enum if it doesn't exist
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

-- Create mission status enum if it doesn't exist
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

-- Create missions table if it doesn't exist
CREATE TABLE IF NOT EXISTS missions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  points_reward integer NOT NULL CHECK (points_reward > 0),
  type mission_type NOT NULL,
  requirements jsonb NOT NULL DEFAULT '{}'::jsonb,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create user missions table if it doesn't exist
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

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_missions_active ON missions(active) WHERE active = true;
CREATE INDEX IF NOT EXISTS idx_user_missions_user ON user_missions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_missions_completed ON user_missions(completed_at) WHERE completed_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_missions_status ON user_missions(status);

-- Drop existing policies if they exist
DO $$ BEGIN
  DROP POLICY IF EXISTS "Enable full access for admins" ON missions;
  DROP POLICY IF EXISTS "Enable read access for active missions" ON missions;
  DROP POLICY IF EXISTS "Users can read own missions" ON user_missions;
  DROP POLICY IF EXISTS "Users can submit own missions" ON user_missions;
  DROP POLICY IF EXISTS "Users can update own missions" ON user_missions;
EXCEPTION
  WHEN undefined_object THEN null;
END $$;

-- Create policies for missions
CREATE POLICY "Enable full access for admins" ON missions
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

CREATE POLICY "Enable read access for active missions" ON missions
  FOR SELECT
  TO authenticated
  USING ((active = true) OR is_admin(auth.uid()));

-- Create policies for user missions
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