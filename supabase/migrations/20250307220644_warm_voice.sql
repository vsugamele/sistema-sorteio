/*
  # Add Tickets Support and Convert R$1000 Prizes to Tickets

  1. Changes
    - Adds tickets table to track lottery tickets
    - Converts existing R$1000 prizes to tickets
    - Adds functions to count tickets
    
  2. Security
    - Enables RLS on tickets table
    - Adds policies for ticket access control
*/

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read own tickets" ON tickets;
DROP POLICY IF EXISTS "System can insert tickets" ON tickets;

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

-- Convert existing R$1000 prizes to tickets
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