import React, { useState, useEffect, useRef } from 'react';
import { Trophy, Gift, AlertCircle, Coins, Ticket, ArrowLeft, X, RefreshCw } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useNavigate } from 'react-router-dom';
import { usePoints } from '../contexts/PointsContext';

interface Prize {
  id: number;
  name: string;
  type: 'money' | 'ticket' | 'none';
  value: number;
  probability: number;
}

export default function Roulette() {
  const navigate = useNavigate();
  const [selectedPrize, setSelectedPrize] = useState<Prize | null>(null);
  const [showConfirmation, setShowConfirmation] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [isRevealing, setIsRevealing] = useState(false);
  const [isDrawing, setIsDrawing] = useState(false);
  const [lastPosition, setLastPosition] = useState<{ x: number; y: number } | null>(null);
  const [canvasInitialized, setCanvasInitialized] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const { points, isRefreshing, fetchPoints } = usePoints();

  const fetchPrizes = async () => {
    try {
      const { data: prizesData, error } = await supabase
        .from('roulette_prizes')
        .select('*')
        .eq('active', true);

      if (error) throw error;

      const formattedPrizes = prizesData.map(prize => ({
        id: prize.id,
        name: prize.name,
        type: prize.type,
        value: prize.value,
        probability: prize.probability,
        icon: getPrizeIcon(prize.type, prize.value),
        color: getPrizeColor(prize.type)
      }));

      return formattedPrizes;
    } catch (err) {
      console.error('Error fetching prizes:', err);
      return [];
    }
  };

  const getPrizeIcon = (type: string, value: number) => {
    switch (type) {
      case 'none':
        return <AlertCircle className="w-8 h-8" />;
      case 'money':
        return value >= 100 ? <Gift className="w-8 h-8" /> : <Coins className="w-8 h-8" />;
      case 'ticket':
        return <Ticket className="w-8 h-8" />;
      default:
        return <AlertCircle className="w-8 h-8" />;
    }
  };

  const getPrizeColor = (type: string) => {
    switch (type) {
      case 'none':
        return 'text-gray-500';
      case 'money':
        return 'text-emerald-500';
      case 'ticket':
        return 'text-blue-500';
      default:
        return 'text-gray-500';
    }
  };

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || canvasInitialized) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Configurar canvas
    canvas.width = canvas.offsetWidth;
    canvas.height = canvas.offsetHeight;

    // Preencher com cor de cobertura
    ctx.fillStyle = '#CBD5E1'; // Cor da raspadinha
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    setCanvasInitialized(true);
  }, [canvasInitialized]);

  const handleBack = () => {
    if (isDrawing) {
      setShowConfirmation(true);
      return;
    }
    
    resetStates();
    navigate('/receipt');
  };

  const resetStates = () => {
    setIsDrawing(false);
    setSelectedPrize(null);
    setShowModal(false);
    setError(null);
    setIsRevealing(false);
    setLastPosition(null);
  };

  const handleScratchStart = (e: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) => {
    e.preventDefault();
    if (!selectedPrize) {
      return;
    }
    setIsDrawing(true);
    const canvas = canvasRef.current;
    if (!canvas) return;

    const rect = canvas.getBoundingClientRect();
    const x = ('touches' in e ? e.touches[0].clientX : e.clientX) - rect.left;
    const y = ('touches' in e ? e.touches[0].clientY : e.clientY) - rect.top;
    setLastPosition({ x, y });
  };

  const handleScratchMove = (e: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) => {
    e.preventDefault();
    if (!isDrawing || !lastPosition || !selectedPrize) return;

    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const rect = canvas.getBoundingClientRect();
    const x = ('touches' in e ? e.touches[0].clientX : e.clientX) - rect.left;
    const y = ('touches' in e ? e.touches[0].clientY : e.clientY) - rect.top;

    ctx.globalCompositeOperation = 'destination-out';
    ctx.beginPath();
    ctx.lineWidth = 40;
    ctx.lineCap = 'round';
    ctx.moveTo(lastPosition.x, lastPosition.y);
    ctx.lineTo(x, y);
    ctx.stroke();

    setLastPosition({ x, y });

    // Calcular área raspada
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const pixels = imageData.data;
    let transparentPixels = 0;
    for (let i = 3; i < pixels.length; i += 4) {
      if (pixels[i] === 0) transparentPixels++;
    }
    const percentage = (transparentPixels / (pixels.length / 4)) * 100;

    // Revelar prêmio quando raspar 70% da área
    if (percentage >= 70) {
      revealPrize();
    }
  };

  const handleScratchEnd = () => {
    setIsDrawing(false);
  };

  const handleCanvasTouch = (e: React.TouchEvent<HTMLCanvasElement>) => {
    e.preventDefault(); // Prevent scrolling while scratching
    if (e.type === 'touchstart') handleScratchStart(e);
    if (e.type === 'touchmove') handleScratchMove(e);
    if (e.type === 'touchend') handleScratchEnd();
  };

  const revealPrize = () => {
    if (isRevealing) return;
    setIsRevealing(true);
    setShowModal(true);
  };

  const saveTicket = async (value: number) => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('User not authenticated');

      // Let the database determine the correct type based on value
      const { error } = await supabase
        .from('prizes')
        .insert([{
          value: value,
          user_id: user.id
        }]);

      if (error) throw error;
    } catch (err) {
      console.error('Erro ao salvar ticket:', err);
      throw err; // Re-throw to handle in the calling function
    }
  };

  const startScratchCard = async () => {
    if (isProcessing) return;
    
    if (!points || points.approved < 50 || isRefreshing) {
      setError('Você precisa de 50 pontos para jogar');
      setShowModal(true);
      return;
    }
    
    // Reset states
    setError(null);
    setIsProcessing(true);
    setShowModal(false);

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      setError('Usuário não autenticado');
      setIsProcessing(false);
      return;
    }

    const prizes = await fetchPrizes();
    if (!prizes || prizes.length === 0) {
      setError('Não há prêmios disponíveis no momento. Tente novamente mais tarde.');
      setIsProcessing(false);
      return;
    }

    // Calculate total probability
    const totalProbability = prizes.reduce((sum, prize) => sum + prize.probability, 0);
    if (totalProbability <= 0) {
      setError('Configuração de probabilidades inválida. Por favor, tente novamente mais tarde.');
      setIsProcessing(false);
      return;
    }

    // Select prize based on probability
    const random = Math.random() * totalProbability;
    let sum = 0;
    const selectedPrize = prizes.find(prize => {
      sum += prize.probability;
      return random <= sum;
    });

    if (!selectedPrize) {
      setError('Erro ao selecionar prêmio. Por favor, tente novamente.');
      setIsProcessing(false);
      return;
    }

    // Definir o prêmio selecionado antes de atualizar pontos
    setSelectedPrize(selectedPrize);

    // Mostrar o modal imediatamente após selecionar o prêmio
    setShowModal(true);

    // Verificar pontos novamente antes de tentar criar o spin
    const { data: currentPoints } = await supabase
      .rpc('get_available_points_v2', { user_uuid: user.id });

    if (!currentPoints || currentPoints < 50) {
      setError('Pontos insuficientes para jogar. Faça mais depósitos ou complete missões.');
      setIsProcessing(false);
      return;
    }

    const { error: spinError } = await supabase
      .from('roulette_spins')
      .upsert({
        user_id: user.id,
        prize_id: selectedPrize.id,
        points_spent: 50
      });

    if (spinError) {
      if (spinError.message.includes('Insufficient points available')) {
        setError('Pontos insuficientes para jogar. Faça mais depósitos ou complete missões.');
      } else {
        setError('Erro ao criar spin. Por favor, tente novamente.');
      }
      setIsProcessing(false);
      return;
    }

    // Se ganhou um prêmio, salvar
    if (selectedPrize.type !== 'none') {
      try {
        await saveTicket(selectedPrize.value);
        // Refresh pending prizes after saving
        await Promise.all([
          fetchPoints(),
        ]);
      } catch (error) {
        console.error('Error saving prize:', error);
        // Continue showing the prize even if saving fails
        // We'll retry saving later
      }
    }

    setIsProcessing(false);
  };

  const resetCanvas = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Limpar e reconfigurar canvas
    canvas.width = canvas.offsetWidth;
    canvas.height = canvas.offsetHeight;
    ctx.fillStyle = '#CBD5E1';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    setIsDrawing(false);
  };

  return (
    <>
      {/* Overlay de bloqueio quando não há pontos suficientes */}
      {showModal && error && points.approved < 50 && (
        <div className="absolute inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-10 p-4">
          <div className="bg-white dark:bg-gray-800 rounded-xl p-6 max-w-sm text-center space-y-4 shadow-xl">
            <AlertCircle className="w-12 h-12 text-red-500 mx-auto" />
            <h3 className="text-xl font-bold text-gray-900 dark:text-white">
              Pontos Insuficientes
            </h3>
            <p className="text-gray-600 dark:text-gray-300">
              Você precisa de 50 pontos para jogar. Faça um depósito para ganhar mais pontos!
            </p>
            <button
              onClick={() => navigate('/receipt')}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              type="button"
            >
              Fazer Depósito
            </button>
            <button
              onClick={() => setShowModal(false)}
              className="px-6 py-2 text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200 transition-colors"
              type="button"
            >
              Fechar
            </button>
          </div>
        </div>
      )}
      {/* Botão Voltar */}
      <div className="mb-8 mt-4 sm:mt-0">
        <button
          type="button"
          onClick={handleBack}
          className="flex items-center gap-2 text-gray-600 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 transition-colors group cursor-pointer">
          <ArrowLeft className="w-5 h-5 group-hover:-translate-x-1 transition-transform" />
          <span className="font-medium">Voltar</span>
        </button>
      </div>

      <div className="w-full max-w-2xl mx-auto bg-white dark:bg-gray-800 rounded-xl shadow-xl p-6 relative overflow-hidden">
      {/* Modal de Confirmação para Sair */}
      {showConfirmation && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-[100]">
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-sm w-full shadow-xl">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                Deseja mesmo sair?
              </h3>
              <button
                onClick={() => setShowConfirmation(false)}
                className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 p-1"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <p className="text-gray-600 dark:text-gray-300 mb-4">
              A raspadinha ainda não foi totalmente revelada. Se sair agora, perderá os pontos gastos.
            </p>
            <div className="flex justify-end gap-3 mt-6">
              <button
                onClick={() => setShowConfirmation(false)}
                className="px-4 py-2 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-md transition-colors"
              >
                Cancelar
              </button>
              <button
                onClick={() => {
                  setShowConfirmation(false);
                  navigate('/receipt');
                }}
                className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 transition-colors"
              >
                Sair assim mesmo
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Background Patterns */}
      <div className="absolute inset-0 opacity-5 dark:opacity-10">
        <div className="absolute top-0 left-0 w-32 h-32 bg-blue-600 rounded-full blur-3xl" />
        <div className="absolute bottom-0 right-0 w-32 h-32 bg-purple-600 rounded-full blur-3xl" />
      </div>

      {/* Content */}
      <div className="relative">
        <div className="text-center mb-8">
          <h2 className="text-3xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 dark:from-blue-400 dark:to-purple-400 bg-clip-text text-transparent mb-3">
            Raspadinha da Sorte
          </h2>
          <p className="text-lg text-gray-600 dark:text-gray-300">
            Complete as metas/missões para ganhar pontos. A cada 50 pontos coletados você pode concorrer a diversos prêmios!
          </p>
          <div className="bg-blue-50 dark:bg-blue-900/20 rounded-xl p-6 max-w-2xl mx-auto">
            <h3 className="text-xl font-semibold text-blue-700 dark:text-blue-300 mb-4">
              Prêmios Disponíveis:
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-left">
              <div>
                <h4 className="font-medium text-blue-600 dark:text-blue-400 mb-2">Prêmios Instantâneos:</h4>
                <ul className="space-y-2 text-gray-600 dark:text-gray-300">
                  <li className="flex items-center gap-2">
                    <Gift className="w-4 h-4 text-green-500" />
                    Ganhe R$ 20,00
                  </li>
                  <li className="flex items-center gap-2">
                    <Gift className="w-4 h-4 text-green-500" />
                    Ganhe R$ 100,00
                  </li>
                </ul>
              </div>
              <div>
                <h4 className="font-medium text-purple-600 dark:text-purple-400 mb-2">Tickets para Sorteio Mensal:</h4>
                <ul className="space-y-2 text-gray-600 dark:text-gray-300">
                  <li className="flex items-center gap-2">
                    <Ticket className="w-4 h-4 text-purple-500" />
                    <span className="text-gray-900 dark:text-white">R$ 1.000,00 em dinheiro</span>
                  </li>
                  <li className="flex items-center gap-2">
                    <Ticket className="w-4 h-4 text-purple-500" />
                    R$ 1.000,00 em compra no Supermercado
                  </li>
                  <li className="flex items-center gap-2">
                    <Ticket className="w-4 h-4 text-purple-500" />
                    Celular até R$ 3.000,00
                  </li>
                  <li className="flex items-center gap-2">
                    <Ticket className="w-4 h-4 text-purple-500" />
                    5 Cestas Básicas
                  </li>
                  <li className="flex items-center gap-2">
                    <Ticket className="w-4 h-4 text-purple-500" />
                    Tanque de Gasolina
                  </li>
                  <li className="flex items-center gap-2">
                    <Ticket className="w-4 h-4 text-purple-500" />
                    Dia da Beleza
                  </li>
                </ul>
              </div>
            </div>
            <div className="mt-4 pt-4 border-t border-blue-200 dark:border-blue-800">
              <p className="text-sm text-blue-600 dark:text-blue-400">
                <strong>Importante:</strong> Os prêmios de R$ 1.000,00,
                 R$ 1.000,00 em compra no Supermercado, celular, 5 cestas básicas,
                 tanque de gasolina e dia da beleza são tickets para concorrer aos prêmios mensais.
              </p>
            </div>
          </div>
          <div className="mt-6 inline-flex items-center gap-2 px-6 py-2 bg-gradient-to-r from-yellow-500/10 to-amber-500/10 dark:from-yellow-500/20 dark:to-amber-500/20 rounded-full">
            <Trophy className="w-6 h-6 text-yellow-500 animate-pulse" />
            <span className="text-xl font-bold bg-gradient-to-r from-yellow-600 to-amber-600 dark:from-yellow-400 dark:to-amber-400 bg-clip-text text-transparent">
              {points.approved} pontos
              <button
                onClick={fetchPoints}
                disabled={isRefreshing}
                className="ml-2 p-1 hover:bg-gray-100 dark:hover:bg-gray-700/50 rounded-full transition-colors disabled:opacity-50"
                title="Atualizar pontos"
              >
                <RefreshCw className={`w-5 h-5 text-gray-500 dark:text-gray-400 ${isRefreshing ? 'animate-spin' : 'hover:text-blue-500 dark:hover:text-blue-400'}`} />
              </button>
            </span>
            {points.pending > 0 && (
              <span className="text-sm text-gray-500 dark:text-gray-400">
                (+{points.pending} em análise)
              </span>
            )}
          </div>
        </div>

        {/* Área da Raspadinha */}
        <div className="relative w-full aspect-[4/3] max-w-md mx-auto mb-8 rounded-xl overflow-hidden bg-gradient-to-br from-blue-100 to-indigo-100 dark:from-blue-900 dark:to-indigo-900">
          {isDrawing && (
            <canvas
              ref={canvasRef}
              className="absolute inset-0 w-full h-full cursor-pointer touch-none"
              onMouseDown={handleScratchStart}
              onMouseMove={handleScratchMove}
              onMouseUp={handleScratchEnd}
              onMouseLeave={handleScratchEnd}
              onTouchStart={handleCanvasTouch}
              onTouchMove={handleCanvasTouch}
              onTouchEnd={handleCanvasTouch}
            />
          )}
          <div className="absolute inset-0 flex flex-col items-center justify-center p-8 text-center space-y-6">
            <div className="text-2xl font-bold text-gray-700 dark:text-gray-200">
              Raspe para revelar seu prêmio!
            </div>
          </div>
        </div>

        <button
          onClick={startScratchCard}
          disabled={isDrawing || points.approved < 50}
          className={`w-full py-4 px-6 rounded-xl font-bold text-lg transition-all duration-300 transform
            ${isDrawing
              ? 'bg-gray-400 dark:bg-gray-600 text-white cursor-not-allowed'
              : points.approved < 50
              ? 'bg-red-100 dark:bg-red-900/20 text-red-600 dark:text-red-400 cursor-not-allowed'
              : 'bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 hover:shadow-xl hover:-translate-y-1 active:scale-95 text-white'
            }`}
        >
          {isDrawing 
            ? 'Raspando...'
            : points.approved < 50
              ? `Saldo insuficiente (${points.approved}/50 pontos)` 
              : 'Clique aqui para Poder Raspar'}
        </button>

        {error && (
          <div className="mt-4 p-4 bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 rounded-xl text-sm text-center font-medium flex items-center justify-center gap-2">
            <AlertCircle className="w-5 h-5" />
            {error}
          </div>
        )}
      </div>

      {/* Modal de Prêmio */}
      {showModal && selectedPrize && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-800 rounded-2xl p-8 max-w-md w-full animate-fade-in relative overflow-hidden shadow-2xl transform hover:scale-105 transition-transform">
            {/* Resetar estados ao fechar */}
            <button
              onClick={() => {
                setShowModal(false);
                resetStates();
                resetCanvas();
              }}
              className="absolute top-4 right-4 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
            >
              <X className="w-6 h-6" />
            </button>
            {/* Confetti */}
            {selectedPrize.type !== 'none' && (
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
            )}
            
            <div className="text-center space-y-4">
              <div className="flex justify-center">
                <div className={`w-20 h-20 rounded-full ${selectedPrize.type === 'none' ? 'bg-gray-500' : 'bg-gradient-to-br from-blue-500 to-indigo-600'} flex items-center justify-center animate-success shadow-lg`}>
                  <div className="transform hover:scale-110 transition-transform text-white">
                    {getPrizeIcon(selectedPrize.type, selectedPrize.value)}
                  </div>
                </div>
              </div>
              
              <h3 className="text-3xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 dark:from-blue-400 dark:to-purple-400 bg-clip-text text-transparent">
                {selectedPrize.type === 'none' ? 'Não foi dessa vez...' : 'Parabéns!'}
              </h3>
              
              <p className="text-lg text-gray-600 dark:text-gray-300">
                {selectedPrize.type === 'none' 
                  ? 'Continue tentando para ganhar prêmios incríveis!'
                  : selectedPrize.value >= 200
                    ? `Você ganhou 1 Ticket para Concorrer no Fim do Mês a R$ ${selectedPrize.value.toFixed(2)}!`
                    : `Você ganhou R$ ${selectedPrize.value.toFixed(2)}!`}
              </p>
              
              <button
                onClick={() => {
                  setShowModal(false);
                  resetStates();
                  fetchPoints(); // Atualizar pontos ao fechar
                  resetCanvas();
                }}
                className="px-8 py-3 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white rounded-xl font-bold text-lg transition-all duration-200 hover:shadow-lg hover:-translate-y-0.5 active:scale-95"
              >
                Fechar
              </button>
            </div>
          </div>
        </div>
      )}
      </div>
    </>
  );
}