import React, { useState, useRef, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Trophy, Gift, Target, Layout, ChevronDown, Zap, HeadphonesIcon, Sun, Moon, User, LogOut, X, Ticket, RefreshCw, DollarSign, Gamepad2 } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { usePoints } from '../contexts/PointsContext';
import './Navigation.mobile.css';

interface UserProfile {
  name: string;
  phone: string;
  isAdmin: boolean;
}

export function Navigation() {
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [activeMenu, setActiveMenu] = useState('');
  const [theme, setTheme] = useState<'light' | 'dark'>(
    localStorage.getItem('theme') as 'light' | 'dark' || 'light'
  );
  const [isUserMenuOpen, setIsUserMenuOpen] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [showPixModal, setShowPixModal] = useState(false);
  const [pixKey, setPixKey] = useState('');
  const { points, isRefreshing, fetchPoints } = usePoints();
  const [tickets, setTickets] = useState({ pending: 0, total: 0 });
  const [pendingPrizes, setPendingPrizes] = useState({ count: 0, value: 0 });
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [hasPixKey, setHasPixKey] = useState(false);

  useEffect(() => {
    Promise.all([
      fetchPendingPrizes(),
      fetchTickets(),
      fetchPixKey()
    ]);
  }, []);

  useEffect(() => {
    if (theme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
    localStorage.setItem('theme', theme);
  }, [theme]);

  const toggleTheme = () => {
    const newTheme = theme === 'light' ? 'dark' : 'light';
    setTheme(newTheme);
  };

  const fetchPixKey = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user?.user_metadata) return;
      
      const currentPixKey = user.user_metadata.pix_key;
      
      if (currentPixKey) {
        setPixKey(currentPixKey);
        setHasPixKey(true);
      }
    } catch (error) {
      console.error('Error fetching PIX key:', error instanceof Error ? error.message : error);
    }
  };

  const fetchTickets = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const [pendingResult, totalResult] = await Promise.all([
        supabase.rpc('get_pending_tickets_count', { user_uuid: user.id }),
        supabase.rpc('get_total_tickets_count', { user_uuid: user.id })
      ]);

      if (pendingResult.error) throw pendingResult.error;
      if (totalResult.error) throw totalResult.error;

      setTickets({
        pending: pendingResult.data || 0,
        total: totalResult.data || 0
      });
    } catch (error) {
      console.error('Error fetching tickets:', error);
    }
  };

  const fetchPendingPrizes = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const [countResult, valueResult] = await Promise.all([
        supabase.rpc('get_pending_prizes_count', { user_uuid: user.id }),
        supabase.rpc('get_pending_prizes_value', { user_uuid: user.id })
      ]);

      if (countResult.error) throw countResult.error;
      if (valueResult.error) throw valueResult.error;

      setPendingPrizes({
        count: countResult.data || 0,
        value: valueResult.data || 0
      });
    } catch (error) {
      console.error('Error fetching pending prizes:', error);
    }
  };

  const handleSavePix = async () => {
    try {
      setHasPixKey(true);
      const { error } = await supabase.auth.updateUser({
        data: { pix_key: pixKey }
      });

      if (error) throw error;
      setShowPixModal(false);
    } catch (error) {
      console.error('Error saving PIX key:', error);
      alert('Erro ao salvar chave PIX. Tente novamente.');
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
          setUserProfile({
            name: user.user_metadata.name || 'Usuário',
            phone: user.user_metadata.phone || 'Telefone não cadastrado',
            isAdmin: userData.is_admin || false
          });
        }
      }
    };

    fetchUserProfile();
  }, []);

  const handleLogout = async () => {
    try {
      await supabase.auth.signOut();
      window.location.reload();
    } catch (error) {
      console.error('Erro ao fazer logout:', error);
    }
  };

  // Reference for dropdown menu
  const dropdownRef = useRef<HTMLDivElement>(null);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const mobileMenuRef = useRef<HTMLDivElement>(null);
  const mobileButtonRef = useRef<HTMLButtonElement>(null);

  // Close dropdown on outside click
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(event.target as Node) &&
        buttonRef.current &&
        !buttonRef.current.contains(event.target as Node)
      ) {
        setIsDropdownOpen(false);
      }

      if (
        mobileMenuRef.current &&
        !mobileMenuRef.current.contains(event.target as Node) &&
        mobileButtonRef.current &&
        !mobileButtonRef.current.contains(event.target as Node)
      ) {
        setIsMobileMenuOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const platforms = [
    {
      name: 'BR4BET',
      url: 'https://go.aff.br4-partners.com/uwatp51w'
    },
    {
      name: 'Segurobet',
      url: 'https://www.seguro.bet.br/affiliates/?btag=1486959'
    },
    {
      name: 'Onabet',
      url: 'https://onabet.cxclick.com/visit/?bta=40879&brand=onabet'
    },
    {
      name: 'Goldbet',
      url: 'https://go.aff.goldebet.com/j5w6jyft'
    },
    {
      name: 'Lotogreen',
      url: 'https://go.aff.lotogreen.com/8dtgqwgq'
    },
    {
      name: 'McGames',
      url: 'https://go.aff.mcgames.bet/r20yo6uf'
    }
  ];

  return (
    <nav className="relative z-[999997] ios-nav fixed w-full top-0 left-0 right-0">
      {/* Top Bar */}
      <div className="bg-gradient-to-r from-blue-600 to-blue-700 dark:from-blue-900 dark:to-blue-950 text-white px-4 sm:px-6 py-3 sm:py-3">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <div className="flex items-center">
            {/* Mobile Menu Button */}
            <button
              ref={mobileButtonRef}
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              className="mr-2 p-2 rounded-lg bg-blue-500 hover:bg-blue-600 text-white transition-colors focus:outline-none focus:ring-2 focus:ring-white/20 lg:hidden"
              aria-expanded={isMobileMenuOpen}
              aria-label="Menu principal"
            >
              <div className="w-6 h-5 flex flex-col justify-between">
                <span className={`w-full h-0.5 bg-white transform transition-transform duration-300 ${isMobileMenuOpen ? 'rotate-45 translate-y-2' : ''}`} />
                <span className={`w-full h-0.5 bg-white transition-opacity duration-300 ${isMobileMenuOpen ? 'opacity-0' : ''}`} />
                <span className={`w-full h-0.5 bg-white transform transition-transform duration-300 ${isMobileMenuOpen ? '-rotate-45 -translate-y-2' : ''}`} />
              </div>
            </button>
            
            <Link
              to="/receipt"
              className="flex items-center gap-3 group cursor-pointer hover:opacity-80 transition-opacity"
            >
              <Trophy className="w-5 h-5 sm:w-6 sm:h-6 group-hover:scale-110 transition-transform" />
              <span className="font-medium text-sm sm:text-base">Sorteio da Laise</span>
            </Link>
          </div>
          
          <div className="flex items-center gap-2 sm:gap-4">
            <button 
              onClick={toggleTheme}
              className="p-2 rounded-full hover:bg-white/10 transition-colors"
              title={theme === 'light' ? "Modo escuro" : "Modo claro"}
            >
              {theme === 'light' ? (
                <Moon className="w-5 h-5" />
              ) : (
                <Sun className="w-5 h-5" />
              )}
            </button>
            
            <button
              onClick={() => setIsUserMenuOpen(!isUserMenuOpen)}
              className="flex items-center gap-1 hover:text-blue-100 transition-colors group"
              aria-expanded={isUserMenuOpen}
              aria-haspopup="true"
            >
              <div className="w-7 h-7 sm:w-8 sm:h-8 bg-blue-500 rounded-full flex items-center justify-center group-hover:bg-blue-400 transition-colors">
                <User className="w-4 h-4 sm:w-5 sm:h-5" />
              </div>
              <span className="font-medium text-sm sm:text-base hidden sm:inline">{userProfile?.name}</span>
              <ChevronDown className={`w-4 h-4 transition-transform ${isUserMenuOpen ? 'rotate-180' : ''}`} />
            </button>
            
            {isUserMenuOpen && (
              <div className="fixed sm:absolute inset-x-0 sm:inset-x-auto top-[4rem] sm:top-full right-0 mt-2 mx-4 sm:mx-0 sm:w-64 bg-white dark:bg-gray-800 rounded-lg shadow-xl py-3 text-gray-700 dark:text-gray-200 transform origin-top-right transition-all duration-200 ease-out border border-gray-200 dark:border-gray-700 backdrop-blur-sm z-50">
                <div className="px-4 py-2 border-b border-gray-100 dark:border-gray-700">
                  <div className="font-medium">{userProfile?.name}</div>
                  <div className="text-sm text-gray-500 dark:text-gray-400">{userProfile?.phone}</div>
                </div>
                <div className="space-y-2 p-2">
                  {tickets.total > 0 && (
                    <button
                      onClick={() => setShowPixModal(true)}
                      className="w-full px-4 py-3 flex items-center justify-between bg-purple-50 dark:bg-purple-900/20 rounded-md hover:bg-purple-100 dark:hover:bg-purple-900/40 transition-colors"
                    >
                      <div className="flex-1 flex items-center gap-2">
                        <Ticket className="w-4 h-4 text-purple-500" />
                        <span className="font-semibold text-gray-900 dark:text-gray-100">
                          {tickets.pending} {tickets.pending === 1 ? 'ticket' : 'tickets'}
                        </span>
                        <span className="text-gray-700 dark:text-gray-300 text-sm ml-1">
                          {tickets.pending === 1 ? 'pendente' : 'pendentes'}
                        </span>
                      </div>
                      <RefreshCw 
                        className={`w-4 h-4 text-gray-500 dark:text-gray-400 hover:text-blue-500 dark:hover:text-blue-400`}
                        onClick={(e) => {
                          e.stopPropagation();
                          fetchTickets();
                        }}
                      />
                    </button>
                  )}
                  {pendingPrizes.count > 0 && (
                    <div className="px-4 py-3 flex items-center gap-2 bg-green-50 dark:bg-green-900/20 rounded-md">
                      <div className="flex-1 flex items-center gap-2">
                        <Gift className="w-4 h-4 text-green-500" />
                        <span className="font-semibold text-gray-900 dark:text-gray-100">
                          R$ {pendingPrizes.value.toFixed(2)}
                        </span>
                        <span className="text-gray-700 dark:text-gray-300 text-sm ml-1">
                          em {pendingPrizes.count} {pendingPrizes.count === 1 ? 'prêmio' : 'prêmios'} pendentes
                        </span>
                      </div>
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          fetchPendingPrizes();
                        }}
                        className="p-1 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-full transition-colors"
                        title="Atualizar prêmios"
                      >
                        <RefreshCw className={`w-4 h-4 text-gray-500 dark:text-gray-400 hover:text-blue-500 dark:hover:text-blue-400`} />
                      </button>
                    </div>
                  )}
                  <button
                    onClick={() => setShowPixModal(true)}
                    className="w-full px-4 py-3 flex items-center gap-2 bg-blue-50 dark:bg-blue-900/20 rounded-md hover:bg-blue-100 dark:hover:bg-blue-900/40 transition-colors"
                  >
                    <DollarSign className="w-4 h-4 text-blue-500" />
                    <span className="text-gray-700 dark:text-gray-300 text-sm">
                      Configurar Chave PIX
                    </span>
                  </button>
                  <div className="px-4 py-3 flex items-center gap-2 bg-yellow-50 dark:bg-yellow-900/20 rounded-md">
                    <div className="flex-1 flex items-center gap-2">
                      <Trophy className="w-4 h-4 text-yellow-500" />
                      <span className="font-semibold text-gray-900 dark:text-gray-100">
                        {points.pending.toLocaleString('pt-BR')}
                      </span>
                      <span className="text-gray-700 dark:text-gray-300 text-sm ml-1">pontos em análise</span>
                    </div>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        fetchPoints();
                      }}
                      disabled={isRefreshing}
                      className="p-1 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-full transition-colors disabled:opacity-50"
                      title="Atualizar pontos"
                    >
                      <RefreshCw className={`w-4 h-4 text-gray-500 dark:text-gray-400 ${isRefreshing ? 'animate-spin' : 'hover:text-blue-500 dark:hover:text-blue-400'}`} />
                    </button>
                  </div>
                  <div className="px-4 py-3 flex items-center gap-2 bg-green-50 dark:bg-green-900/20 rounded-md">
                    <div className="flex-1 flex items-center gap-2">
                      <Trophy className="w-4 h-4 text-green-500" />
                      <span className="font-semibold text-gray-900 dark:text-gray-100">
                        {points.approved.toLocaleString('pt-BR')}
                      </span>
                      <span className="text-gray-700 dark:text-gray-300 text-sm ml-1">pontos aprovados</span>
                    </div>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        fetchPoints();
                      }}
                      disabled={isRefreshing}
                      className="p-1 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-full transition-colors disabled:opacity-50"
                      title="Atualizar pontos"
                    >
                      <RefreshCw className={`w-4 h-4 text-gray-500 dark:text-gray-400 ${isRefreshing ? 'animate-spin' : 'hover:text-blue-500 dark:hover:text-blue-400'}`} />
                    </button>
                  </div>
                </div>
                {isAdmin && (
                  <Link
                    to="/admin"
                    className="block px-4 py-2 text-gray-700 dark:text-gray-300 hover:bg-blue-50 dark:hover:bg-blue-900/50 hover:text-blue-600 dark:hover:text-blue-400 transition-all duration-200 hover:pl-6"
                    onClick={() => setIsUserMenuOpen(false)}
                  >
                    <div className="flex items-center gap-2">
                      <Layout className="w-4 h-4" />
                      <span>Painel Administrativo</span>
                    </div>
                  </Link>
                )}
                <button
                  onClick={handleLogout}
                  className="w-full px-4 py-2 mt-2 flex items-center gap-2 text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
                >
                  <LogOut className="w-4 h-4" />
                  <span>Sair</span>
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Mobile Navigation Bar */}
      <div className="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 lg:hidden z-[999996]">
        <div className="grid grid-cols-6 h-14">
          <div className="relative">
            <button
              onClick={() => setIsDropdownOpen(!isDropdownOpen)}
              className={`flex flex-col items-center justify-center gap-1 w-full h-full ${
                isDropdownOpen 
                  ? 'text-blue-600 dark:text-blue-400' 
                  : 'text-gray-500 dark:text-gray-400 hover:text-blue-600 dark:hover:text-blue-400'
              }`}
            >
              <Layout className="w-5 h-5" />
              <div className="flex items-center gap-1">
                <span className="text-xs">Plataformas</span>
                <ChevronDown className={`w-3 h-3 transition-transform ${isDropdownOpen ? 'rotate-180' : ''}`} />
              </div>
            </button>
            {isDropdownOpen && (
              <div className="absolute top-full left-0 mt-1 w-56 bg-white dark:bg-gray-800 rounded-lg shadow-lg py-1 z-50 max-h-[60vh] overflow-y-auto">
                {platforms.map((platform) => (
                  <a
                    key={platform.name}
                    href={platform.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="block px-4 py-3 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 border-b border-gray-100 dark:border-gray-700 last:border-0"
                    onClick={() => setIsDropdownOpen(false)}
                  >
                    {platform.name}
                  </a>
                ))}
              </div>
            )}
          </div>
          <a
            href="https://www.laisebet.com/"
            target="_blank"
            rel="noopener noreferrer"
            className="flex flex-col items-center justify-center gap-1 text-gray-500 dark:text-gray-400 hover:text-blue-600 dark:hover:text-blue-400"
            onClick={() => setActiveMenu('laise')}
          >
            <Gamepad2 className="w-5 h-5" />
            <span className="text-xs">LaiseBet</span>
          </a>
          <Link
            to="/roulette"
            className="flex flex-col items-center justify-center gap-1 text-gray-500 dark:text-gray-400 hover:text-blue-600 dark:hover:text-blue-400"
            onClick={() => setActiveMenu('roulette')}
          >
            <Target className="w-5 h-5" />
            <span className="text-xs">Raspadinha</span>
          </Link>
          <Link
            to="/missions"
            className="flex flex-col items-center justify-center gap-1 text-gray-500 dark:text-gray-400 hover:text-blue-600 dark:hover:text-blue-400"
            onClick={() => setActiveMenu('missions')}
          >
            <Zap className="w-5 h-5" />
            <span className="text-xs">Missões</span>
          </Link>
          <a
            href="https://www.sinaisdalaise.com/"
            target="_blank"
            rel="noopener noreferrer"
            className="flex flex-col items-center justify-center gap-1 text-gray-500 dark:text-gray-400 hover:text-blue-600 dark:hover:text-blue-400"
            onClick={() => setActiveMenu('sinais')}
          >
            <Target className="w-5 h-5" />
            <span className="text-xs">Sinais</span>
          </a>
          <a
            href="https://t.me/laisebetsuporte"
            target="_blank"
            rel="noopener noreferrer"
            className="flex flex-col items-center justify-center gap-1 text-gray-500 dark:text-gray-400 hover:text-blue-600 dark:hover:text-blue-400"
            onClick={() => setActiveMenu('suporte')}
          >
            <HeadphonesIcon className="w-5 h-5" />
            <span className="text-xs">Suporte</span>
          </a>
        </div>
      </div>

      {/* Mobile Menu */}
      {isMobileMenuOpen && (
        <div 
          ref={mobileMenuRef}
          className="fixed inset-x-0 top-[4rem] bg-white dark:bg-gray-800 shadow-lg p-4 z-50 lg:hidden overflow-y-auto max-h-[calc(100vh-4rem)]"
        >
          <ul className="space-y-2">
            <li className="relative">
              <button
                onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                className="w-full flex items-center justify-between px-4 py-3 rounded-lg text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <div className="flex items-center gap-2">
                  <Layout className="w-5 h-5" />
                  <span className="font-medium">Plataformas</span>
                </div>
                <ChevronDown className={`w-4 h-4 transition-transform ${isDropdownOpen ? 'rotate-180' : ''}`} />
              </button>
            
              {isDropdownOpen && (
                <div className="mt-1 bg-gray-50 dark:bg-gray-700 rounded-lg py-1 px-2">
                  {platforms.map((platform) => (
                    <a
                      key={platform.name}
                      href={platform.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="block px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-600 rounded-lg"
                    >
                      {platform.name}
                    </a>
                  ))}
                </div>
              )}
            </li>
            <li>
              <a
                href="https://www.laisebet.com/"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full flex items-center gap-2 px-4 py-3 rounded-lg text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <Gamepad2 className="w-5 h-5" />
                <span className="font-medium">LaiseBet</span>
              </a>
            </li>
            <li>
              <Link
                to="/roulette"
                onClick={() => {
                  setActiveMenu('roulette');
                  setIsMobileMenuOpen(false);
                }}
                className="w-full flex items-center gap-2 px-4 py-3 rounded-lg text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <Target className="w-5 h-5" />
                <span className="font-medium">Raspadinha</span>
              </Link>
            </li>
            <li>
              <Link
                to="/missions"
                onClick={() => {
                  setActiveMenu('missions');
                  setIsMobileMenuOpen(false);
                }}
                className="w-full flex items-center gap-2 px-4 py-3 rounded-lg text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <Zap className="w-5 h-5" />
                <span className="font-medium">Missões</span>
              </Link>
            </li>
            <li>
              <a
                onClick={() => {
                  setActiveMenu('sinais');
                  setIsMobileMenuOpen(false);
                }}
                href="https://www.sinaisdalaise.com/"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full flex items-center gap-2 px-4 py-3 rounded-lg text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <Target className="w-5 h-5" />
                <span className="font-medium">Sinais</span>
              </a>
            </li>
            <li>
              <a
                onClick={() => {
                  setActiveMenu('suporte');
                  setIsMobileMenuOpen(false);
                }}
                href="https://t.me/laisebetsuporte"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full flex items-center gap-2 px-4 py-3 rounded-lg text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <HeadphonesIcon className="w-5 h-5" />
                <span className="font-medium">Suporte</span>
              </a>
            </li>
          </ul>
        </div>
      )}

      {/* Main Navigation for Desktop */}
      <div className={`bg-white/95 dark:bg-gray-800/95 backdrop-blur-sm shadow-lg hidden lg:block`}>
        <div className="max-w-6xl mx-auto">
          <ul className="flex flex-col lg:flex-row lg:items-center lg:justify-center lg:space-x-8 px-4 py-2 lg:py-4 space-y-2 lg:space-y-0">
            <li className="relative">
              <button
                ref={buttonRef}
                onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                className="flex items-center gap-2 px-4 py-2 rounded-lg text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <Layout className="w-5 h-5" />
                <span className="font-medium">Plataformas</span>
                <ChevronDown className={`w-4 h-4 transition-transform ${isDropdownOpen ? 'rotate-180' : ''}`} />
              </button>
            
              {isDropdownOpen && (
                <div 
                  ref={dropdownRef}
                  className="absolute top-full left-0 mt-1 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg py-1"
                >
                  {platforms.map((platform) => (
                    <a
                      key={platform.name}
                      href={platform.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="block px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                      onClick={() => setIsDropdownOpen(false)}
                    >
                      {platform.name}
                    </a>
                  ))}
                </div>
              )}
            </li>
            <li>
              <a
                onClick={() => {
                  setActiveMenu('laise');
                  setIsUserMenuOpen(false);
                }}
                href="https://www.laisebet.com/"
                target="_blank"
                rel="noopener noreferrer"
                className={`w-full lg:w-auto min-h-[44px] flex items-center gap-2 px-4 py-3 lg:py-2 rounded-lg transition-all duration-200 ${
                  activeMenu === 'laise' 
                    ? 'text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/50' 
                    : 'text-gray-700 dark:text-gray-200 hover:text-blue-600 dark:hover:text-blue-400'
                }`}
              >
                <Gamepad2 className="w-5 h-5" />
                <span className="font-medium text-base">LaiseBet</span>
              </a>
            </li>
            <li>
              <Link
                to="/roulette"
                className={`w-full lg:w-auto min-h-[44px] flex items-center gap-2 px-4 py-3 lg:py-2 rounded-lg transition-all duration-200 ${
                  activeMenu === 'roulette' 
                    ? 'text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/50' 
                    : 'text-gray-700 dark:text-gray-200 hover:text-blue-600 dark:hover:text-blue-400'
                }`}
                onClick={() => {
                  setActiveMenu('roulette');
                  setIsUserMenuOpen(false);
                }}
              >
                <Target className="w-5 h-5" />
                <span className="font-medium text-base">Raspadinha</span>
              </Link>
            </li>
            <li>
              <Link
                to="/missions"
                className={`w-full lg:w-auto min-h-[44px] flex items-center gap-2 px-4 py-3 lg:py-2 rounded-lg transition-all duration-200 ${
                  activeMenu === 'missions' 
                    ? 'text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/50' 
                    : 'text-gray-700 dark:text-gray-200 hover:text-blue-600 dark:hover:text-blue-400'
                }`}
                onClick={() => {
                  setActiveMenu('missions');
                  setIsUserMenuOpen(false);
                }}
              >
                <Zap className="w-5 h-5" />
                <span className="font-medium text-base">Missões</span>
              </Link>
            </li>
            <li>
              <a
                onClick={() => {
                  setActiveMenu('sinais');
                  setIsUserMenuOpen(false);
                }}
                href="https://www.sinaisdalaise.com/"
                target="_blank"
                rel="noopener noreferrer"
                className={`w-full lg:w-auto min-h-[44px] flex items-center gap-2 px-4 py-3 lg:py-2 rounded-lg transition-all duration-200 ${
                  activeMenu === 'sinais' 
                    ? 'text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/50' 
                    : 'text-gray-700 dark:text-gray-200 hover:text-blue-600 dark:hover:text-blue-400'
                }`}
              >
                <Target className="w-5 h-5" />
                <span className="font-medium text-base">Sinais</span>
              </a>
            </li>
            <li>
              <a
                onClick={() => {
                  setActiveMenu('suporte');
                  setIsUserMenuOpen(false);
                }}
                href="https://t.me/laisebetsuporte"
                target="_blank"
                rel="noopener noreferrer"
                className={`w-full lg:w-auto min-h-[44px] flex items-center gap-2 px-4 py-3 lg:py-2 rounded-lg transition-all duration-200 ${
                  activeMenu === 'suporte' 
                    ? 'text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/50' 
                    : 'text-gray-700 dark:text-gray-200 hover:text-blue-600 dark:hover:text-blue-400'
                }`}
              >
                <HeadphonesIcon className="w-5 h-5" />
                <span className="font-medium text-base">Suporte</span>
              </a>
            </li>
          </ul>
        </div>
      </div>

      {/* Modal de Tickets */}
      {showPixModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-md w-full">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                Configurar Chave PIX
                {hasPixKey && <span className="text-sm text-gray-500 dark:text-gray-400 ml-2">(Atualizar)</span>}
              </h3>
              <button
                onClick={() => setShowPixModal(false)}
                className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <div className="space-y-4">
              <p className="text-sm text-gray-600 dark:text-gray-300">
                {hasPixKey ? 'Atualize sua chave PIX se necessário:' : 'Digite sua chave PIX para receber seus prêmios. Pode ser CPF, telefone, email ou chave aleatória.'}
              </p>
              
              <div className="space-y-2">
                <input
                  type="text"
                  value={pixKey}
                  onChange={(e) => setPixKey(e.target.value)}
                  placeholder={hasPixKey ? "Digite a nova chave PIX" : "Digite sua chave PIX"}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                />
              </div>
              
              <div className="flex justify-end gap-3">
                <button
                  onClick={() => setShowPixModal(false)}
                  className="px-4 py-2 text-sm text-gray-600 dark:text-gray-300 hover:text-gray-800 dark:hover:text-gray-100"
                >
                  Cancelar
                </button>
                <button
                  onClick={handleSavePix}
                  disabled={!pixKey.trim()}
                  className="px-4 py-2 text-sm bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                >
                  {hasPixKey ? 'Atualizar' : 'Salvar'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </nav>
  );
}

export default Navigation;