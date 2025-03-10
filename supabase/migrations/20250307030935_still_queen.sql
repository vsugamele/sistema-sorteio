/*
  # Fix Missions Schema

  1. New Types
    - social_mission_type: Enum for different types of social missions
    - mission_status: Enum for mission status tracking

  2. New Tables
    - social_missions: Core social missions table
    - user_social_missions: User mission progress tracking

  3. Security
    - Enable RLS on all tables
    - Add policies for user access
    - Add policies for admin management
*/

-- Create social_mission_type enum
DO $$ BEGIN
  CREATE TYPE social_mission_type AS ENUM (
    'registration',
    'instagram',
    'telegram'
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

-- Create social_missions table
CREATE TABLE IF NOT EXISTS social_missions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  points integer NOT NULL CHECK (points > 0),
  platform text NOT NULL,
  type social_mission_type NOT NULL,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Create user_social_missions table
CREATE TABLE IF NOT EXISTS user_social_missions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
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

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can read active social missions" ON social_missions;
DROP POLICY IF EXISTS "Admins can manage social missions" ON social_missions;
DROP POLICY IF EXISTS "Users can read own social missions" ON user_social_missions;
DROP POLICY IF EXISTS "Users can submit own social missions" ON user_social_missions;
DROP POLICY IF EXISTS "Users can update own social missions" ON user_social_missions;

-- Social missions policies
CREATE POLICY "Anyone can read active social missions" ON social_missions
  FOR SELECT
  TO authenticated
  USING (active = true OR is_admin(auth.uid()));

CREATE POLICY "Admins can manage social missions" ON social_missions
  FOR ALL
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

-- User social missions policies
CREATE POLICY "Users can read own social missions" ON user_social_missions
  FOR SELECT
  TO authenticated
  USING ((user_id = auth.uid()) OR is_admin(auth.uid()));

CREATE POLICY "Users can submit own social missions" ON user_social_missions
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own social missions" ON user_social_missions
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_social_missions_active ON social_missions(active) WHERE active = true;
CREATE INDEX IF NOT EXISTS idx_social_missions_type_active ON social_missions(type) WHERE active = true;
CREATE INDEX IF NOT EXISTS idx_user_social_missions_user ON user_social_missions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_social_missions_status ON user_social_missions(status);