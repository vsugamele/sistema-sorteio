/*
  # Create Roulette Prizes Table

  1. New Tables
    - `roulette_prizes`
      - `id` (uuid, primary key)
      - `name` (text)
      - `type` (prize_type)
      - `value` (numeric)
      - `probability` (integer)
      - `created_at` (timestamptz)
      - `active` (boolean)

  2. Security
    - Enable RLS
    - Add policies for admins and users
    
  3. Default Data
    - Insert default prize options with proper type casting
*/

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can manage prizes" ON roulette_prizes;
DROP POLICY IF EXISTS "Anyone can read active prizes" ON roulette_prizes;

-- Create roulette prizes if not exists
CREATE TABLE IF NOT EXISTS roulette_prizes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  type prize_type NOT NULL,
  value numeric DEFAULT 0,
  probability integer NOT NULL CHECK (probability >= 0 AND probability <= 100),
  created_at timestamptz DEFAULT now(),
  active boolean DEFAULT true
);

-- Enable RLS
ALTER TABLE roulette_prizes ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Admins can manage prizes" ON roulette_prizes
  FOR ALL TO authenticated
  USING (auth.uid() IN (SELECT id FROM users WHERE is_admin = true))
  WITH CHECK (auth.uid() IN (SELECT id FROM users WHERE is_admin = true));

CREATE POLICY "Anyone can read active prizes" ON roulette_prizes
  FOR SELECT TO authenticated
  USING (active = true);

-- Insert default prizes if not exists
INSERT INTO roulette_prizes (name, type, value, probability, active)
SELECT * FROM (
  VALUES 
    ('Tente Novamente', 'none'::prize_type, 0, 85, true),
    ('R$ 20,00', 'money'::prize_type, 20, 7, true),
    ('Ticket R$ 1.000', 'ticket'::prize_type, 1000, 7.5, true),
    ('R$ 100,00', 'money'::prize_type, 100, 0.5, true)
) AS v (name, type, value, probability, active)
WHERE NOT EXISTS (
  SELECT 1 FROM roulette_prizes LIMIT 1
);