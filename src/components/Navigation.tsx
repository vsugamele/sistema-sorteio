import React from 'react';
import { Layout, Gamepad2, Zap, HeadphonesIcon, ChevronDown, Trophy, User, LogOut, Sun, Moon, Target, Gift, DollarSign, Loader2, X, Ticket, RefreshCw } from 'lucide-react';
import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { Link, useNavigate } from 'react-router-dom';
import { usePoints } from '../contexts/PointsContext';

interface UserProfile {
  name: string;
  phone: string;
  isAdmin: boolean;
}

export function Navigation() {
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [isUserMenuOpen, setIsUserMenuOpen] = useState(false);
  const [activeMenu, setActiveMenu] = useState('');
  const [isHovering, setIsHovering] = useState(false);
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [isDark, setIsDark] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const { points, isRefreshing, fetchPoints } = usePoints();
  const [tickets, setTickets] = useState({ pending: 0, total: 0 });
  const [pendingPrizes, setPendingPrizes] = useState({ count: 0, value: 0 });
  const [showPixModal, setShowPixModal] = useState(false);
  const [pixKey, setPixKey] = useState('');
  const [savingPix, setSavingPix] = useState(false);
  const [showTicketsModal, setShowTicketsModal] = useState(false);
  const [hasPixKey, setHasPixKey] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    Promise.all([
      fetchPendingPrizes(),
      fetchTickets(),
      fetchPixKey()
    ]);
  }, []);

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
      setSavingPix(true);
      setHasPixKey(true);
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
    // Check initial preference
    const isDarkMode = localStorage.getItem('darkMode') === 'true';
    setIsDark(isDarkMode);
    if (isDarkMode) {
      document.documentElement.classList.add('dark');
    }
  }, []);

  const toggleDarkMode = () => {
    setIsDark(!isDark);
    document.documentElement.classList.toggle('dark');
    localStorage.setItem('darkMode', (!isDark).toString());
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
  const dropdownRef = React.useRef<HTMLDivElement>(null);
  const buttonRef = React.useRef<HTMLButtonElement>(null);
  const timeoutRef = React.useRef<number>();

  const handleMouseEnter = (menu: string) => {
    if (menu === 'platforms') {
      clearTimeout(timeoutRef.current);
      setIsHovering(true);
      setIsDropdownOpen(true);
      setActiveMenu(menu);
    } else {
      setActiveMenu(menu);
    }
  };

  const handleMouseLeave = () => {
    setIsHovering(false);
    timeoutRef.current = window.setTimeout(() => {
      if (!isHovering) {
        setIsDropdownOpen(false);
        setActiveMenu('');
      }
    }, 150);
  };

  useEffect(() => {
    return () => clearTimeout(timeoutRef.current);
  }, []);

  const handleMenuClick = (menu: string, event: React.MouseEvent) => {
    event.preventDefault();
    event.stopPropagation();

    if (menu === 'platforms') {
      setIsDropdownOpen(!isDropdownOpen);
      setActiveMenu(isDropdownOpen ? '' : menu);
    } else {
      setActiveMenu(menu);
    }
  };

  useEffect(() => {
    const handleOutsideClick = (event: MouseEvent) => {
      if (
        dropdownRef.current &&
        buttonRef.current &&
        !dropdownRef.current.contains(event.target as Node) &&
        !buttonRef.current.contains(event.target as Node)
      ) {
        setIsDropdownOpen(false);
        setActiveMenu('');
      }
    };

    document.addEventListener('click', handleOutsideClick);
    return () => document.removeEventListener('click', handleOutsideClick);
  }, []);

  // Close dropdown on ESC
  useEffect(() => {
    const handleEscKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && isDropdownOpen) {
        setIsDropdownOpen(false);
        setActiveMenu('');
      }
    };

    document.addEventListener('keydown', handleEscKey);
    return () => document.removeEventListener('keydown', handleEscKey);
  }, [isDropdownOpen]);

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
          
          {/* Mobile Menu Button */}
          <button
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            className="lg:hidden p-2 rounded-lg hover:bg-white/10 transition-colors focus:outline-none focus:ring-2 focus:ring-white/20"
            aria-expanded={isMobileMenuOpen}
            aria-label="Menu principal"
          >
            <div className="w-6 h-5 flex flex-col justify-between">
              <span className={`w-full h-0.5 bg-white transform transition-transform duration-300 ${isMobileMenuOpen ? 'rotate-45 translate-y-2' : ''}`} />
              <span className={`w-full h-0.5 bg-white transition-opacity duration-300 ${isMobileMenuOpen ? 'opacity-0' : ''}`} />
              <span className={`w-full h-0.5 bg-white transform transition-transform duration-300 ${isMobileMenuOpen ? '-rotate-45 -translate-y-2' : ''}`} />
            </div>
          </button>
          
          <div className="relative flex items-center gap-2 sm:gap-4">
            <button 
              onClick={toggleDarkMode}
              className="p-2 rounded-full hover:bg-white/10 transition-colors"
              title={isDark ? "Modo claro" : "Modo escuro"}
            >
              {isDark ? (
                <Sun className="w-5 h-5" />
              ) : (
                <Moon className="w-5 h-5" />
              )}
            </button>
            <button
              onClick={() => setIsUserMenuOpen(!isUserMenuOpen)}
              className="flex items-center gap-3 hover:text-blue-100 transition-colors group"
            >
              <div className="w-7 h-7 sm:w-8 sm:h-8 bg-blue-500 rounded-full flex items-center justify-center group-hover:bg-blue-400 transition-colors">
                <User className="w-4 h-4 sm:w-5 sm:h-5" />
              </div>
              <span className="font-medium text-sm sm:text-base hidden sm:inline">{userProfile?.name}</span>
              <ChevronDown className={`w-4 h-4 transition-transform ${isUserMenuOpen ? 'rotate-180' : ''}`} />
            </button>
            
            {isUserMenuOpen && (
              <div className="absolute top-full right-0 mt-2 w-64 bg-white dark:bg-gray-800 rounded-lg shadow-xl py-3 text-gray-700 dark:text-gray-200 transform origin-top-right transition-all duration-200 ease-out border border-gray-200 dark:border-gray-700 backdrop-blur-sm z-50">
                <div className="px-4 py-2 border-b border-gray-100">
                  <div className="font-medium">{userProfile?.name}</div>
                  <div className="text-sm text-gray-500 dark:text-gray-400">{userProfile?.phone}</div>
                </div>
                <div className="space-y-2 p-2">
                  {tickets.total > 0 && (
                    <button
                      onClick={() => setShowTicketsModal(true)}
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

      {/* Main Navigation */}
      <div className={`bg-white/95 dark:bg-gray-800/95 backdrop-blur-sm shadow-lg ${isMobileMenuOpen ? 'block' : 'hidden lg:block'}`}>
        <div className="max-w-6xl mx-auto">
          <ul className="flex flex-col lg:flex-row lg:items-center lg:justify-center lg:space-x-8 px-4 py-2 lg:py-4 space-y-2 lg:space-y-0">
            <li className="relative platforms-menu">
              <button
                ref={buttonRef}
                onClick={(e) => handleMenuClick('platforms', e)}
                onMouseEnter={() => handleMouseEnter('platforms')}
                onMouseLeave={handleMouseLeave}
                className={`w-full lg:w-auto min-h-[44px] flex items-center gap-2 px-4 py-3 lg:py-2 rounded-lg transition-all duration-200 select-none ${
                  activeMenu === 'platforms' 
                    ? 'text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/50' 
                    : 'text-gray-700 dark:text-gray-200 hover:text-blue-600 dark:hover:text-blue-400'
                }`}
                aria-expanded={isDropdownOpen}
                aria-haspopup="true"
              >
                <Layout className="w-5 h-5" />
                <span className="font-medium text-base flex-1 text-left">Plataformas</span>
                <ChevronDown className={`w-3 h-3 sm:w-4 sm:h-4 transition-transform ${isDropdownOpen ? 'rotate-180' : ''}`} />
              </button>
            
              {isDropdownOpen && (
                <div 
                  ref={dropdownRef}
                  onMouseEnter={() => handleMouseEnter('platforms')}
                  onMouseLeave={handleMouseLeave}
                  className={`lg:absolute lg:top-full lg:left-0 mt-1 w-full lg:w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg dark:shadow-gray-900/50 py-2 z-[60] transform transition-all duration-200 platforms-dropdown ${isMobileMenuOpen ? '' : 'lg:origin-top-left'} backdrop-blur-sm`}
                  style={{
                    maxHeight: 'calc(100vh - 200px)',
                    overflowY: 'auto'
                  }}
                  role="menu"
                  aria-orientation="vertical"
                >
                  {platforms.map((platform) => (
                    <a
                      key={platform.name}
                      href={platform.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="block min-h-[44px] px-4 py-3 lg:py-2 text-base lg:text-sm text-gray-700 dark:text-gray-300 hover:bg-blue-50 dark:hover:bg-blue-900/50 hover:text-blue-600 dark:hover:text-blue-400 transition-all duration-200 hover:pl-6"
                      onClick={() => {
                        setIsDropdownOpen(false);
                        setActiveMenu('');
                      }}
                      role="menuitem"
                      tabIndex={0}
                    >
                      {platform.name}
                    </a>
                  ))}
                </div>
              )}
            </li>
            <li>
              <a
                onClick={() => setActiveMenu('laise')}
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
                onClick={() => setActiveMenu('roulette')}
              >
                <Gift className="w-5 h-5" />
                <span className="font-medium text-base">Raspadinha da Sorte</span>
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
                onClick={() => setActiveMenu('missions')}
              >
                <Target className="w-5 h-5" />
                <span className="font-medium text-base">Missões</span>
              </Link>
            </li>
            <li>
              <a
                onClick={() => setActiveMenu('sinais')}
                href="https://www.sinaisdalaise.com/"
                target="_blank"
                rel="noopener noreferrer"
                className={`w-full lg:w-auto min-h-[44px] flex items-center gap-2 px-4 py-3 lg:py-2 rounded-lg transition-all duration-200 ${
                  activeMenu === 'sinais' 
                    ? 'text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/50' 
                    : 'text-gray-700 dark:text-gray-200 hover:text-blue-600 dark:hover:text-blue-400'
                }`}
              >
                <Zap className="w-5 h-5" />
                <span className="font-medium text-base">Sinais</span>
              </a>
            </li>
            <li>
              <a
                onClick={() => setActiveMenu('suporte')}
                href="https://t.me/laisesuporte"
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
      
      {/* Mobile Menu */}
      <div className={`lg:hidden fixed inset-x-0 top-[57px] sm:top-[65px] bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 transform transition-transform duration-300 ease-in-out ${isMobileMenuOpen ? 'translate-y-0' : '-translate-y-full'}`}>
        <div className="p-4 space-y-4">
          <Link
            to="/receipt"
            className="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            onClick={() => setIsMobileMenuOpen(false)}
          >
            <Trophy className="w-5 h-5 text-blue-500" />
            <span>Principal</span>
          </Link>
          <Link
            to="/missions"
            className="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            onClick={() => setIsMobileMenuOpen(false)}
          >
            <Target className="w-5 h-5 text-purple-500" />
            <span>Missões</span>
          </Link>
          <Link
            to="/roulette"
            className="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            onClick={() => setIsMobileMenuOpen(false)}
          >
            <Gift className="w-5 h-5 text-pink-500" />
            <span>Raspadinha</span>
          </Link>
          {isAdmin && (
            <Link
              to="/admin"
              className="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              onClick={() => setIsMobileMenuOpen(false)}
            >
              <Layout className="w-5 h-5 text-green-500" />
              <span>Admin</span>
            </Link>
          )}
        </div>
      </div>
      
      {/* Modal de Tickets */}
      {showTicketsModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-md w-full">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                Sorteio Mensal
              </h3>
              <button
                onClick={() => setShowTicketsModal(false)}
                className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <div className="space-y-4">
              <div className="flex items-center gap-3 text-gray-600 dark:text-gray-300">
                <Trophy className="w-5 h-5 text-yellow-500" />
                <p>
                  O sorteio do mês {new Date().toLocaleString('pt-BR', { month: 'long' })} ainda não foi realizado.
                </p>
              </div>
              
              <p className="text-sm text-gray-600 dark:text-gray-300">
                O sorteio é realizado sempre no último dia do mês. Se você ganhar, será notificado pelos administradores.
              </p>
              
              <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
                <div className="flex items-center gap-2 mb-2">
                  <Ticket className="w-5 h-5 text-blue-500" />
                  <span className="font-medium text-gray-900 dark:text-white">
                    Seus Tickets
                  </span>
                </div>
                <p className="text-sm text-gray-600 dark:text-gray-300">
                  Você tem {tickets.pending} {tickets.pending === 1 ? 'ticket' : 'tickets'} para o sorteio deste mês.
                </p>
              </div>
              
              <button
                onClick={() => setShowTicketsModal(false)}
                className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                Entendi
              </button>
            </div>
          </div>
        </div>
      )}
      
      {/* Modal PIX */}
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
                  disabled={!pixKey.trim() || savingPix}
                  className="px-4 py-2 text-sm bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
                >
                  {savingPix ? (
                    <>
                      <Loader2 className="w-4 h-4 animate-spin" />
                      <span>Salvando...</span>
                    </>
                  ) : (
                    <span>{hasPixKey ? 'Atualizar' : 'Salvar'}</span>
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

export default Navigation;