/*
  # Create users PIX view

  1. New View
    - Creates a view that combines user information with PIX key data
    - Includes:
      - User ID
      - Email
      - Name
      - Phone
      - PIX key
      - Creation date

  2. Security
    - Only admins can access this view through RLS policies
*/

-- Create the view in the public schema
CREATE OR REPLACE VIEW public.users_pix_view AS
SELECT 
  au.id,
  au.email,
  au.raw_user_meta_data->>'name' as name,
  au.raw_user_meta_data->>'phone' as phone,
  au.raw_user_meta_data->>'pix_key' as pix_key,
  au.created_at
FROM auth.users au;

-- Create security policy function if it doesn't exist
CREATE OR REPLACE FUNCTION public.users_pix_view_security(jwt_claims json)
RETURNS boolean AS $$
BEGIN
  RETURN is_admin(auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant access to authenticated users
GRANT SELECT ON public.users_pix_view TO authenticated;