import React, { useState } from 'react';
import { Mail, Lock, Eye, EyeOff } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface LoginProps {
  onLoginSuccess: () => void;
  onSignUpClick: () => void;
}

export function Login({ onLoginSuccess, onSignUpClick }: LoginProps) {
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    email: '',
    password: ''
  });
  const [isResettingPassword, setIsResettingPassword] = useState(false);

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const { error } = await supabase.auth.resetPasswordForEmail(formData.email, {
        redirectTo: window.location.origin
      });

      if (error) throw error;

      setIsResettingPassword(false);
      alert('Instruções de recuperação de senha foram enviadas para seu e-mail');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao enviar e-mail de recuperação');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: formData.email,
        password: formData.password
      });

      if (error) throw error;

      if (data.user) {
        onLoginSuccess();
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao fazer login');
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-900 dark:to-gray-800 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-xl p-8 space-y-6">
          <div className="text-center space-y-2">
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
              Bem-Vindo ao Sorteios da Laise
            </h1>
            <p className="text-gray-600 dark:text-gray-300 text-lg">
              Faça login para participar de sorteios incríveis!
            </p>
          </div>

          <form onSubmit={isResettingPassword ? handleResetPassword : handleSubmit} className="space-y-4">
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
                  value={formData.email}
                  onChange={handleChange}
                  className="block w-full pl-10 pr-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                  placeholder="seu@email.com"
                  required
                />
              </div>
            </div>

            {!isResettingPassword && <div className="space-y-2">
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
                  value={formData.password}
                  onChange={handleChange}
                  className="block w-full pl-10 pr-10 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                  placeholder="Digite sua senha"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute inset-y-0 right-0 pr-3 flex items-center"
                >
                  {showPassword ? (
                    <EyeOff className="h-5 w-5 text-gray-400" />
                  ) : (
                    <Eye className="h-5 w-5 text-gray-400" />
                  )}
                </button>
              </div>
            </div>}

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
              <div className="mt-2 text-sm text-red-600 text-center">
                {error}
              </div>
            )}
          </form>

          <div className="text-center">
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

          <div className="text-center text-sm">
            <span className="text-gray-500 dark:text-gray-400">Ainda não tem uma conta?</span>{' '}
            <button 
              onClick={onSignUpClick}
              className="text-blue-600 hover:text-blue-700 font-medium"
            >
              Criar conta
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}