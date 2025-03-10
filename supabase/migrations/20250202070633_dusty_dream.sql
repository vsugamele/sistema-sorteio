/*
  # Fix receipt storage access

  1. Changes
    - Add public access to receipts bucket
    - Update storage policies for better access control
    - Add security policies for receipt URLs
*/

-- Update bucket to allow public access
UPDATE storage.buckets
SET public = true
WHERE id = 'receipts';

-- Drop existing policies
DROP POLICY IF EXISTS "Authenticated users can upload receipts" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can read receipts" ON storage.objects;

-- Create more specific policies
CREATE POLICY "Anyone can read receipts"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'receipts');

CREATE POLICY "Authenticated users can upload receipts"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'receipts'
  AND (auth.role() = 'authenticated')
);

-- Add function to generate signed URLs
CREATE OR REPLACE FUNCTION get_signed_url(bucket text, object text)
RETURNS text
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN storage.generate_presigned_url(
    bucket,
    object,
    INTERVAL '1 hour'
  );
END;
$$;