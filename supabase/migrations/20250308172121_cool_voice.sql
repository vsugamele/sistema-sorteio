/*
  # Add User Messages System

  1. New Tables
    - `user_messages`
      - `id` (uuid, primary key)
      - `title` (text) - Message title
      - `content` (text) - Message content
      - `user_id` (uuid, nullable) - Specific user or null for all users
      - `created_at` (timestamp)
      - `created_by` (uuid) - Admin who created the message
      - `read_at` (timestamp, nullable) - When user read the message
      - `expires_at` (timestamp, nullable) - Optional expiration date

  2. Security
    - Enable RLS on `user_messages` table
    - Add policies for admins to manage messages
    - Add policies for users to read their messages

  3. Functions
    - Function to mark messages as read
*/

-- Drop existing policies and table if they exist
DROP POLICY IF EXISTS "Admins can manage all messages" ON user_messages;
DROP POLICY IF EXISTS "Users can read their messages" ON user_messages;
DROP TABLE IF EXISTS user_messages;

-- Create user messages table
CREATE TABLE IF NOT EXISTS user_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  content text NOT NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id) NOT NULL,
  read_at timestamptz,
  expires_at timestamptz,
  CONSTRAINT valid_expiration CHECK (expires_at > created_at)
);

-- Enable RLS
ALTER TABLE user_messages ENABLE ROW LEVEL SECURITY;

-- Policies for admins
CREATE POLICY "Admins can manage all messages"
  ON user_messages
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.is_admin = true
  ));

-- Policy for users to read their messages
CREATE POLICY "Users can read their messages"
  ON user_messages
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR 
    (user_id IS NULL AND (expires_at IS NULL OR expires_at > now()))
  );

-- Function to mark message as read
CREATE OR REPLACE FUNCTION mark_message_read(message_uuid uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE user_messages
  SET read_at = now()
  WHERE id = message_uuid
  AND (user_id = auth.uid() OR user_id IS NULL)
  AND read_at IS NULL;
END;
$$;