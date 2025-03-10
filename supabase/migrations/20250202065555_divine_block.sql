/*
  # Add deposit status management
  
  1. Changes
    - Add status column to deposits table
    - Add approved_at and approved_by columns
    - Add policies for admin approval
  
  2. Security
    - Only admins can approve/reject deposits
    - Users can see their deposit status
*/

-- Add status enum type
CREATE TYPE deposit_status AS ENUM ('pending', 'approved', 'rejected');

-- Add status management columns
ALTER TABLE deposits
ADD COLUMN status deposit_status NOT NULL DEFAULT 'pending',
ADD COLUMN approved_at timestamptz,
ADD COLUMN approved_by uuid REFERENCES auth.users(id),
ADD COLUMN rejection_reason text;

-- Create policy for admins to update deposit status
CREATE POLICY "Admins can update deposit status"
ON deposits
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND is_admin = true
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND is_admin = true
  )
);