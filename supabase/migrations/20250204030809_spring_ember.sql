/*
  # Add social missions system

  1. New Tables
    - `social_missions`
      - `id` (uuid, primary key)
      - `title` (text)
      - `points` (integer)
      - `platform` (text)
      - `type` (social_mission_type)
      - `active` (boolean)
      - `created_at` (timestamptz)
    
    - `user_social_missions`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `mission_id` (uuid, references social_missions)
      - `proof_url` (text)
      - `status` (mission_status)
      - `completed_at` (timestamptz)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on both tables
    - Add policies for user access
*/

-- Create mission type enum
CREATE TYPE social_mission_type AS ENUM (
  'registration',  -- Platform registration
  'instagram',     -- Instagram tasks
  'telegram'       -- Telegram tasks
);

-- Create mission status enum
CREATE TYPE mission_status AS ENUM (
  'pending',   -- Waiting for proof
  'submitted', -- Proof submitted
  'approved',  -- Mission completed
  'rejected'   -- Proof rejected
);

-- Create social missions table
CREATE TABLE social_missions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  points integer NOT NULL CHECK (points > 0),
  platform text NOT NULL,
  type social_mission_type NOT NULL,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Create user social missions table
CREATE TABLE user_social_missions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  mission_id uuid REFERENCES social_missions(id) NOT NULL,
  proof_url text,
  status mission_status DEFAULT 'pending',
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, mission_id)
);

-- Enable RLS
ALTER TABLE social_missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_social_missions ENABLE ROW LEVEL SECURITY;

-- Create policies for social_missions table
CREATE POLICY "Anyone can read active social missions"
  ON social_missions
  FOR SELECT
  TO authenticated
  USING (active = true);

CREATE POLICY "Admins can manage social missions"
  ON social_missions
  FOR ALL
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

-- Create policies for user_social_missions table
CREATE POLICY "Users can read own social missions"
  ON user_social_missions
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    is_admin(auth.uid())
  );

CREATE POLICY "Users can update own social missions"
  ON user_social_missions
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert own social missions"
  ON user_social_missions
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Create indexes
CREATE INDEX idx_social_missions_active ON social_missions(active) WHERE active = true;
CREATE INDEX idx_user_social_missions_user ON user_social_missions(user_id);
CREATE INDEX idx_user_social_missions_status ON user_social_missions(status);

-- Insert initial social missions
INSERT INTO social_missions (title, points, platform, type)
VALUES
  ('Cadastro LotoGreen', 5, 'LotoGreen', 'registration'),
  ('Cadastro Goldebet', 5, 'Goldebet', 'registration'),
  ('Cadastro Onabet', 5, 'Onabet', 'registration'),
  ('Cadastro McGames', 5, 'McGames', 'registration'),
  ('Cadastro Br4', 5, 'Br4', 'registration'),
  ('Seguir @laise no Instagram', 5, 'Instagram', 'instagram'),
  ('Marcar @laise nos Stories', 10, 'Instagram', 'instagram'),
  ('Participar do Grupo VIP', 5, 'Telegram', 'telegram'),
  ('Comentar em 10 fotos do perfil @laise', 5, 'Instagram', 'instagram'),
  ('Cadastro Laisebet', 5, 'Laisebet', 'registration');