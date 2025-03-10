-- Criação da tabela de permissões de usuários
CREATE TABLE IF NOT EXISTS public.user_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  permission TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, permission)
);

-- Políticas RLS para a tabela user_permissions
ALTER TABLE public.user_permissions ENABLE ROW LEVEL SECURITY;

-- Apenas admins podem gerenciar permissões
CREATE POLICY "Admins can manage permissions" 
ON public.user_permissions 
FOR ALL 
TO authenticated 
USING (auth.uid() IN (SELECT id FROM public.admin_users));

-- Usuários podem ler suas próprias permissões
CREATE POLICY "Users can read own permissions" 
ON public.user_permissions 
FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

-- Índice para melhorar performance de consultas
CREATE INDEX idx_user_permissions_user_id ON public.user_permissions(user_id);

-- Função para verificar se um usuário tem uma permissão específica
CREATE OR REPLACE FUNCTION public.has_permission(user_uuid UUID, required_permission TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  is_admin BOOLEAN;
  has_perm BOOLEAN;
BEGIN
  -- Verificar se o usuário é admin
  SELECT EXISTS(SELECT 1 FROM public.admin_users WHERE id = user_uuid) INTO is_admin;
  
  IF is_admin THEN
    RETURN TRUE;
  END IF;
  
  -- Verificar permissão específica
  SELECT EXISTS(
    SELECT 1 FROM public.user_permissions 
    WHERE user_id = user_uuid AND permission = required_permission
  ) INTO has_perm;
  
  RETURN has_perm;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para atualizar o campo updated_at
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_permissions_timestamp
BEFORE UPDATE ON public.user_permissions
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Políticas RLS mais restritivas para outras tabelas

-- Política para user_missions
DROP POLICY IF EXISTS "Users can update own missions" ON public.user_missions;
CREATE POLICY "Users can update own missions" 
ON public.user_missions 
FOR UPDATE 
TO authenticated 
USING (
  auth.uid() = user_id OR 
  (auth.uid() IN (SELECT id FROM public.admin_users))
);

-- Política para user_points
DROP POLICY IF EXISTS "Users can select own points" ON public.user_points;
CREATE POLICY "Users can select own points" 
ON public.user_points 
FOR SELECT 
TO authenticated 
USING (
  auth.uid() = user_id OR 
  (auth.uid() IN (SELECT id FROM public.admin_users))
);

-- Configuração de CORS para permitir apenas origens confiáveis
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', false);

UPDATE storage.buckets
SET cors_origins = ARRAY['https://sistema-sorteio.vercel.app', 'http://localhost:5173']
WHERE id = 'avatars';
