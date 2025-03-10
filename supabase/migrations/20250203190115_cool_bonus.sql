/*
  # Adicionar sistema de tickets

  1. Nova Tabela
    - `tickets`
      - `id` (uuid, primary key)
      - `user_id` (uuid, referência para auth.users)
      - `value` (decimal, valor do ticket)
      - `created_at` (timestamp)
      - `claimed` (boolean, indica se o ticket já foi resgatado)
      - `claimed_at` (timestamp, quando o ticket foi resgatado)

  2. Security
    - Enable RLS na tabela tickets
    - Adicionar políticas para usuários e admins
*/

-- Criar tabela de tickets
CREATE TABLE tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  value decimal NOT NULL,
  created_at timestamptz DEFAULT now(),
  claimed boolean DEFAULT false,
  claimed_at timestamptz
);

-- Habilitar RLS
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

-- Políticas de acesso
CREATE POLICY "Users can read own tickets"
  ON tickets
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND is_admin = true
    )
  );

CREATE POLICY "System can insert tickets"
  ON tickets
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Admins can update tickets"
  ON tickets
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