/*
  # Add User Messages System

  1. New Table
    - `user_messages`
      - `id` (uuid, primary key)
      - `title` (text, required)
      - `content` (text, required)
      - `user_id` (uuid, optional - null means message is for all users)
      - `created_at` (timestamp)
      - `created_by` (uuid, references admin user)
      - `read_at` (timestamp, null until user reads message)
      - `expires_at` (timestamp, optional)

  2. Security
    - Enable RLS
    - Admins can manage all messages
    - Users can only read their own messages or global messages
    - Messages are automatically filtered by expiration date

  3. Changes
    - Creates new table for user messages
    - Adds RLS policies for security
    - Adds constraint to ensure expiration date is after creation date
*/

-- Create messages table
CREATE TABLE IF NOT EXISTS user_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  content text NOT NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  created_by uuid NOT NULL REFERENCES auth.users(id),
  read_at timestamptz,
  expires_at timestamptz,
  CONSTRAINT valid_expiration CHECK (expires_at > created_at)
);

-- Enable RLS
ALTER TABLE user_messages ENABLE ROW LEVEL SECURITY;

-- Admin policy with unique name
CREATE POLICY "admin_manage_messages" ON user_messages
  FOR ALL
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

-- User read policy with unique name
CREATE POLICY "user_read_messages" ON user_messages
  FOR SELECT
  TO authenticated
  USING (
    (user_id = auth.uid() OR user_id IS NULL)
    AND (expires_at IS NULL OR expires_at > now())
  );