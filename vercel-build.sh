#!/bin/bash

# Garantir que todos os arquivos CSS estejam disponíveis
mkdir -p src/components
touch src/components/dropdown-override.css
touch src/components/dropdown-important.css
touch src/components/bottom-menu.css
touch src/components/Navigation.mobile.css
touch src/components/logo.css

# Executar o build normal
npm run build
