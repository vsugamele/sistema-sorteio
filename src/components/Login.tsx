import { useState } from 'react';
import { supabase } from '../lib/supabase';
import { Mail, Lock, Eye, EyeOff } from 'lucide-react';

export interface LoginProps {
  onLoginSuccess: () => void;
  onSignUpClick: () => void;
}

export function Login({ onLoginSuccess, onSignUpClick }: LoginProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showPassword, setShowPassword] = useState(false);
  const [isResettingPassword, setIsResettingPassword] = useState(false);
  const [resetSent, setResetSent] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      console.log('Tentando fazer login com:', email);
      
      // Usando a API padrão do Supabase para login
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        console.error('Erro de login:', error);
        setError(error.message);
      } else {
        console.log('Login bem-sucedido:', data);
        
        // Verificar se é admin (apenas para logging)
        const { data: adminData } = await supabase
          .from('admin_users')
          .select('id')
          .eq('id', data.user.id)
          .single();
          
        console.log('É admin?', !!adminData);
        
        // Chamar callback de sucesso
        onLoginSuccess();
      }
    } catch (err) {
      console.error('Erro inesperado:', err);
      setError('Ocorreu um erro inesperado. Por favor, tente novamente.');
    } finally {
      setLoading(false);
    }
  };

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      console.log('Enviando e-mail de recuperação para:', email);
      
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: window.location.origin + '/login',
      });

      if (error) {
        console.error('Erro ao enviar e-mail de recuperação:', error);
        setError(error.message);
      } else {
        console.log('E-mail de recuperação enviado com sucesso');
        setResetSent(true);
      }
    } catch (err) {
      console.error('Erro inesperado:', err);
      setError('Ocorreu um erro inesperado. Por favor, tente novamente.');
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    if (name === 'email') {
      setEmail(value);
    } else if (name === 'password') {
      setPassword(value);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-900 dark:to-gray-800 p-4">
      <div className="max-w-md w-full bg-white dark:bg-gray-800 rounded-xl shadow-lg overflow-hidden">
        <div className="p-8">
          <div className="text-center mb-8">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Bem-Vindo ao Sorteios da Laíse</h2>
            <p className="text-gray-600 dark:text-gray-300 mt-2">
              Faça login para participar de sorteios incríveis!
            </p>
          </div>

          {resetSent ? (
            <div className="text-center p-4 bg-green-100 dark:bg-green-900 rounded-lg mb-4">
              <p className="text-green-800 dark:text-green-200">
                Enviamos instruções de recuperação para seu e-mail. Verifique sua caixa de entrada.
              </p>
              <button
                onClick={() => {
                  setIsResettingPassword(false);
                  setResetSent(false);
                }}
                className="mt-4 text-blue-600 hover:text-blue-700 text-sm font-medium"
              >
                Voltar ao login
              </button>
            </div>
          ) : (
            <form onSubmit={isResettingPassword ? handleResetPassword : handleLogin} className="space-y-4">
              <div className="space-y-2">
                <label className="text-sm font-medium text-gray-700 dark:text-gray-200 block">
                  E-mail
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Mail className="h-5 w-5 text-gray-400" />
                  </div>
                  <input
                    type="email"
                    name="email"
                    value={email}
                    onChange={handleChange}
                    className="block w-full pl-10 pr-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                    placeholder="seu@email.com"
                    required
                  />
                </div>
              </div>

              {!isResettingPassword && (
                <div className="space-y-2">
                  <label className="text-sm font-medium text-gray-700 dark:text-gray-200 block">
                    Senha
                  </label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <Lock className="h-5 w-5 text-gray-400" />
                    </div>
                    <input
                      type={showPassword ? "text" : "password"}
                      name="password"
                      value={password}
                      onChange={handleChange}
                      className="block w-full pl-10 pr-10 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                      placeholder="Digite sua senha"
                      required
                    />
                    <button
                      type="button"
                      className="absolute inset-y-0 right-0 pr-3 flex items-center"
                      onClick={() => setShowPassword(!showPassword)}
                    >
                      {showPassword ? (
                        <EyeOff className="h-5 w-5 text-gray-400" />
                      ) : (
                        <Eye className="h-5 w-5 text-gray-400" />
                      )}
                    </button>
                  </div>
                </div>
              )}

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
              >
                {loading 
                  ? (isResettingPassword ? 'Enviando...' : 'Entrando...') 
                  : (isResettingPassword ? 'Enviar instruções' : 'Entrar')}
              </button>
              
              {error && (
                <div className="p-2 text-sm text-red-600 bg-red-50 dark:bg-red-900 dark:text-red-200 rounded">
                  {error}
                </div>
              )}
            </form>
          )}

          {!resetSent && (
            <div className="text-center mt-4">
              <button
                onClick={() => {
                  setIsResettingPassword(!isResettingPassword);
                  setError(null);
                }}
                className="text-blue-600 hover:text-blue-700 text-sm font-medium"
              >
                {isResettingPassword ? 'Voltar ao login' : 'Esqueci minha senha'}
              </button>
            </div>
          )}

          <div className="mt-6 text-center">
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Ainda não tem uma conta?{' '}
              <button
                onClick={onSignUpClick}
                className="text-blue-600 hover:text-blue-700 font-medium"
              >
                Criar conta
              </button>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}