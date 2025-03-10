/*
  # Integração do Sistema de Pontos das Missões

  1. Novas Tabelas
    - `mission_points_transactions`: Registra todas as transações de pontos
    - `mission_points_balance`: Mantém o saldo atual de pontos por usuário
    
  2. Funções
    - Função para calcular saldo
    - Trigger para atualizar saldo
    - Função para validar transações
    
  3. Índices e Constraints
    - Índices para performance
    - Constraints para integridade
*/

-- Create transaction types enum
CREATE TYPE point_transaction_type AS ENUM (
  'mission_completed',
  'mission_revoked',
  'points_expired',
  'points_adjusted'
);

-- Create points transactions table
CREATE TABLE mission_points_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  mission_id uuid REFERENCES social_missions(id),
  amount integer NOT NULL,
  type point_transaction_type NOT NULL,
  status mission_status NOT NULL,
  reference_id uuid, -- ID da missão ou outro documento relacionado
  metadata jsonb,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id) NOT NULL,
  description text
);

-- Create points balance table
CREATE TABLE mission_points_balance (
  user_id uuid REFERENCES auth.users(id) PRIMARY KEY,
  total_points integer NOT NULL DEFAULT 0,
  pending_points integer NOT NULL DEFAULT 0,
  last_updated_at timestamptz DEFAULT now(),
  CHECK (total_points >= 0),
  CHECK (pending_points >= 0)
);

-- Enable RLS
ALTER TABLE mission_points_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE mission_points_balance ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own transactions"
  ON mission_points_transactions
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    is_admin(auth.uid())
  );

CREATE POLICY "Users can view own balance"
  ON mission_points_balance
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    is_admin(auth.uid())
  );

-- Create function to validate transaction
CREATE OR REPLACE FUNCTION validate_mission_points_transaction()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Validate amount
  IF NEW.amount = 0 THEN
    RAISE EXCEPTION 'Transaction amount cannot be zero';
  END IF;

  -- Validate reference exists
  IF NEW.mission_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM social_missions WHERE id = NEW.mission_id
  ) THEN
    RAISE EXCEPTION 'Invalid mission reference';
  END IF;

  -- Set created_by if not provided
  IF NEW.created_by IS NULL THEN
    NEW.created_by := auth.uid();
  END IF;

  RETURN NEW;
END;
$$;

-- Create trigger for transaction validation
CREATE TRIGGER validate_mission_points_transaction_trigger
  BEFORE INSERT ON mission_points_transactions
  FOR EACH ROW
  EXECUTE FUNCTION validate_mission_points_transaction();

-- Create function to update balance
CREATE OR REPLACE FUNCTION update_mission_points_balance()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Insert or update balance
  INSERT INTO mission_points_balance (user_id, total_points, pending_points, last_updated_at)
  VALUES (
    NEW.user_id,
    CASE 
      WHEN NEW.status = 'approved' THEN NEW.amount
      ELSE 0
    END,
    CASE 
      WHEN NEW.status = 'pending' OR NEW.status = 'submitted' THEN NEW.amount
      ELSE 0
    END,
    now()
  )
  ON CONFLICT (user_id) DO UPDATE
  SET 
    total_points = CASE 
      WHEN NEW.status = 'approved' 
      THEN mission_points_balance.total_points + NEW.amount
      ELSE mission_points_balance.total_points
    END,
    pending_points = CASE 
      WHEN NEW.status = 'pending' OR NEW.status = 'submitted'
      THEN mission_points_balance.pending_points + NEW.amount
      ELSE mission_points_balance.pending_points
    END,
    last_updated_at = now();

  RETURN NEW;
END;
$$;

-- Create trigger for balance updates
CREATE TRIGGER update_mission_points_balance_trigger
  AFTER INSERT ON mission_points_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_mission_points_balance();

-- Create indexes
CREATE INDEX idx_mission_points_transactions_user ON mission_points_transactions(user_id);
CREATE INDEX idx_mission_points_transactions_mission ON mission_points_transactions(mission_id);
CREATE INDEX idx_mission_points_transactions_created_at ON mission_points_transactions(created_at);
CREATE INDEX idx_mission_points_transactions_type ON mission_points_transactions(type);
CREATE INDEX idx_mission_points_transactions_status ON mission_points_transactions(status);

-- Drop existing function if exists
DROP FUNCTION IF EXISTS get_user_points(uuid);

-- Create function to get user points
CREATE FUNCTION get_user_points(user_uuid uuid)
RETURNS TABLE (
  total_points integer,
  pending_points integer
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT total_points, pending_points
  FROM mission_points_balance
  WHERE user_id = user_uuid;
$$;