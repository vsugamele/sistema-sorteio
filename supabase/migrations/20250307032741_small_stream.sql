/*
  # Create missions and initial data

  1. New Tables
    - `missions` table for storing mission definitions
      - id: UUID primary key
      - title: Mission title/description
      - points_reward: Points awarded for completion
      - type: Type of mission (registration, instagram, telegram, deposit)
      - requirements: JSON object with mission-specific requirements
      - active: Boolean to control mission visibility
      - created_at: Timestamp of creation
      - updated_at: Timestamp of last update

  2. Initial Data
    - Instagram missions:
      - Story mention (10 points)
      - Comment on 10 reels (10 points)
      - Follow @laisebotrader (5 points)
    - Registration missions:
      - Goldbet registration (5 points)
      - Onabet registration (5 points)
      - McGames registration (5 points)
      - BR4Bet registration (5 points)
      - LaiseBet registration (5 points)
    - Deposit missions:
      - R$ 30 deposit (1 point)
      - R$ 50 deposit (3 points)
      - R$ 100 deposit (5 points)

  3. Security
    - Enable RLS
    - Add policies for read/write access
*/

-- Create type for mission types if it doesn't exist
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
  requirements jsonb NOT NULL DEFAULT '{}',
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE missions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can read active missions" ON missions;
DROP POLICY IF EXISTS "Admins can manage missions" ON missions;

-- Create new policies
CREATE POLICY "Enable read access for active missions" ON missions
  FOR SELECT
  TO authenticated
  USING ((active = true) OR is_admin(auth.uid()));

CREATE POLICY "Enable full access for admins" ON missions
  FOR ALL
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

-- Insert initial missions
INSERT INTO missions (title, points_reward, type, requirements) VALUES
  -- Instagram missions
  ('Marcar @laise nos Stories', 10, 'invite', '{"action": "story_mention"}'),
  ('Comentar em 10 Reels da Laise', 10, 'invite', '{"action": "comment_reels", "count": 10}'),
  ('Seguir a @laisebotrader', 5, 'invite', '{"action": "follow"}'),

  -- Registration missions
  ('Cadastro na Goldbet', 5, 'invite', '{"platform": "goldbet"}'),
  ('Cadastro na Onabet', 5, 'invite', '{"platform": "onabet"}'),
  ('Cadastro McGames', 5, 'invite', '{"platform": "mcgames"}'),
  ('Cadastro na Br4Bet', 5, 'invite', '{"platform": "br4bet"}'),
  ('Cadastro na Laisebet', 5, 'invite', '{"platform": "laisebet"}'),

  -- Deposit missions
  ('Depósito de R$ 30,00', 1, 'deposit', '{"amount": 30}'),
  ('Depósito de R$ 50,00', 3, 'deposit', '{"amount": 50}'),
  ('Depósito de R$ 100,00', 5, 'deposit', '{"amount": 100}');