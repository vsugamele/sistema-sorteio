import React, { useState } from 'react';
import { User, Mail, Phone, Lock, Eye, EyeOff, CheckCircle } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface SignUpProps {
  onLoginClick: () => void;
}

export function SignUp({ onLoginClick }: SignUpProps) {
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    phone: '',
    email: '',
    password: ''
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setSuccess(false);
    
    try {
      const { data, error } = await supabase.auth.signUp({
        email: formData.email,
        password: formData.password,
        options: {
          data: {
            name: formData.name,
            phone: formData.phone
          }
        }
      });

      if (error) throw error;

      if (data.user) {
        setSuccess(true);
        setFormData({
          name: '',
          phone: '',
          email: '',
          password: ''
        });
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ocorreu um erro ao criar a conta');
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
      {/* Overlay de Sucesso */}
      {success && (
        <div className="fixed inset-0 bg-black/20 dark:bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl p-8 max-w-md w-full animate-success-bg relative overflow-hidden">
            {/* Confetti */}
            <div className="absolute inset-0 overflow-hidden pointer-events-none">
              {[...Array(20)].map((_, i) => (
                <div
                  key={i}
                  className="absolute animate-confetti"
                  style={{
                    left: `${Math.random() * 100}%`,
                    top: `${Math.random() * 100}%`,
                    backgroundColor: ['#60A5FA', '#34D399', '#FBBF24', '#F87171'][Math.floor(Math.random() * 4)],
                    width: '8px',
                    height: '8px',
                    borderRadius: Math.random() > 0.5 ? '50%' : '2px',
                    animationDelay: `${Math.random() * 0.5}s`,
                    animationDuration: `${0.5 + Math.random() * 0.5}s`
                  }}
                />
              ))}
            </div>
            <div className="text-center space-y-4 relative">
              <div className="flex justify-center relative">
                <div className="absolute inset-0 bg-green-500/20 dark:bg-green-500/10 rounded-full blur-xl animate-success" />
                <CheckCircle className="w-16 h-16 text-green-500 animate-success" />
              </div>
              <h2 className="text-2xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 dark:from-green-400 dark:to-emerald-400 bg-clip-text text-transparent">
                Conta criada com sucesso!
              </h2>
              <p className="text-gray-600 dark:text-gray-300">
                Verifique seu e-mail para confirmar o cadastro.
              </p>
              <button
                onClick={() => {
                  setSuccess(false);
                  onLoginClick();
                }}
                className="px-6 py-2 bg-gradient-to-r from-green-600 to-emerald-600 dark:from-green-500 dark:to-emerald-500 text-white rounded-full font-medium hover:shadow-lg hover:-translate-y-0.5 transition-all duration-200"
              >
                Ir para Login
              </button>
            </div>
          </div>
        </div>
      )}

      <div className="w-full max-w-md">
        <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-xl p-8 space-y-6 relative">
          <div className="text-center space-y-2">
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
              Criar Conta
            </h1>
            <p className="text-gray-500 dark:text-gray-400">
              Junte-se à nossa comunidade
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <label className="text-sm font-medium text-gray-700 dark:text-gray-200 block">
                Nome Completo
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <User className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="text"
                  name="name"
                  value={formData.name}
                  onChange={handleChange}
                  className="block w-full pl-10 pr-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                  placeholder="Digite seu nome"
                  required
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium text-gray-700 dark:text-gray-200 block">
                Telefone
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Phone className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="tel"
                  name="phone"
                  value={formData.phone}
                  onChange={handleChange}
                  className="block w-full pl-10 pr-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                  placeholder="(00) 00000-0000"
                  required
                />
              </div>
            </div>

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
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            >
              {loading ? 'Criando conta...' : 'Criar Conta'}
            </button>
            {error && (
              <div className="mt-2 text-sm text-red-600 text-center">
                {error}
              </div>
            )}
          </form>

          <div className="text-center text-sm">
            <span className="text-gray-500 dark:text-gray-400">Já tem uma conta?</span>{' '}
            <button
              onClick={onLoginClick}
              className="text-blue-600 hover:text-blue-700 font-medium"
            >
              Entrar
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}