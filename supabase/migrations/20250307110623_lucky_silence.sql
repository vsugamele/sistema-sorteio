/*
  # Setup Roulette Prizes System

  1. New Tables
    - `roulette_prizes`: Stores available prizes and their probabilities
    - Includes name, type, value, and probability settings

  2. Initial Data
    - Creates default prize options
    - Sets up probabilities and values

  3. Security
    - Enables RLS
    - Adds policies for prize access
*/

-- Create prize types if not exists
DO $$ BEGIN
  CREATE TYPE prize_type AS ENUM ('money', 'ticket', 'none');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Create roulette prizes table
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

-- Drop existing policies if they exist
DO $$ BEGIN
  DROP POLICY IF EXISTS "Anyone can read active prizes" ON roulette_prizes;
  DROP POLICY IF EXISTS "Admins can manage prizes" ON roulette_prizes;
EXCEPTION
  WHEN undefined_object THEN NULL;
END $$;

-- Create policies
CREATE POLICY "Anyone can read active prizes" 
  ON roulette_prizes
  FOR SELECT 
  TO authenticated 
  USING (active = true);

CREATE POLICY "Admins can manage prizes" 
  ON roulette_prizes
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

-- Insert default prizes if they don't exist
INSERT INTO roulette_prizes (name, type, value, probability)
SELECT 'Tente Novamente', 'none', 0, 85
WHERE NOT EXISTS (
  SELECT 1 FROM roulette_prizes WHERE name = 'Tente Novamente'
);

INSERT INTO roulette_prizes (name, type, value, probability)
SELECT 'R$ 20,00', 'money', 20, 7
WHERE NOT EXISTS (
  SELECT 1 FROM roulette_prizes WHERE name = 'R$ 20,00'
);

INSERT INTO roulette_prizes (name, type, value, probability)
SELECT 'Ticket R$ 1.000', 'ticket', 1000, 7.5
WHERE NOT EXISTS (
  SELECT 1 FROM roulette_prizes WHERE name = 'Ticket R$ 1.000'
);

INSERT INTO roulette_prizes (name, type, value, probability)
SELECT 'R$ 100,00', 'money', 100, 0.5
WHERE NOT EXISTS (
  SELECT 1 FROM roulette_prizes WHERE name = 'R$ 100,00'
);