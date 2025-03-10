/*
  # Add Roulette System Tables

  1. New Tables
    - `roulette_prizes`
      - `id` (uuid, primary key)
      - `name` (text) - Nome do prêmio
      - `type` (enum) - Tipo do prêmio (money, ticket, none)
      - `value` (decimal) - Valor do prêmio (para prêmios em dinheiro)
      - `probability` (integer) - Probabilidade de ganhar (em porcentagem)
      - `created_at` (timestamptz)
      - `active` (boolean) - Se o prêmio está ativo

    - `roulette_spins`
      - `id` (uuid, primary key)
      - `user_id` (uuid) - ID do usuário que girou
      - `prize_id` (uuid) - ID do prêmio ganho
      - `points_spent` (integer) - Pontos gastos
      - `created_at` (timestamptz)
      - `claimed` (boolean) - Se o prêmio foi resgatado
      - `claimed_at` (timestamptz) - Quando o prêmio foi resgatado

  2. Security
    - Enable RLS on both tables
    - Add policies for users to read their own spins
    - Add policies for admins to manage prizes and view all spins
*/

-- Create prize type enum
CREATE TYPE prize_type AS ENUM ('money', 'ticket', 'none');

-- Create roulette_prizes table
CREATE TABLE IF NOT EXISTS roulette_prizes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  type prize_type NOT NULL,
  value decimal DEFAULT 0,
  probability integer NOT NULL CHECK (probability >= 0 AND probability <= 100),
  created_at timestamptz DEFAULT now(),
  active boolean DEFAULT true
);

-- Create roulette_spins table
CREATE TABLE IF NOT EXISTS roulette_spins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  prize_id uuid REFERENCES roulette_prizes(id) NOT NULL,
  points_spent integer NOT NULL DEFAULT 50,
  created_at timestamptz DEFAULT now(),
  claimed boolean DEFAULT false,
  claimed_at timestamptz
);

-- Enable RLS
ALTER TABLE roulette_prizes ENABLE ROW LEVEL SECURITY;
ALTER TABLE roulette_spins ENABLE ROW LEVEL SECURITY;

-- Policies for roulette_prizes
CREATE POLICY "Anyone can read active prizes"
  ON roulette_prizes
  FOR SELECT
  TO authenticated
  USING (active = true);

CREATE POLICY "Admins can manage prizes"
  ON roulette_prizes
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND is_admin = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND is_admin = true
    )
  );

-- Policies for roulette_spins
CREATE POLICY "Users can read own spins"
  ON roulette_spins
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own spins"
  ON roulette_spins
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can view all spins"
  ON roulette_spins
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND is_admin = true
    )
  );

-- Insert initial prizes
INSERT INTO roulette_prizes (name, type, value, probability)
VALUES
  ('Tente Novamente', 'none', 0, 70),
  ('R$ 20,00', 'money', 20, 15),
  ('Ticket R$ 1.000', 'ticket', 1000, 12),
  ('R$ 100,00', 'money', 100, 3);

-- Create function to update user points after spin
CREATE OR REPLACE FUNCTION update_points_after_spin()
RETURNS TRIGGER AS $$
DECLARE
  deposit_id uuid;
BEGIN
  -- Find the first deposit with enough points
  SELECT id INTO deposit_id
  FROM deposits
  WHERE user_id = NEW.user_id
    AND status = 'approved'
    AND points >= NEW.points_spent
  ORDER BY created_at ASC
  LIMIT 1;

  -- If we found a deposit, update its points
  IF deposit_id IS NOT NULL THEN
    UPDATE deposits
    SET points = points - NEW.points_spent
    WHERE id = deposit_id;
  ELSE
    RAISE EXCEPTION 'Insufficient points';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update points
CREATE TRIGGER points_update_trigger
  AFTER INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION update_points_after_spin();