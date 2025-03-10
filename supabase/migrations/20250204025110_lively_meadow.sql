/*
  # Add missions system

  1. New Tables
    - `missions`
      - `id` (uuid, primary key)
      - `title` (text)
      - `description` (text)
      - `points_reward` (integer)
      - `type` (mission_type enum)
      - `requirements` (jsonb)
      - `active` (boolean)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `user_missions`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `mission_id` (uuid, references missions)
      - `completed` (boolean)
      - `completed_at` (timestamptz)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on both tables
    - Add policies for user access
*/

-- Create mission type enum
CREATE TYPE mission_type AS ENUM (
  'deposit',      -- Make a deposit
  'daily_login',  -- Login daily
  'invite',       -- Invite friends
  'play_games'    -- Play specific games
);

-- Create missions table
CREATE TABLE missions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  points_reward integer NOT NULL CHECK (points_reward > 0),
  type mission_type NOT NULL,
  requirements jsonb NOT NULL,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create user_missions table
CREATE TABLE user_missions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  mission_id uuid REFERENCES missions(id) NOT NULL,
  completed boolean DEFAULT false,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, mission_id)
);

-- Enable RLS
ALTER TABLE missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_missions ENABLE ROW LEVEL SECURITY;

-- Create policies for missions table
CREATE POLICY "Anyone can read active missions"
  ON missions
  FOR SELECT
  TO authenticated
  USING (active = true);

CREATE POLICY "Admins can manage missions"
  ON missions
  FOR ALL
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

-- Create policies for user_missions table
CREATE POLICY "Users can read own missions"
  ON user_missions
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    is_admin(auth.uid())
  );

CREATE POLICY "Users can update own missions"
  ON user_missions
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "System can insert user missions"
  ON user_missions
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create indexes
CREATE INDEX idx_missions_active ON missions(active) WHERE active = true;
CREATE INDEX idx_user_missions_user ON user_missions(user_id);
CREATE INDEX idx_user_missions_completed ON user_missions(completed) WHERE completed = false;

-- Insert initial missions
INSERT INTO missions (title, description, points_reward, type, requirements)
VALUES
  (
    'Primeiro Depósito',
    'Faça seu primeiro depósito em qualquer plataforma',
    100,
    'deposit',
    '{"min_amount": 20}'
  ),
  (
    'Login Diário',
    'Faça login todos os dias para ganhar pontos',
    50,
    'daily_login',
    '{"consecutive_days": 1}'
  ),
  (
    'Super Depósito',
    'Faça um depósito de R$100 ou mais',
    200,
    'deposit',
    '{"min_amount": 100}'
  ),
  (
    'Jogador Dedicado',
    'Jogue em 3 plataformas diferentes',
    300,
    'play_games',
    '{"platforms_count": 3}'
  );