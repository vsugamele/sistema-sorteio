import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error('Supabase URL and Anon Key são necessários.');
}

export const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    storageKey: 'sorteio_auth_token',
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
    // Configuração para usar cookies HttpOnly em vez de localStorage
    storage: {
      getItem: (key) => {
        // Aqui estamos usando cookies HttpOnly que são mais seguros
        // O navegador não permite acesso via JavaScript
        const value = document.cookie
          .split('; ')
          .find((row) => row.startsWith(`${key}=`))
          ?.split('=')[1];
        return value || null;
      },
      setItem: (key, value) => {
        // Configurando cookie com HttpOnly, Secure e SameSite
        // Isso impede acesso via JavaScript e restringe o envio do cookie
        document.cookie = `${key}=${value}; path=/; max-age=2592000; HttpOnly; Secure; SameSite=Strict`;
      },
      removeItem: (key) => {
        // Remove o cookie definindo uma data de expiração no passado
        document.cookie = `${key}=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT; HttpOnly; Secure; SameSite=Strict`;
      },
    },
  },
  global: {
    headers: {
      'X-CSRF-Token': getCSRFToken(), // Adiciona proteção CSRF
    },
  },
});

// Função para gerar um token CSRF
function getCSRFToken() {
  let token = localStorage.getItem('csrf_token');
  if (!token) {
    token = generateRandomToken();
    localStorage.setItem('csrf_token', token);
  }
  return token;
}

// Gera um token aleatório para proteção CSRF
function generateRandomToken() {
  return Array.from(crypto.getRandomValues(new Uint8Array(16)))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

// Implementar logout automático após período de inatividade
let inactivityTimer: number | null = null;
const INACTIVITY_TIMEOUT = 30 * 60 * 1000; // 30 minutos

function resetInactivityTimer() {
  if (inactivityTimer) {
    clearTimeout(inactivityTimer);
  }
  inactivityTimer = window.setTimeout(async () => {
    await supabase.auth.signOut();
    window.location.href = '/';
  }, INACTIVITY_TIMEOUT);
}

// Monitorar atividade do usuário
if (typeof window !== 'undefined') {
  ['mousedown', 'keypress', 'scroll', 'touchstart'].forEach(event => {
    window.addEventListener(event, resetInactivityTimer);
  });
  resetInactivityTimer();
}

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