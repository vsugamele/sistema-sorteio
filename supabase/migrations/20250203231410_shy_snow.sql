/*
  # Fix prizes table and schema

  1. New Tables
    - `prizes` table for storing user prizes
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `value` (decimal)
      - `created_at` (timestamptz)
      - `claimed` (boolean)
      - `claimed_at` (timestamptz)

  2. Security
    - Enable RLS on prizes table
    - Add policies for users and admins
*/

-- Create prizes table
CREATE TABLE IF NOT EXISTS prizes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  value decimal NOT NULL,
  created_at timestamptz DEFAULT now(),
  claimed boolean DEFAULT false,
  claimed_at timestamptz
);

-- Enable RLS
ALTER TABLE prizes ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can read own prizes"
ON prizes
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR
  is_admin(auth.uid())
);

CREATE POLICY "Users can insert prizes"
ON prizes
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid()
);

CREATE POLICY "Admins can update prizes"
ON prizes
FOR UPDATE
TO authenticated
USING (is_admin(auth.uid()))
WITH CHECK (is_admin(auth.uid()));