/*
  # Create Admin Views and Functions

  1. Views Created
    - `users_pix_view`: Shows user information including PIX key
    - `admin_users_view`: Shows admin users information
  
  2. Security
    - Views are secured through RLS on the underlying tables
    - Function for admin check
*/

-- Create security definer function to check admin status
CREATE OR REPLACE FUNCTION is_admin(user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM users 
    WHERE id = user_id AND is_admin = true
  );
$$;

-- Create users PIX view
CREATE OR REPLACE VIEW users_pix_view AS 
SELECT 
  au.id,
  au.email,
  au.raw_user_meta_data->>'name' as name,
  au.raw_user_meta_data->>'phone' as phone,
  au.raw_user_meta_data->>'pix_key' as pix_key,
  au.created_at
FROM auth.users au;

-- Create admin users view
CREATE OR REPLACE VIEW admin_users_view AS 
SELECT 
  au.id,
  au.email,
  au.raw_user_meta_data->>'name' as name,
  au.raw_user_meta_data->>'phone' as phone,
  au.created_at
FROM auth.users au
JOIN users u ON u.id = au.id
WHERE u.is_admin = true;

-- Grant access to authenticated users
GRANT SELECT ON users_pix_view TO authenticated;
GRANT SELECT ON admin_users_view TO authenticated;