/*
  # Social Missions Schema Update

  1. New Tables
    - `social_missions`
      - `id` (uuid, primary key)
      - `title` (text)
      - `points` (integer)
      - `platform` (text)
      - `type` (social_mission_type)
      - `active` (boolean)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Changes
    - Adds social_mission_type enum
    - Creates social_missions table
    - Adds RLS policies for social_missions

  3. Security
    - Enables RLS on social_missions table
    - Adds policies for:
      - Admins: Full access
      - Users: Read access to active missions
*/

-- Create social mission type enum if it doesn't exist
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
  platform text,
  type social_mission_type NOT NULL,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE social_missions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Enable full access for admins" ON social_missions
  FOR ALL
  TO authenticated
  USING ((SELECT is_admin FROM users WHERE id = auth.uid()))
  WITH CHECK ((SELECT is_admin FROM users WHERE id = auth.uid()));

CREATE POLICY "Enable read access for active missions" ON social_missions
  FOR SELECT
  TO authenticated
  USING (active = true);

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
ALTER TABLE user_social_missions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can read own missions" ON user_social_missions
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR (SELECT is_admin FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can submit own missions" ON user_social_missions
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own missions" ON user_social_missions
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_social_missions_user ON user_social_missions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_social_missions_status ON user_social_missions(status);
CREATE INDEX IF NOT EXISTS idx_user_social_missions_completed ON user_social_missions(completed_at) WHERE completed_at IS NOT NULL;