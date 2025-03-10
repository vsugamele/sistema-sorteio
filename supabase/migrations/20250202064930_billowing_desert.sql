/*
  # Add admin role to users

  1. Changes
    - Add `is_admin` column to auth.users
    - Set vsugamele@gmail.com as admin
    - Add RLS policy for admin access

  2. Security
    - Only admins can view all deposits
    - Regular users can only view their own deposits
*/

-- Adiciona coluna is_admin aos usuários
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS is_admin boolean DEFAULT false;

-- Define o usuário específico como administrador
UPDATE auth.users 
SET is_admin = true 
WHERE email = 'vsugamele@gmail.com';

-- Atualiza a política de RLS para permitir que admins vejam todos os depósitos
DROP POLICY IF EXISTS "Users can read own deposits" ON deposits;

CREATE POLICY "Users can read deposits"
  ON deposits
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id 
    OR 
    (SELECT is_admin FROM auth.users WHERE id = auth.uid())
  );