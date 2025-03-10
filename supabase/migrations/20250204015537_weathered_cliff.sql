/*
  # Optimize Deposits Table Performance and Policies

  1. Performance Improvements
    - Add indexes for better query performance
    - Optimize points calculation and updates

  2. Policy Updates
    - Update deposit access policies
    - Ensure proper user and admin access control

  3. Points Management
    - Add automatic points calculation
    - Implement trigger for points updates
*/

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_deposits_user_id_status ON deposits(user_id, status);
CREATE INDEX IF NOT EXISTS idx_deposits_points ON deposits(points) WHERE status = 'approved';

-- Remover todas as políticas existentes de forma segura
DO $$ 
BEGIN
  -- Remove existing policies if they exist
  DROP POLICY IF EXISTS "Deposits access policy" ON deposits;
  DROP POLICY IF EXISTS "Users can insert own deposits" ON deposits;
  DROP POLICY IF EXISTS "Admins can update deposit status" ON deposits;
  DROP POLICY IF EXISTS "Users can read own deposits" ON deposits;
  DROP POLICY IF EXISTS "Users can insert own deposits" ON deposits;
  DROP POLICY IF EXISTS "Admins can update deposits" ON deposits;
END $$;

-- Criar novas políticas otimizadas
DO $$ 
BEGIN
  -- Create new policies only if they don't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'deposits' 
    AND policyname = 'Users can read own deposits'
  ) THEN
    CREATE POLICY "Users can read own deposits"
    ON deposits
    FOR SELECT
    TO authenticated
    USING (
      user_id = auth.uid() OR
      is_admin(auth.uid())
    );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'deposits' 
    AND policyname = 'Users can insert own deposits'
  ) THEN
    CREATE POLICY "Users can insert own deposits"
    ON deposits
    FOR INSERT
    TO authenticated
    WITH CHECK (
      user_id = auth.uid()
    );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'deposits' 
    AND policyname = 'Admins can update deposits'
  ) THEN
    CREATE POLICY "Admins can update deposits"
    ON deposits
    FOR UPDATE
    TO authenticated
    USING (is_admin(auth.uid()))
    WITH CHECK (is_admin(auth.uid()));
  END IF;
END $$;

-- Função para calcular pontos baseado no valor do depósito
CREATE OR REPLACE FUNCTION calculate_deposit_points(amount numeric)
RETURNS integer
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN floor(amount)::integer;
END;
$$;

-- Trigger para atualizar pontos automaticamente
CREATE OR REPLACE FUNCTION update_deposit_points()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
    NEW.points = calculate_deposit_points(NEW.amount);
  ELSIF NEW.status != 'approved' THEN
    NEW.points = 0;
  END IF;
  RETURN NEW;
END;
$$;

-- Remover trigger existente se houver
DROP TRIGGER IF EXISTS deposit_points_trigger ON deposits;

-- Criar novo trigger
CREATE TRIGGER deposit_points_trigger
  BEFORE UPDATE OF status ON deposits
  FOR EACH ROW
  EXECUTE FUNCTION update_deposit_points();