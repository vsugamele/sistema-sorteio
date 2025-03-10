/*
  # Add functions to calculate pending prizes

  1. Functions
    - `get_pending_prizes_count` - Get count of unclaimed money prizes for a user
    - `get_pending_prizes_value` - Get total value of unclaimed money prizes for a user

  2. Changes
    - Only considers prizes of type 'money'
    - Excludes tickets from calculations
*/

-- Create function to get pending prizes count
CREATE OR REPLACE FUNCTION get_pending_prizes_count(user_uuid uuid)
RETURNS integer AS $$
BEGIN
  RETURN COALESCE(
    (SELECT COUNT(*)
     FROM prizes
     WHERE user_id = user_uuid 
     AND claimed = false
     AND type = 'money'),
    0
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get pending prizes total value
CREATE OR REPLACE FUNCTION get_pending_prizes_value(user_uuid uuid)
RETURNS numeric AS $$
BEGIN
  RETURN COALESCE(
    (SELECT SUM(value)
     FROM prizes
     WHERE user_id = user_uuid 
     AND claimed = false
     AND type = 'money'),
    0
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;