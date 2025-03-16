import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 3333,
    open: true,
    strictPort: false
  },
  build: {
    outDir: 'dist',
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
      },
    },
    // Garantir que o Vite gere os assets corretamente para SPAs
    assetsInlineLimit: 4096,
    sourcemap: true,
    // Copiar arquivos estáticos para a pasta de build
    copyPublicDir: true
  },
  // Configuração para lidar com rotas SPA
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },
  // Configuração para o histórico de navegação HTML5
  base: '/'
});
