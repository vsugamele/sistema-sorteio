# Guia de Segurança para o Sistema de Sorteio

Este documento descreve as melhorias de segurança implementadas e as configurações recomendadas para proteger o sistema contra acessos não autorizados.

## Melhorias Implementadas

### 1. Armazenamento Seguro de Tokens

Substituímos o armazenamento de tokens JWT no localStorage por cookies HttpOnly com flags de segurança:

- **HttpOnly**: Impede acesso via JavaScript, protegendo contra ataques XSS
- **Secure**: Garante que o cookie só seja enviado em conexões HTTPS
- **SameSite=Strict**: Previne envio do cookie em requisições cross-site, protegendo contra CSRF

### 2. Proteção CSRF

Implementamos tokens CSRF para proteger contra ataques de falsificação de requisição:

- Geramos um token aleatório armazenado no cliente
- Enviamos este token em todas as requisições ao Supabase
- O servidor valida o token antes de processar a requisição

### 3. Políticas RLS Aprimoradas

Configuramos políticas Row Level Security (RLS) mais restritivas no Supabase:

```sql
-- Política para permitir que administradores atualizem missões de qualquer usuário
CREATE POLICY "Admins can update any mission" 
ON user_missions 
FOR UPDATE 
TO authenticated 
USING (auth.uid() IN (SELECT id FROM public.admin_users));

-- Política para permitir que usuários leiam apenas suas próprias missões
CREATE POLICY "Users can read own missions" 
ON user_missions 
FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);
```

### 4. Verificação de Permissões no Cliente

Implementamos um sistema de verificação de permissões no lado do cliente:

- Componente `ProtectedRoute` que verifica autenticação e permissões
- Função `checkUserPermissions` para verificar permissões específicas
- Redirecionamento para página de acesso negado quando necessário

### 5. Logout Automático por Inatividade

Adicionamos um sistema de logout automático após período de inatividade:

- Monitora eventos de interação do usuário (cliques, teclas, scroll)
- Reinicia o temporizador a cada interação
- Realiza logout automático após 30 minutos de inatividade

### 6. Configuração de CORS

Configuramos CORS para permitir apenas origens confiáveis:

```sql
UPDATE storage.buckets
SET cors_origins = ARRAY['https://sistema-sorteio.vercel.app', 'http://localhost:5173']
WHERE id = 'avatars';
```

## Recomendações Adicionais

1. **Atualize regularmente as dependências** para corrigir vulnerabilidades conhecidas:
   ```bash
   npm audit fix
   ```

2. **Ative autenticação de dois fatores (2FA)** no Supabase para contas de administrador

3. **Monitore logs de acesso** para detectar atividades suspeitas

4. **Realize backups regulares** do banco de dados

5. **Implemente rate limiting** para prevenir ataques de força bruta

## Configuração no Supabase

Para aplicar as políticas RLS e outras configurações de segurança no Supabase:

1. Acesse o painel de administração do Supabase
2. Navegue até "SQL Editor"
3. Execute o script SQL contido em `supabase/migrations/20250310_user_permissions.sql`

## Teste de Segurança

Após implementar estas melhorias, recomendamos realizar os seguintes testes:

1. Tente acessar rotas protegidas sem autenticação
2. Tente acessar rotas de administrador com uma conta comum
3. Verifique se o token JWT não está acessível via JavaScript
4. Teste o logout automático por inatividade
5. Verifique se as políticas RLS estão funcionando corretamente

---

**Importante**: Mantenha este documento atualizado conforme novas medidas de segurança forem implementadas.
