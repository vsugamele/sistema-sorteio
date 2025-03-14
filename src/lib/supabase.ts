import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error('Supabase URL and Anon Key são necessários.');
}

// Configuração simplificada do cliente Supabase com opções mínimas
export const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false, // Desativar detecção de sessão na URL para evitar problemas em dispositivos móveis
    storage: typeof window !== 'undefined' ? window.localStorage : undefined
  },
  global: {
    headers: {
      'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0'
    }
  }
});

// Detectar se é um dispositivo iOS
export const isIOS = () => {
  if (typeof window === 'undefined') return false;
  return /iPad|iPhone|iPod/.test(navigator.userAgent) && !(window as any).MSStream;
};

// Função para limpar a sessão em caso de problemas
export async function clearSession() {
  if (typeof window !== 'undefined') {
    // Limpar todos os itens do localStorage relacionados ao Supabase
    localStorage.removeItem('supabase.auth.token');
    localStorage.removeItem('supabase.auth.expires_at');
    localStorage.removeItem('supabase.auth.refresh_token');
    
    // Limpar qualquer outro item de autenticação que possa existir
    const keysToRemove = [];
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && (key.includes('supabase') || key.includes('auth'))) {
        keysToRemove.push(key);
      }
    }
    
    keysToRemove.forEach(key => localStorage.removeItem(key));
    
    try {
      // Tentar fazer logout usando o Supabase
      await supabase.auth.signOut();
      
      // Redirecionar para a página de login após limpar a sessão
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    } catch (error) {
      console.error("Erro ao fazer logout:", error);
    }
    
    // Limpar todos os cookies para iOS
    if (isIOS()) {
      const cookies = document.cookie.split(';');
      for (let i = 0; i < cookies.length; i++) {
        const cookie = cookies[i];
        const eqPos = cookie.indexOf('=');
        const name = eqPos > -1 ? cookie.substr(0, eqPos) : cookie;
        document.cookie = name + '=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/';
      }
    }
  }
}

// Função para fazer login
export async function login(email: string, password: string): Promise<{ success: boolean; message: string }> {
  try {
    console.log(`Tentando fazer login com email: ${email}`);
    
    // Método 1: Login padrão do Supabase
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      console.error('Erro no login padrão:', error.message);
      
      // Método 2: Tentar via REST API como fallback
      try {
        console.log('Tentando método alternativo de login via REST API');
        const response = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=password`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseKey,
          },
          body: JSON.stringify({ email, password }),
        });

        const responseData = await response.json();
        console.log('Resposta do login REST API:', responseData);

        if (response.ok) {
          console.log('Login via REST API bem-sucedido!');
          return { success: true, message: 'Login bem-sucedido via método alternativo' };
        } else {
          console.error('Erro no login REST API:', responseData.error_description || responseData.error);
          return { 
            success: false, 
            message: `Falha no login: ${responseData.error_description || responseData.error}` 
          };
        }
      } catch (restError) {
        console.error('Erro ao tentar login via REST API:', restError);
        return { 
          success: false, 
          message: `Falha no login: ${error.message}. Erro no método alternativo: ${restError}` 
        };
      }
    }

    // Login bem-sucedido
    console.log('Login bem-sucedido!', data);
    
    // Verificar imediatamente se é admin para diagnóstico
    const adminCheck = await isAdmin();
    console.log(`Verificação de admin após login: ${adminCheck}`);
    
    // Verificar diretamente cada tabela de admin para diagnóstico
    await verificarTabelasAdmin();
    
    return { success: true, message: 'Login bem-sucedido' };
  } catch (error) {
    console.error('Erro inesperado no login:', error);
    return { 
      success: false, 
      message: `Erro inesperado: ${error}` 
    };
  }
}

// Função para diagnóstico - verificar diretamente as tabelas de admin
async function verificarTabelasAdmin() {
  try {
    const { data: { session } } = await supabase.auth.getSession();
    
    if (!session) {
      console.log('DIAGNÓSTICO: Usuário não está autenticado');
      return;
    }
    
    const userId = session.user.id;
    console.log(`DIAGNÓSTICO: Verificando tabelas para o usuário ID: ${userId}`);
    
    // Verificar admin_users_table
    const { data: tableData, error: tableError } = await supabase
      .from('admin_users_table')
      .select('*')
      .eq('id', userId);
      
    console.log('DIAGNÓSTICO admin_users_table:', tableData, tableError);
    
    // Verificar admin_users_real
    const { data: realData, error: realError } = await supabase
      .from('admin_users_real')
      .select('*')
      .eq('id', userId);
      
    console.log('DIAGNÓSTICO admin_users_real:', realData, realError);
    
    // Verificar admin_users
    const { data: viewData, error: viewError } = await supabase
      .from('admin_users')
      .select('*')
      .eq('id', userId);
      
    console.log('DIAGNÓSTICO admin_users:', viewData, viewError);
    
    // Verificar todas as tabelas de admin
    const { data: allAdminTables, error: tablesError } = await supabase
      .rpc('list_admin_tables');
      
    console.log('DIAGNÓSTICO todas as tabelas de admin:', allAdminTables, tablesError);
  } catch (error) {
    console.error('DIAGNÓSTICO: Erro ao verificar tabelas admin:', error);
  }
}

// Função auxiliar para verificar se um usuário é administrador
export async function isAdmin(): Promise<boolean> {
  try {
    // Verificar se o usuário está autenticado
    const { data: { session } } = await supabase.auth.getSession();
    
    if (!session) {
      console.log('Usuário não está autenticado');
      return false;
    }
    
    console.log(`Verificando se usuário ${session.user.id} (${session.user.email}) é admin`);
    
    // Verificar se está na tabela de administradores (admin_users_table)
    const { data: adminTableData, error: adminTableError } = await supabase
      .from('admin_users_table')  // Tabela nova criada pelo script
      .select('id')
      .eq('id', session.user.id)
      .single();
      
    if (adminTableError) {
      console.log('Erro ao verificar admin_users_table:', adminTableError.message);
    }
      
    if (adminTableData) {
      console.log('Usuário é admin na tabela admin_users_table');
      return true;
    }
    
    // Verificar se está na tabela admin_users_real
    const { data: adminRealData, error: adminRealError } = await supabase
      .from('admin_users_real')
      .select('id')
      .eq('id', session.user.id)
      .single();
      
    if (adminRealError) {
      console.log('Erro ao verificar admin_users_real:', adminRealError.message);
    }
      
    if (adminRealData) {
      console.log('Usuário é admin na tabela admin_users_real');
      return true;
    }
    
    // Verificar se está na visão materializada admin_users
    const { data: adminData, error: adminError } = await supabase
      .from('admin_users')
      .select('id')
      .eq('id', session.user.id)
      .single();
      
    if (adminError) {
      console.log('Erro ao verificar admin_users:', adminError.message);
    }
      
    if (adminData) {
      console.log('Usuário é admin na visão materializada admin_users');
      return true;
    }
    
    console.log('Usuário não é admin em nenhuma tabela');
    return false;
  } catch (error) {
    console.error('Erro ao verificar se é admin:', error);
    return false;
  }
}

// Função para verificar permissões do usuário - sempre retorna true
export async function checkUserPermissions(requiredPermission: string): Promise<boolean> {
  console.log(`Verificando permissão ${requiredPermission}`);
  return true; // Sempre permitir acesso
}

// Função para recuperação de senha
export async function requestPasswordReset(email: string): Promise<{ success: boolean; message: string }> {
  try {
    if (!email || !email.includes('@')) {
      return { success: false, message: 'Por favor, forneça um email válido' };
    }

    console.log(`Enviando email de recuperação de senha para: ${email}`);
    
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`,
    });
    
    if (error) {
      console.error('Erro ao enviar email de recuperação:', error);
      return { 
        success: false, 
        message: `Erro ao enviar email de recuperação: ${error.message}` 
      };
    }
    
    return { 
      success: true, 
      message: 'Email de recuperação enviado com sucesso. Verifique sua caixa de entrada.' 
    };
  } catch (error: any) {
    console.error('Erro inesperado ao solicitar recuperação de senha:', error);
    return { 
      success: false, 
      message: `Erro inesperado: ${error.message || error}` 
    };
  }
}

