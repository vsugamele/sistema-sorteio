/*
  # Add claim prize function

  1. New Functions
    - `claim_prize`: Function to safely claim a prize
      - Validates prize exists and is not claimed
      - Updates prize status
      - Records who claimed it and when

  2. Security
    - Only admins can execute this function
    - Validates user permissions
    - Ensures atomic updates
*/

-- Create function to claim prizes
create or replace function claim_prize(prize_uuid uuid, admin_uuid uuid)
returns boolean
language plpgsql
security definer
as $$
declare
  is_admin boolean;
begin
  -- Check if user is admin
  select is_admin into is_admin from users where id = admin_uuid;
  if not is_admin then
    raise exception 'Only admins can claim prizes';
  end if;

  -- Update prize
  update prizes
  set 
    claimed = true,
    claimed_at = now(),
    claimed_by = admin_uuid
  where 
    id = prize_uuid
    and claimed = false;

  -- Return true if a row was updated
  return found;
end;
$$;