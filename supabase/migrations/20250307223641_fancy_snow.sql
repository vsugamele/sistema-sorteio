/*
  # Create admin users view

  1. New View
    - `admin_users_view`: Shows information about admin users
      - `id` (uuid)
      - `email` (text)
      - `name` (text)
      - `phone` (text)
      - `created_at` (timestamp)

  2. Security
    - View is secured through the is_admin() function check in the view definition
*/

-- Create view to show admin users information with built-in security check
CREATE OR REPLACE VIEW admin_users_view AS
SELECT 
  au.id,
  au.email,
  au.raw_user_meta_data->>'name' as name,
  au.raw_user_meta_data->>'phone' as phone,
  au.created_at
FROM auth.users au
JOIN users u ON u.id = au.id
WHERE 
  u.is_admin = true 
  AND (is_admin(auth.uid()) OR auth.uid() = au.id)
ORDER BY au.created_at DESC;