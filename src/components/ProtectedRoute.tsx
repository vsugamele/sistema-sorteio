import { useEffect, useState } from 'react';
import { Navigate } from 'react-router-dom';
import { supabase, clearSession } from '../lib/supabase';

interface ProtectedRouteProps {
  children: React.ReactNode;
  // Mantemos esses parâmetros para compatibilidade futura, mesmo que não sejam usados agora
  requiredPermission?: string;
  adminOnly?: boolean;
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ 
  children, 
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  requiredPermission,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  adminOnly = false 
}) => {
  const [loading, setLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    const checkAuth = async () => {
      try {
        // Verificar se o usuário está autenticado
        const { data: { session } } = await supabase.auth.getSession();
        
        if (!session) {
          console.log('Usuário não está autenticado');
          setIsAuthenticated(false);
          setLoading(false);
          return;
        }
        
        console.log('Usuário autenticado:', session.user.email);
        // Sempre autenticar o usuário, independente de permissões
        setIsAuthenticated(true);
        setLoading(false);
      } catch (error) {
        console.error('Erro ao verificar autenticação:', error);
        // Em caso de erro, limpar a sessão e redirecionar para login
        await clearSession();
        setIsAuthenticated(false);
        setLoading(false);
      }
    };

    checkAuth();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-purple-500"></div>
      </div>
    );
  }

  // Redirecionar para login apenas se não estiver autenticado
  if (!isAuthenticated) {
    console.log('Redirecionando para /login');
    // Usar window.location.href como fallback para garantir o redirecionamento na Vercel
    setTimeout(() => {
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }, 100);
    return <Navigate to="/login" replace />;
  }

  // Sempre permitir acesso a qualquer rota para usuários autenticados
  return <>{children}</>;
};
