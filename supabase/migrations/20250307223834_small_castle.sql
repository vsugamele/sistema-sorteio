/*
  # Add admin check function

  1. New Function
    - `is_admin`: Function to check if a user is an admin
      - Takes a user_id as parameter
      - Returns boolean

  2. Security
    - Function is accessible to authenticated users
*/

CREATE OR REPLACE FUNCTION is_admin(user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 
    FROM users 
    WHERE id = user_id AND is_admin = true
  );
$$;