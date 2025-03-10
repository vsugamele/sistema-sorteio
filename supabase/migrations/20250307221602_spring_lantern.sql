/*
  # Fix tickets calculation

  1. Changes
    - Update function to calculate pending tickets per user
    - Only count tickets with value = 1000
    - Add proper type filtering
    - Fix counting logic to avoid duplicates

  2. Functions
    - get_pending_tickets_count: Count of unclaimed tickets per user
    - get_total_tickets_count: Total tickets per user
*/

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS get_pending_tickets_count(uuid);
DROP FUNCTION IF EXISTS get_total_tickets_count(uuid);

-- Create function to get pending tickets count
CREATE OR REPLACE FUNCTION get_pending_tickets_count(user_uuid uuid)
RETURNS integer AS $$
BEGIN
  RETURN COALESCE(
    (SELECT COUNT(*)
     FROM prizes p
     WHERE p.user_id = user_uuid 
     AND p.value = 1000
     AND p.type = 'ticket'
     AND p.claimed = false),
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
     FROM prizes p
     WHERE p.user_id = user_uuid 
     AND p.value = 1000
     AND p.type = 'ticket'),
    0
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;