import React from 'react';

export const ThumbnailImage: React.FC = () => {
  return (
    <div className="absolute inset-0 overflow-hidden">
      <img 
        src="https://fa16cacc-5be9-4e34-94bf-a609daa78fc3.lovableproject.com/shared/lyjwf6jsyj5m6i59izjqo" 
        alt="Capa do vídeo tutorial" 
        className="w-full h-full object-cover"
      />
    </div>
  );
};
