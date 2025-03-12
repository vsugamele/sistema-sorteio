/**
 * Script para carregar a aplicação em um iframe e evitar qualquer barra indesejada
 */

// Função para criar o iframe e carregar a aplicação
function loadAppInIframe() {
  // Verificar se já estamos em um iframe
  if (window.self !== window.top) {
    console.log('Já estamos em um iframe, não é necessário criar outro');
    return;
  }
  
  // Verificar se estamos na página de login
  const isLoginPage = window.location.pathname === '/login' || 
                      window.location.pathname === '/' || 
                      window.location.href.includes('/login') ||
                      window.location.href.includes('/register');
  
  if (isLoginPage) {
    console.log('Estamos na página de login, não é necessário criar iframe');
    return;
  }
  
  // Remover qualquer barra indesejada no topo
  const bodyChildren = document.querySelectorAll('body > div');
  bodyChildren.forEach(function(el) {
    if (el.id !== 'root') {
      el.style.display = 'none';
    }
  });
  
  // Verificar se já existe o iframe
  if (document.getElementById('app-iframe')) {
    console.log('O iframe já existe');
    return;
  }
  
  // Obter a URL atual sem parâmetros de consulta
  const currentUrl = window.location.href.split('?')[0];
  
  // Criar o iframe
  const iframe = document.createElement('iframe');
  iframe.id = 'app-iframe';
  iframe.src = currentUrl + '?iframe=true';
  iframe.style.width = '100%';
  iframe.style.height = '100vh';
  iframe.style.border = 'none';
  iframe.style.position = 'fixed';
  iframe.style.top = '0';
  iframe.style.left = '0';
  iframe.style.zIndex = '99999';
  
  // Verificar se estamos sendo carregados em um iframe
  if (window.location.search.includes('iframe=true')) {
    console.log('Estamos sendo carregados em um iframe, não é necessário criar outro');
    return;
  }
  
  // Limpar o conteúdo do body
  document.body.innerHTML = '';
  
  // Adicionar o iframe ao body
  document.body.appendChild(iframe);
}

// Verificar se devemos carregar o iframe
if (!window.location.search.includes('iframe=true')) {
  // Executar a função quando o DOM estiver carregado
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadAppInIframe);
  } else {
    loadAppInIframe();
  }
}
