/*
  # Fix Missions Schema

  1. New Types
    - mission_type: Enum for different types of missions
    - mission_status: Enum for mission status tracking

  2. New Tables
    - missions: Core missions table
    - user_missions: User mission progress tracking

  3. Security
    - Enable RLS on all tables
    - Add policies for user access
    - Add policies for admin management
*/

-- Create mission_type enum
DO $$ BEGIN
  CREATE TYPE mission_type AS ENUM (
    'registration',
    'instagram',
    'telegram',
    'deposit',
    'daily_login',
    'invite',
    'play_games'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create mission_status enum
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
  requirements jsonb NOT NULL DEFAULT '{}',
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create user_missions table
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

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can read active missions" ON missions;
DROP POLICY IF EXISTS "Admins can manage missions" ON missions;
DROP POLICY IF EXISTS "Users can read own missions" ON user_missions;
DROP POLICY IF EXISTS "Users can submit own missions" ON user_missions;
DROP POLICY IF EXISTS "Users can update own missions" ON user_missions;

-- Missions policies
CREATE POLICY "Anyone can read active missions" ON missions
  FOR SELECT
  TO authenticated
  USING (active = true OR is_admin(auth.uid()));

CREATE POLICY "Admins can manage missions" ON missions
  FOR ALL
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

-- User missions policies
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