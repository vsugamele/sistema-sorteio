/*
  # Fix Roulette System Policies

  1. Tables
    - `roulette_spins`: Tracks user spins and prizes
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `prize_id` (uuid, references roulette_prizes)
      - `points_spent` (integer)
      - `created_at` (timestamp)
      - `claimed` (boolean)
      - `claimed_at` (timestamp)

  2. Functions
    - `handle_roulette_spin`: Validates and processes spins
    - `update_points_after_spin`: Updates user points after spin

  3. Security
    - Safe policy creation with existence checks
    - RLS policies for spins table
    - Secure point deduction
*/

-- Create roulette_spins table if not exists
CREATE TABLE IF NOT EXISTS roulette_spins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  prize_id uuid NOT NULL REFERENCES roulette_prizes(id),
  points_spent integer NOT NULL DEFAULT 50,
  created_at timestamptz DEFAULT now(),
  claimed boolean DEFAULT false,
  claimed_at timestamptz
);

-- Enable RLS
ALTER TABLE roulette_spins ENABLE ROW LEVEL SECURITY;

-- Safely create policies
DO $$ 
BEGIN
  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS "Users can insert own spins" ON roulette_spins;
  DROP POLICY IF EXISTS "Users can read own spins" ON roulette_spins;
  DROP POLICY IF EXISTS "Admins can view all spins" ON roulette_spins;

  -- Create new policies
  CREATE POLICY "Users can insert own spins"
    ON roulette_spins
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

  CREATE POLICY "Users can read own spins"
    ON roulette_spins
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

  CREATE POLICY "Admins can view all spins"
    ON roulette_spins
    FOR SELECT
    TO authenticated
    USING (is_admin(auth.uid()));
END $$;

-- Function to handle roulette spin
CREATE OR REPLACE FUNCTION handle_roulette_spin()
RETURNS TRIGGER AS $$
DECLARE
  available_points integer;
BEGIN
  -- Get available points
  SELECT COALESCE(SUM(points), 0)
  INTO available_points
  FROM deposits
  WHERE user_id = NEW.user_id
    AND status = 'approved';

  -- Add points from approved missions
  available_points := available_points + COALESCE((
    SELECT SUM(m.points_reward)
    FROM user_missions um
    JOIN missions m ON m.id = um.mission_id
    WHERE um.user_id = NEW.user_id
      AND um.status = 'approved'
  ), 0);

  -- Subtract points from previous spins
  available_points := available_points - COALESCE((
    SELECT SUM(points_spent)
    FROM roulette_spins
    WHERE user_id = NEW.user_id
  ), 0);

  -- Check if user has enough points
  IF available_points < NEW.points_spent THEN
    RAISE EXCEPTION 'Insufficient points available';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS handle_roulette_spin_trigger ON roulette_spins;

-- Create trigger for spin validation
CREATE TRIGGER handle_roulette_spin_trigger
  BEFORE INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION handle_roulette_spin();

-- Function to update points after spin
CREATE OR REPLACE FUNCTION update_points_after_spin()
RETURNS TRIGGER AS $$
BEGIN
  -- Points are automatically deducted by the handle_roulette_spin function
  -- This function can be extended for additional point processing if needed
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS points_update_trigger ON roulette_spins;

-- Create trigger for points update
CREATE TRIGGER points_update_trigger
  AFTER INSERT ON roulette_spins
  FOR EACH ROW
  EXECUTE FUNCTION update_points_after_spin();