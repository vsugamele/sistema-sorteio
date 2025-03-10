import React from 'react';

export const ThumbnailImage: React.FC = () => {
  return (
    <div className="absolute inset-0 overflow-hidden">
      <img 
        src="https://preview--windsnap-sharing.lovable.app/shared/rih05jagl87kmwgmeqtg3" 
        alt="Capa do vídeo tutorial" 
        className="w-full h-full object-cover"
      />
    </div>
  );
};
