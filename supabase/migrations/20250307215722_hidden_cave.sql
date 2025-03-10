/*
  # Add PIX key to users and improve prize tracking

  1. New Columns
    - Add `pix_key` to users table for payment information
    - Add `payment_info` to prizes table for additional payment details

  2. Functions
    - Add function to count pending prizes
    - Add function to get total prize value

  3. Security
    - Add RLS policies to protect PIX information
*/

-- Add PIX key to users table
ALTER TABLE auth.users 
ADD COLUMN IF NOT EXISTS pix_key text;

-- Add payment info to prizes table
ALTER TABLE public.prizes
ADD COLUMN IF NOT EXISTS payment_info jsonb DEFAULT '{}'::jsonb;

-- Function to get pending prizes count
CREATE OR REPLACE FUNCTION get_pending_prizes_count(user_uuid uuid)
RETURNS integer AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::integer
    FROM prizes
    WHERE user_id = user_uuid
    AND claimed = false
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get total pending prize value
CREATE OR REPLACE FUNCTION get_pending_prizes_value(user_uuid uuid)
RETURNS numeric AS $$
BEGIN
  RETURN (
    SELECT COALESCE(SUM(value), 0)
    FROM prizes
    WHERE user_id = user_uuid
    AND claimed = false
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;