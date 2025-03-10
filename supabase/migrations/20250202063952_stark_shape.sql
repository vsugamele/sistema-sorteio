/*
  # Create deposits table

  1. New Tables
    - `deposits`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key to auth.users)
      - `amount` (decimal, deposit amount)
      - `platform` (text, platform name)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on `deposits` table
    - Add policy for authenticated users to read their own deposits
    - Add policy for authenticated users to insert their own deposits
*/

CREATE TABLE IF NOT EXISTS deposits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  amount decimal NOT NULL CHECK (amount > 0),
  platform text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE deposits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own deposits"
  ON deposits
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own deposits"
  ON deposits
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);