/*
  # Add view for users PIX information
  
  1. New View
    - `users_pix_view`
      - Shows user email, name, phone and PIX key
      - Only accessible by admins
      - Includes only users with PIX keys set
  
  2. Security
    - Grant select permission only to authenticated users
    - View checks for admin access in the query itself
*/

-- Create view to show users PIX information
CREATE OR REPLACE VIEW users_pix_view AS
SELECT 
  au.id,
  au.email,
  au.raw_user_meta_data->>'name' as name,
  au.raw_user_meta_data->>'phone' as phone,
  au.raw_user_meta_data->>'pix_key' as pix_key,
  au.created_at
FROM auth.users au
WHERE 
  au.raw_user_meta_data->>'pix_key' IS NOT NULL
  AND (
    -- Only show results if the requesting user is an admin
    EXISTS (
      SELECT 1 
      FROM users u 
      WHERE u.id = auth.uid() 
      AND u.is_admin = true
    )
  )
ORDER BY au.created_at DESC;

-- Grant access to authenticated users
GRANT SELECT ON users_pix_view TO authenticated;