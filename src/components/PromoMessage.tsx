import React from 'react';
import { Sparkles, Gift, Star, Trophy, Upload, Target, X, Play } from 'lucide-react';
import { ViewSetter } from '../App';
import { ReceiptUpload } from './ReceiptUpload';

interface PromoMessageProps {
  setView: ViewSetter;
}

export function PromoMessage({ setView }: PromoMessageProps) {
  const [showModal, setShowModal] = React.useState(false);
  const [showVideo, setShowVideo] = React.useState(false);

  const toggleVideo = () => {
    setShowVideo(!showVideo);
  };

  return (
    <div className="space-y-8 relative">
      {/* Navigation Buttons */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <button
          onClick={() => setShowModal(true)}
          className="relative group overflow-hidden bg-gradient-to-r from-blue-500 to-indigo-500 hover:from-blue-600 hover:to-indigo-600 text-white rounded-xl p-4 transition-all duration-300 hover:shadow-lg hover:-translate-y-1"
        >
          <div className="absolute inset-0 bg-white/10 transform -skew-x-12 group-hover:skew-x-12 transition-transform duration-700 ease-out" />
          <div className="relative flex flex-col items-center gap-2">
            <Upload className="w-6 h-6" />
            <span className="font-medium">Registre Sua Participação</span>
          </div>
        </button>

        <button
          onClick={() => setView('roulette')}
          className="relative group overflow-hidden bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600 text-white rounded-xl p-4 transition-all duration-300 hover:shadow-lg hover:-translate-y-1"
        >
          <div className="absolute inset-0 bg-white/10 transform -skew-x-12 group-hover:skew-x-12 transition-transform duration-700 ease-out" />
          <div className="relative flex flex-col items-center gap-2">
            <Gift className="w-6 h-6" />
            <span className="font-medium">Raspadinha da Sorte</span>
          </div>
        </button>

        <button
          onClick={() => setView('missions')}
          className="relative group overflow-hidden bg-gradient-to-r from-emerald-500 to-green-500 hover:from-emerald-600 hover:to-green-600 text-white rounded-xl p-4 transition-all duration-300 hover:shadow-lg hover:-translate-y-1"
        >
          <div className="absolute inset-0 bg-white/10 transform -skew-x-12 group-hover:skew-x-12 transition-transform duration-700 ease-out" />
          <div className="relative flex flex-col items-center gap-2">
            <Target className="w-6 h-6" />
            <span className="font-medium">Missões</span>
          </div>
        </button>
      </div>

      {/* Vídeo Promocional */}
      <div className="bg-gradient-to-r from-blue-100 to-indigo-100 dark:from-blue-900/30 dark:to-indigo-900/30 p-4 rounded-xl border border-blue-200 dark:border-blue-800 shadow-md">
        <h3 className="text-lg font-semibold text-blue-700 dark:text-blue-300 mb-3 text-center">
          Assista ao vídeo explicativo
        </h3>
        
        {showVideo ? (
          <div className="relative aspect-video bg-black rounded-lg overflow-hidden">
            <iframe 
              className="w-full h-full"
              src="https://www.youtube.com/embed/4dK2i5wgYHQ?autoplay=1"
              title="Tutorial do Sistema"
              frameBorder="0"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
              allowFullScreen
            ></iframe>
            
            <button 
              onClick={toggleVideo}
              className="absolute top-3 right-3 bg-black/50 hover:bg-black/70 rounded-full p-1 transition-colors"
            >
              <X className="w-6 h-6 text-white" />
            </button>
          </div>
        ) : (
          <div 
            className="relative aspect-video rounded-lg flex items-center justify-center cursor-pointer hover:opacity-90 transition-opacity overflow-hidden"
            onClick={toggleVideo}
          >
            {/* Usando um gradiente colorido em vez de uma imagem externa */}
            <div 
              className="absolute inset-0 bg-gradient-to-br from-purple-800 via-pink-600 to-purple-900"
            />
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="text-white text-center z-10">
                <div className="bg-pink-600/80 rounded-full p-4 mb-3 backdrop-blur-sm">
                  <Play className="w-12 h-12 mx-auto" />
                </div>
                <p className="font-medium text-xl drop-shadow-md">Clique para assistir o tutorial</p>
              </div>
            </div>
          </div>
        )}
      </div>

      <div className="text-center relative group perspective-1000">
      <div className="absolute inset-0 bg-gradient-to-r from-blue-500/5 via-indigo-500/5 to-blue-500/5 dark:from-blue-400/10 dark:via-indigo-400/10 dark:to-blue-400/10 rounded-2xl transform group-hover:scale-105 transition-all duration-500 ease-out" />
      
      <div className="relative bg-white/95 dark:bg-gray-800/95 backdrop-blur-sm border border-blue-100/50 dark:border-blue-900/50 rounded-2xl p-8 shadow-xl space-y-6 group-hover:shadow-2xl group-hover:-translate-y-1 transition-all duration-500">
        <div className="absolute -top-3 -right-3 animate-spin-slow">
          <div className="relative">
            <Star className="w-10 h-10 text-yellow-400 absolute transform rotate-45" />
            <Star className="w-10 h-10 text-yellow-500 animate-pulse" />
          </div>
        </div>
        
        <div className="relative space-y-6">
          <div className="flex justify-center items-center gap-4">
            <Sparkles className="w-8 h-8 text-yellow-400 animate-pulse transform -rotate-12" />
            <Sparkles className="w-6 h-6 text-blue-500 animate-pulse delay-150 transform rotate-12" />
          </div>
          
          <h1 className="text-2xl sm:text-3xl md:text-4xl font-extrabold bg-gradient-to-r from-blue-600 via-indigo-500 to-blue-600 bg-clip-text text-transparent leading-tight transform hover:scale-[1.01] transition-transform duration-300">
            SORTEIO DA LAISE
          </h1>
          <div className="space-y-6">
            <p className="text-xl sm:text-2xl text-blue-600 dark:text-blue-400 font-semibold">
              Seja bem vindo! Aqui vou explicar como que funcionam as regras para você ganhar prêmios.
            </p>
            
            <div className="grid gap-6">
              <div className="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 p-6 rounded-xl border border-blue-100 dark:border-blue-800">
                <h3 className="text-lg font-semibold text-blue-700 dark:text-blue-300 mb-2">
                  Existem duas maneiras de você poder participar da raspadinha e ganhar prêmios:
                </h3>
                
                <div className="space-y-4">
                  <div className="flex items-start gap-4">
                    <div className="flex-shrink-0 w-8 h-8 bg-blue-100 dark:bg-blue-900/50 rounded-full flex items-center justify-center">
                      <span className="text-blue-600 dark:text-blue-400 font-bold">1</span>
                    </div>
                    <p className="text-gray-700 dark:text-gray-300">
                      A Primeira delas é fazendo deposito em uma das plataformas participantes.
                      <span className="block mt-1 font-medium text-blue-600 dark:text-blue-400">
                        Cada 1 real depositado = 1 ponto
                      </span>
                    </p>
                  </div>
                  
                  <div className="flex items-start gap-4">
                    <div className="flex-shrink-0 w-8 h-8 bg-blue-100 dark:bg-blue-900/50 rounded-full flex items-center justify-center">
                      <span className="text-blue-600 dark:text-blue-400 font-bold">2</span>
                    </div>
                    <p className="text-gray-700 dark:text-gray-300">
                      A segunda maneira é você completando as missões, são pequenas tarefas que também te darão pontos para liberar a raspadinha.
                    </p>
                  </div>
                </div>
              </div>
              
              <div className="bg-gradient-to-r from-emerald-50 to-green-50 dark:from-emerald-900/20 dark:to-green-900/20 p-6 rounded-xl border border-emerald-100 dark:border-emerald-800">
                <div className="flex items-center gap-3">
                  <div className="flex-shrink-0 w-10 h-10 bg-emerald-100 dark:bg-emerald-900/50 rounded-full flex items-center justify-center">
                    <Trophy className="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
                  </div>
                  <p className="text-lg font-medium text-emerald-700 dark:text-emerald-300">
                    Você pode participar da raspadinha a cada 50 pontos!
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      
      </div>
    </div>
      
      {/* Modal de Registro */}
      {showModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-800 rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white dark:bg-gray-800 p-4 border-b border-gray-200 dark:border-gray-700 flex justify-between items-center">
              <h2 className="text-xl font-bold text-gray-900 dark:text-white">
                Registre sua Participação
              </h2>
              <button
                onClick={() => setShowModal(false)}
                className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            <div className="p-4">
              <ReceiptUpload />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}