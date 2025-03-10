/*
  # Update Prize Handling for Tickets

  1. Changes
    - Updates unclaimed prizes to be properly categorized as tickets if value >= 300
    - Updates roulette prize configuration for future prizes
    - Creates/updates functions to correctly count pending tickets

  2. Security
    - Maintains existing RLS policies
    - No changes to access control
*/

-- Update only unclaimed prizes to be tickets if value >= 300
UPDATE prizes
SET type = 'ticket'
WHERE value >= 300 
AND claimed = false;

-- Update roulette prizes configuration for future prizes
UPDATE roulette_prizes
SET type = 'ticket'
WHERE value >= 300;

-- Create or replace function to count pending tickets
CREATE OR REPLACE FUNCTION get_pending_tickets_count(user_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::integer
    FROM prizes
    WHERE user_id = user_uuid 
    AND claimed = false
    AND type = 'ticket'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create or replace function to count total tickets
CREATE OR REPLACE FUNCTION get_total_tickets_count(user_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::integer
    FROM prizes
    WHERE user_id = user_uuid
    AND type = 'ticket'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;