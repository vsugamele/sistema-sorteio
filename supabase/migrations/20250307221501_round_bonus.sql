/*
  # Fix pending prizes calculation

  1. Changes
    - Update function to calculate pending prizes per user
    - Only count money prizes (not tickets)
    - Group by user to avoid duplicates
    - Add proper type filtering

  2. Functions
    - get_pending_prizes_count: Count of unclaimed money prizes per user
    - get_pending_prizes_value: Total value of unclaimed money prizes per user
*/

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS get_pending_prizes_count(uuid);
DROP FUNCTION IF EXISTS get_pending_prizes_value(uuid);

-- Create function to get pending prizes count
CREATE OR REPLACE FUNCTION get_pending_prizes_count(user_uuid uuid)
RETURNS integer AS $$
BEGIN
  RETURN (
    SELECT COUNT(DISTINCT id)
    FROM prizes p
    WHERE p.user_id = user_uuid 
    AND p.claimed = false
    AND p.type = 'money'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get pending prizes total value
CREATE OR REPLACE FUNCTION get_pending_prizes_value(user_uuid uuid)
RETURNS numeric AS $$
BEGIN
  RETURN COALESCE(
    (SELECT SUM(value)
     FROM prizes p
     WHERE p.user_id = user_uuid 
     AND p.claimed = false
     AND p.type = 'money'
    ), 0
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;