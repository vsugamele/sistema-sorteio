import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    // Garantir que o Vite não remova arquivos importantes durante o build
    emptyOutDir: true,
    // Copiar arquivos da pasta public para a pasta dist
    copyPublicDir: true
  }
});
