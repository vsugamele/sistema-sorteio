import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error('Supabase URL and Anon Key são necessários.');
}

// Configuração simplificada do cliente Supabase para garantir compatibilidade
export const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  }
});

// Função para verificar permissões do usuário
export async function checkUserPermissions(requiredPermission: string): Promise<boolean> {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return false;
    
    // Verificar se o usuário é admin
    const { data: adminData } = await supabase
      .from('admin_users')
      .select('id')
      .eq('id', user.id)
      .single();
      
    if (adminData) return true; // Admins têm todas as permissões
    
    // Verificar permissões específicas
    const { data: permissions } = await supabase
      .from('user_permissions')
      .select('permission')
      .eq('user_id', user.id);
      
    return permissions?.some(p => p.permission === requiredPermission) || false;
  } catch (error) {
    console.error('Erro ao verificar permissões:', error);
    return false;
  }
}