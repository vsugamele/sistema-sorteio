-- Script para ajustar as políticas de segurança do Supabase
-- Este script relaxa algumas restrições para facilitar o acesso durante o desenvolvimento

-- Permitir que todos os usuários autenticados possam ler dados básicos
CREATE POLICY IF NOT EXISTS "Authenticated users can read basic data" 
ON user_missions 
FOR SELECT 
TO authenticated 
USING (true);

-- Ajustar política de admin para ser mais permissiva
CREATE OR REPLACE POLICY "Admins can update any mission" 
ON user_missions 
FOR UPDATE 
TO authenticated 
USING (
  -- Permite que qualquer usuário autenticado atualize missões durante o desenvolvimento
  -- Em produção, você pode querer restringir isso apenas para administradores
  -- usando: auth.uid() IN (SELECT id FROM public.admin_users)
  true
);

-- Permitir que usuários autenticados possam inserir dados
CREATE OR REPLACE POLICY "Users can submit missions" 
ON user_missions 
FOR INSERT 
TO authenticated 
WITH CHECK (true);

-- Configuração de CORS mais permissiva para desenvolvimento
UPDATE storage.buckets
SET cors_origins = ARRAY['*']
WHERE id = 'avatars';

-- Adicionar todos os usuários atuais como administradores para facilitar o teste
INSERT INTO public.admin_users (id)
SELECT id FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- Função para verificar se um usuário é administrador (retorna sempre true durante desenvolvimento)
CREATE OR REPLACE FUNCTION public.is_admin(user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Durante o desenvolvimento, todos os usuários são considerados administradores
  RETURN true;
  
  -- Em produção, você pode querer usar esta lógica:
  -- RETURN EXISTS (SELECT 1 FROM public.admin_users WHERE id = user_id);
END;
$$;

-- Função para verificar permissões (retorna sempre true durante desenvolvimento)
CREATE OR REPLACE FUNCTION public.has_permission(user_id uuid, permission_name text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Durante o desenvolvimento, todas as permissões são concedidas
  RETURN true;
  
  -- Em produção, você pode querer usar esta lógica:
  -- RETURN EXISTS (
  --   SELECT 1 FROM public.user_permissions 
  --   WHERE user_id = $1 AND permission = $2
  -- ) OR EXISTS (
  --   SELECT 1 FROM public.admin_users WHERE id = $1
  -- );
END;
$$;
