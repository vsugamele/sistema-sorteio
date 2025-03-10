import React, { useEffect, useState } from 'react';
import { Navigate } from 'react-router-dom';
import { supabase, checkUserPermissions } from '../lib/supabase';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requiredPermission?: string;
  adminOnly?: boolean;
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ 
  children, 
  requiredPermission,
  adminOnly = false 
}) => {
  const [loading, setLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [hasPermission, setHasPermission] = useState(false);

  useEffect(() => {
    const checkAuth = async () => {
      try {
        // Verificar se o usuário está autenticado
        const { data: { session } } = await supabase.auth.getSession();
        
        if (!session) {
          setIsAuthenticated(false);
          setLoading(false);
          return;
        }
        
        setIsAuthenticated(true);
        
        // Se não precisar de permissão específica nem ser admin
        if (!requiredPermission && !adminOnly) {
          setHasPermission(true);
          setLoading(false);
          return;
        }
        
        // Verificar se é admin (quando adminOnly é true)
        if (adminOnly) {
          const { data: adminData } = await supabase
            .from('admin_users')
            .select('id')
            .eq('id', session.user.id)
            .single();
            
          if (adminData) {
            setHasPermission(true);
            setLoading(false);
            return;
          } else {
            setHasPermission(false);
            setLoading(false);
            return;
          }
        }
        
        // Verificar permissão específica
        if (requiredPermission) {
          const hasRequiredPermission = await checkUserPermissions(requiredPermission);
          setHasPermission(hasRequiredPermission);
        }
        
        setLoading(false);
      } catch (error) {
        console.error('Erro ao verificar autenticação:', error);
        setIsAuthenticated(false);
        setHasPermission(false);
        setLoading(false);
      }
    };

    checkAuth();
    
    // Listener para mudanças na autenticação
    const { data: authListener } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === 'SIGNED_IN' && session) {
        setIsAuthenticated(true);
        
        if (requiredPermission) {
          const hasRequiredPermission = await checkUserPermissions(requiredPermission);
          setHasPermission(hasRequiredPermission);
        } else if (adminOnly) {
          const { data: adminData } = await supabase
            .from('admin_users')
            .select('id')
            .eq('id', session.user.id)
            .single();
            
          setHasPermission(!!adminData);
        } else {
          setHasPermission(true);
        }
      } else if (event === 'SIGNED_OUT') {
        setIsAuthenticated(false);
        setHasPermission(false);
      }
    });

    return () => {
      authListener?.subscription.unsubscribe();
    };
  }, [requiredPermission, adminOnly]);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-purple-500"></div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (!hasPermission) {
    return <Navigate to="/acesso-negado" replace />;
  }

  return <>{children}</>;
};
