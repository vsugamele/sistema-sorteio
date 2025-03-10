/*
  # Fix mission proofs schema
  
  1. Changes
    - Rename user_social_missions to user_missions_progress
    - Update foreign key to reference missions table instead of social_missions
    - Migrate existing data
*/

-- Create new table with correct foreign key
CREATE TABLE IF NOT EXISTS user_missions_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  mission_id uuid NOT NULL REFERENCES missions(id),
  proof_url text,
  status mission_status DEFAULT 'pending',
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, mission_id)
);

-- Copy data from old table
INSERT INTO user_missions_progress (
  id, user_id, mission_id, proof_url, status, completed_at, created_at
)
SELECT 
  id, user_id, mission_id, proof_url, status, completed_at, created_at
FROM user_social_missions
WHERE EXISTS (
  SELECT 1 FROM missions WHERE id = mission_id
);

-- Enable RLS
ALTER TABLE user_missions_progress ENABLE ROW LEVEL SECURITY;

-- Add policies
CREATE POLICY "Users can insert own progress" 
  ON user_missions_progress
  FOR INSERT 
  TO authenticated 
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can read own progress" 
  ON user_missions_progress
  FOR SELECT 
  TO authenticated 
  USING (user_id = auth.uid() OR is_admin(auth.uid()));

CREATE POLICY "Users can update own progress" 
  ON user_missions_progress
  FOR UPDATE
  TO authenticated 
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());