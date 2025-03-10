/*
  # Add tickets table and functions

  1. New Tables
    - `tickets` - Stores ticket information for R$1,000 prizes
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `value` (numeric)
      - `created_at` (timestamptz)
      - `claimed` (boolean)
      - `claimed_at` (timestamptz)

  2. Security
    - Enable RLS on `tickets` table
    - Add policies for:
      - Users can read own tickets
      - System can insert tickets
      - Admins can update tickets

  3. Functions
    - `get_pending_tickets_count` - Get count of unclaimed tickets for a user
    - `get_total_tickets_count` - Get total tickets count for a user
*/

-- Drop existing policies if they exist
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Users can read own tickets" ON tickets;
  DROP POLICY IF EXISTS "System can insert tickets" ON tickets;
  DROP POLICY IF EXISTS "Admins can update tickets" ON tickets;
EXCEPTION
  WHEN undefined_object THEN NULL;
END $$;

-- Create tickets table if it doesn't exist
CREATE TABLE IF NOT EXISTS tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  value numeric NOT NULL,
  created_at timestamptz DEFAULT now(),
  claimed boolean DEFAULT false,
  claimed_at timestamptz,
  CONSTRAINT tickets_value_check CHECK (value > 0)
);

-- Enable RLS
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

-- Add RLS policies
CREATE POLICY "Users can read own tickets" 
  ON tickets
  FOR SELECT 
  TO authenticated 
  USING (user_id = auth.uid() OR is_admin(auth.uid()));

CREATE POLICY "System can insert tickets"
  ON tickets
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Admins can update tickets"
  ON tickets
  FOR UPDATE
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

-- Create function to get pending tickets count
CREATE OR REPLACE FUNCTION get_pending_tickets_count(user_uuid uuid)
RETURNS integer AS $$
BEGIN
  RETURN COALESCE(
    (SELECT COUNT(*)
     FROM tickets
     WHERE user_id = user_uuid 
     AND value = 1000
     AND claimed = false),
    0
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get total tickets count
CREATE OR REPLACE FUNCTION get_total_tickets_count(user_uuid uuid)
RETURNS integer AS $$
BEGIN
  RETURN COALESCE(
    (SELECT COUNT(*)
     FROM tickets
     WHERE user_id = user_uuid 
     AND value = 1000),
    0
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Convert existing R$1,000 prizes to tickets
INSERT INTO tickets (user_id, value, created_at, claimed, claimed_at)
SELECT 
  user_id,
  value,
  created_at,
  claimed,
  claimed_at
FROM prizes 
WHERE value = 1000
ON CONFLICT DO NOTHING;