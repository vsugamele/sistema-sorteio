/*
  # Add Prize Type Support and Convert R$1000 Prizes to Tickets

  1. Changes
    - Adds type column to prizes table
    - Updates existing R$1000 prizes to be tickets
    - Adds functions to count tickets
    
  2. Security
    - Maintains existing RLS policies
    - No changes to access control needed
*/

-- Add type column to prizes table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'prizes' AND column_name = 'type'
  ) THEN
    ALTER TABLE prizes ADD COLUMN type text DEFAULT 'money';
  END IF;
END $$;

-- Create function to get pending tickets count
CREATE OR REPLACE FUNCTION get_pending_tickets_count(user_uuid uuid)
RETURNS integer AS $$
BEGIN
  RETURN COALESCE(
    (SELECT COUNT(*)
     FROM prizes
     WHERE user_id = user_uuid 
     AND value = 1000
     AND type = 'ticket'
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
     FROM prizes
     WHERE user_id = user_uuid 
     AND value = 1000
     AND type = 'ticket'),
    0
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update existing R$1000 prizes to be tickets
UPDATE prizes 
SET type = 'ticket'
WHERE value = 1000;