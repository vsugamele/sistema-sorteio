import React from 'react';

export const ThumbnailImage: React.FC = () => {
  return (
    <div className="absolute inset-0 bg-gradient-to-br from-purple-900 via-pink-600 to-purple-800 overflow-hidden">
      <div className="absolute inset-0 flex flex-col items-center justify-center text-white">
        <div className="text-5xl font-bold mb-2">TUTORIAL</div>
        <div className="text-7xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-pink-400 to-pink-200">SORTEIO</div>
        <div className="text-6xl font-bold mt-2">LAÍSE</div>
        <div className="absolute bottom-4 right-4 text-sm opacity-70">
          *Substitua este componente pela sua imagem
        </div>
      </div>
    </div>
  );
};
