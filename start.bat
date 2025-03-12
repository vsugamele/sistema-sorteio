@echo off
echo ===================================
echo Iniciando o projeto de sorteio
echo ===================================
echo.
echo 1. Matando processos node.exe anteriores...
taskkill /F /IM node.exe >nul 2>&1
echo.
echo 2. Limpando cache do Vite...
if exist "node_modules\.vite" rmdir /S /Q "node_modules\.vite"
echo.
echo 3. Iniciando servidor Vite na porta 3333...
echo.
echo Aguarde, o navegador abrira automaticamente...
echo.
cd /d "%~dp0"
set PORT=3333
npm run dev
