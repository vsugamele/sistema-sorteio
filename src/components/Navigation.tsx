import { Layout, Trophy, LogOut, Gift, Loader2, X } from 'lucide-react';
import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { Link, useNavigate } from 'react-router-dom';

export function Navigation() {
  const [isAdmin, setIsAdmin] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [showPixModal, setShowPixModal] = useState(false);
  const [pixKey, setPixKey] = useState('');
  const [savingPix, setSavingPix] = useState(false);
  const navigate = useNavigate();

  const handleSavePix = async () => {
    try {
      setSavingPix(true);
      const { error } = await supabase.auth.updateUser({
        data: { pix_key: pixKey }
      });

      if (error) throw error;
      setShowPixModal(false);
    } catch (error) {
      console.error('Error saving PIX key:', error);
      alert('Erro ao salvar chave PIX. Tente novamente.');
    } finally {
      setSavingPix(false);
    }
  };

  useEffect(() => {
    const fetchUserProfile = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (user) {
        // Fetch user data including admin status
        const { data: userData, error } = await supabase
          .from('users')
          .select('is_admin')
          .eq('id', user.id)
          .single();

        if (!error && userData) {
          setIsAdmin(userData.is_admin || false);
        }
      }
    };

    fetchUserProfile();
  }, []);

  const handleLogout = async () => {
    try {
      await supabase.auth.signOut();
      navigate('/login');
    } catch (error) {
      console.error('Erro ao fazer logout:', error);
    }
  };

  return (
    <nav className="fixed top-0 left-0 right-0 z-50">
      {/* Top Bar */}
      <div className="bg-gradient-to-r from-blue-600 to-blue-700 dark:from-blue-900 dark:to-blue-950 text-white px-4 sm:px-6 py-2 sm:py-3">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <button
            onClick={() => navigate('/receipt')}
            className="flex items-center gap-3 group cursor-pointer hover:opacity-80 transition-opacity"
          >
            <Trophy className="w-5 h-5 sm:w-6 sm:h-6 group-hover:scale-110 transition-transform" />
            <span className="font-medium text-sm sm:text-base">Sorteio da Laise</span>
          </button>
          
          {/* Menu Button */}
          <button
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            className="p-2 rounded-lg hover:bg-white/10 transition-colors focus:outline-none"
            aria-expanded={isMobileMenuOpen}
            aria-label="Menu principal"
          >
            <div className="w-6 h-5 flex flex-col justify-between">
              <span className={`w-full h-0.5 bg-white transform transition-transform duration-300 ${isMobileMenuOpen ? 'rotate-45 translate-y-2' : ''}`} />
              <span className={`w-full h-0.5 bg-white transition-opacity duration-300 ${isMobileMenuOpen ? 'opacity-0' : ''}`} />
              <span className={`w-full h-0.5 bg-white transform transition-transform duration-300 ${isMobileMenuOpen ? '-rotate-45 -translate-y-2' : ''}`} />
            </div>
          </button>
        </div>
      </div>

      {/* Mobile Menu */}
      <div className={`bg-white dark:bg-gray-800 shadow-lg ${isMobileMenuOpen ? 'block' : 'hidden'}`}>
        <div className="divide-y divide-gray-200 dark:divide-gray-700">
          <Link
            to="/receipt"
            className="flex items-center gap-3 px-4 py-3 hover:bg-gray-100 dark:hover:bg-gray-700"
            onClick={() => setIsMobileMenuOpen(false)}
          >
            <Trophy className="w-5 h-5 text-blue-500" />
            <span className="text-gray-700 dark:text-gray-300">Registrar Participação</span>
          </Link>

          <Link
            to="/roulette"
            className="flex items-center gap-3 px-4 py-3 hover:bg-gray-100 dark:hover:bg-gray-700"
            onClick={() => setIsMobileMenuOpen(false)}
          >
            <Gift className="w-5 h-5 text-purple-500" />
            <span className="text-gray-700 dark:text-gray-300">Raspadinha da Sorte</span>
          </Link>

          <Link
            to="/missions"
            className="flex items-center gap-3 px-4 py-3 hover:bg-gray-100 dark:hover:bg-gray-700"
            onClick={() => setIsMobileMenuOpen(false)}
          >
            <Trophy className="w-5 h-5 text-green-500" />
            <span className="text-gray-700 dark:text-gray-300">Missões</span>
          </Link>

          {isAdmin && (
            <Link
              to="/admin"
              className="flex items-center gap-3 px-4 py-3 hover:bg-gray-100 dark:hover:bg-gray-700"
              onClick={() => setIsMobileMenuOpen(false)}
            >
              <Layout className="w-5 h-5 text-indigo-500" />
              <span className="text-gray-700 dark:text-gray-300">Painel Admin</span>
            </Link>
          )}

          <button
            onClick={() => {
              handleLogout();
              setIsMobileMenuOpen(false);
            }}
            className="w-full flex items-center gap-3 px-4 py-3 text-red-600 dark:text-red-400 hover:bg-gray-100 dark:hover:bg-gray-700"
          >
            <LogOut className="w-5 h-5" />
            <span>Sair</span>
          </button>
        </div>
      </div>

      {/* Modals */}
      {showPixModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-800 rounded-xl max-w-md w-full">
            <div className="p-4 border-b border-gray-200 dark:border-gray-700 flex justify-between items-center">
              <h2 className="text-xl font-bold text-gray-900 dark:text-white">
                Configurar Chave PIX
              </h2>
              <button
                onClick={() => setShowPixModal(false)}
                className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            <div className="p-4">
              <input
                type="text"
                value={pixKey}
                onChange={(e) => setPixKey(e.target.value)}
                placeholder="Digite sua chave PIX"
                className="w-full px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
              />
              <div className="mt-4 flex justify-end gap-3">
                <button
                  onClick={() => setShowPixModal(false)}
                  className="px-4 py-2 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
                >
                  Cancelar
                </button>
                <button
                  onClick={handleSavePix}
                  disabled={savingPix || !pixKey.trim()}
                  className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors disabled:opacity-50"
                >
                  {savingPix ? (
                    <div className="flex items-center gap-2">
                      <Loader2 className="w-4 h-4 animate-spin" />
                      <span>Salvando...</span>
                    </div>
                  ) : (
                    'Salvar'
                  )}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </nav>
  );
}