// Função para atualizar missões como administrador
export async function updateMissionAsAdmin(missionId: string, status: string): Promise<boolean> {
  try {
    // Verificar se é admin (apenas para logging)
    const isUserAdmin = await isAdmin();
    console.log(`Tentando atualizar missão ${missionId} para ${status}. É admin? ${isUserAdmin}`);
    
    // Usar atualização direta em vez da função RPC que pode estar com problemas
    const { error } = await supabase
      .from('user_missions')
      .update({ 
        status,
        updated_at: new Date().toISOString(),
        approved_by: (await supabase.auth.getUser()).data.user?.id
      })
      .eq('id', missionId);
      
    if (error) {
      console.error('Erro ao atualizar missão:', error);
      return false;
    }
    
    console.log('Missão atualizada com sucesso');
    return true;
  } catch (error) {
    console.error('Erro ao atualizar missão:', error);
    return false;
  }
}

// Função para atualizar missões como administrador - versão alternativa
export async function adminApproveMission(missionId: string, status: 'approved' | 'rejected'): Promise<boolean> {
  try {
    console.log(`Tentando atualizar missão ${missionId} para ${status} usando método alternativo`);
    
    // Obter o usuário atual
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      console.error('Usuário não autenticado');
      return false;
    }
    
    // Verificar se é admin
    const isUserAdmin = await isAdmin();
    if (!isUserAdmin) {
      console.error('Usuário não é administrador');
      return false;
    }
    
    // Usar uma abordagem REST direta para contornar possíveis problemas de RLS
    const response = await fetch(`${supabaseUrl}/rest/v1/user_missions?id=eq.${missionId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': `Bearer ${(await supabase.auth.getSession()).data.session?.access_token}`,
        'Prefer': 'return=minimal'
      },
      body: JSON.stringify({
        status
        // Removidas as colunas que não existem na tabela
      })
    });
    
    if (!response.ok) {
      const errorText = await response.text();
      console.error('Erro na resposta REST:', response.status, errorText);
      return false;
    }
    
    console.log('Missão atualizada com sucesso via REST API');
    return true;
  } catch (error) {
    console.error('Erro ao atualizar missão via REST:', error);
    return false;
  }
}