import React, { useState, useEffect } from 'react';

export const ThumbnailImage: React.FC = () => {
  const [imageLoaded, setImageLoaded] = useState(false);
  const [imageError, setImageError] = useState(false);

  useEffect(() => {
    // Pré-carregar a imagem para verificar se ela carrega corretamente
    const img = new Image();
    img.onload = () => setImageLoaded(true);
    img.onerror = () => setImageError(true);
    img.src = "https://windsnap-sharing.lovable.app/api/shared/44brge2ohuw88w2i5sug/preview";
  }, []);

  return (
    <div className="absolute inset-0 overflow-hidden">
      {imageError ? (
        // Fallback para gradiente caso a imagem não carregue
        <div className="w-full h-full bg-gradient-to-br from-purple-900 via-pink-600 to-purple-800 flex items-center justify-center">
          <div className="text-white text-center text-xl">Tutorial Sorteio Laíse</div>
        </div>
      ) : (
        <img 
          src="https://windsnap-sharing.lovable.app/api/shared/44brge2ohuw88w2i5sug/preview" 
          alt="Capa do vídeo tutorial" 
          className={`w-full h-full object-cover transition-opacity duration-300 ${imageLoaded ? 'opacity-100' : 'opacity-0'}`}
          onLoad={() => setImageLoaded(true)}
          onError={() => setImageError(true)}
        />
      )}
    </div>
  );
};
