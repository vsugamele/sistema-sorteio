import React from 'react';
import { Sparkles, Gift, Star, Trophy, Upload, Target, X, Play, Pause } from 'lucide-react';
import { View, ViewSetter } from '../App';
import { ReceiptUpload } from './ReceiptUpload';

interface PromoMessageProps {
  setView: ViewSetter;
}

export function PromoMessage({ setView }: PromoMessageProps) {
  const [showModal, setShowModal] = React.useState(false);
  const [showVideo, setShowVideo] = React.useState(false);
  const [isPlaying, setIsPlaying] = React.useState(false);
  const videoRef = React.useRef<HTMLVideoElement>(null);

  const toggleVideo = () => {
    setShowVideo(!showVideo);
  };

  const togglePlayPause = () => {
    if (videoRef.current) {
      if (isPlaying) {
        videoRef.current.pause();
      } else {
        videoRef.current.play();
      }
      setIsPlaying(!isPlaying);
    }
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
            <video 
              ref={videoRef}
              className="w-full h-full object-cover"
              controls={false}
              poster="/video-placeholder.jpg"
              onEnded={() => setIsPlaying(false)}
            >
              <source src="/video.mp4" type="video/mp4" />
              Seu navegador não suporta vídeos HTML5.
            </video>
            
            <button 
              onClick={togglePlayPause}
              className="absolute inset-0 w-full h-full flex items-center justify-center bg-black/30 hover:bg-black/40 transition-colors"
            >
              {isPlaying ? (
                <Pause className="w-16 h-16 text-white opacity-80 hover:opacity-100 transition-opacity" />
              ) : (
                <Play className="w-16 h-16 text-white opacity-80 hover:opacity-100 transition-opacity" />
              )}
            </button>
          </div>
        ) : (
          <div 
            className="relative aspect-video bg-gradient-to-r from-blue-500 to-indigo-600 rounded-lg flex items-center justify-center cursor-pointer hover:opacity-90 transition-opacity"
            onClick={toggleVideo}
          >
            <div className="text-white text-center">
              <Play className="w-16 h-16 mx-auto mb-2" />
              <p className="font-medium">Clique para assistir o vídeo</p>
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