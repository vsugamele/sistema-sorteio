/*
  # Add receipt URL to deposits table

  1. Changes
    - Add receipt_url column to deposits table
    - Create storage bucket for receipts
    - Add storage policies for receipts bucket

  2. Security
    - Enable RLS on storage bucket
    - Add policies for authenticated users to upload and read receipts
*/

-- Add receipt_url column to deposits table
ALTER TABLE deposits
ADD COLUMN receipt_url text;

-- Create storage bucket for receipts if it doesn't exist
INSERT INTO storage.buckets (id, name)
VALUES ('receipts', 'receipts')
ON CONFLICT DO NOTHING;

-- Enable RLS on storage bucket
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Create policy for authenticated users to upload receipts
CREATE POLICY "Authenticated users can upload receipts"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'receipts'
  AND auth.role() = 'authenticated'
);

-- Create policy for authenticated users to read receipts
CREATE POLICY "Authenticated users can read receipts"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'receipts'
  AND auth.role() = 'authenticated'
);