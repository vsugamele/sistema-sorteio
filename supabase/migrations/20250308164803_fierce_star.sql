/*
  # Add Reset Tickets Function

  1. New Function
    - `reset_all_tickets`: Resets all tickets by marking them as claimed

  2. Security
    - Function can only be executed by admin users
*/

CREATE OR REPLACE FUNCTION reset_all_tickets()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if user is admin
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Only administrators can reset tickets';
  END IF;

  -- Update all unclaimed tickets to claimed
  UPDATE prizes
  SET 
    claimed = true,
    claimed_at = NOW(),
    claimed_by = auth.uid()
  WHERE 
    claimed = false AND
    type = 'ticket';
END;
$$;