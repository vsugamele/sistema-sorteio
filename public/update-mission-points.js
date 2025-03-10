// Script para atualizar os pontos das missões
async function updateMissionPoints() {
  console.log('Iniciando atualização dos pontos das missões...');

  try {
    // Buscar as missões pelos títulos para obter os IDs
    const { data: missions, error: fetchError } = await window.supabase
      .from('missions')
      .select('id, title, points_reward')
      .in('title', [
        'Indique nosso Grupo para 10 amigos',
        'Poste seu link em 10 Grupos do Facebook',
        'Faça um vídeo com um ganho seu e envie no suporte'
      ]);

    if (fetchError) {
      throw fetchError;
    }

    console.log('Missões encontradas:', missions);

    if (!missions || missions.length === 0) {
      console.log('Nenhuma missão encontrada com os títulos especificados.');
      return;
    }

    // Mapeamento dos novos valores de pontos
    const pointsMap = {
      'Indique nosso Grupo para 10 amigos': 20,
      'Poste seu link em 10 Grupos do Facebook': 15,
      'Faça um vídeo com um ganho seu e envie no suporte': 10
    };

    // Atualizar cada missão com os novos pontos
    for (const mission of missions) {
      const newPoints = pointsMap[mission.title];
      
      if (newPoints) {
        console.log(`Atualizando missão "${mission.title}" de ${mission.points_reward} para ${newPoints} pontos...`);
        
        const { error: updateError } = await window.supabase
          .from('missions')
          .update({ points_reward: newPoints })
          .eq('id', mission.id);

        if (updateError) {
          console.error(`Erro ao atualizar missão ${mission.title}:`, updateError);
        } else {
          console.log(`Missão "${mission.title}" atualizada com sucesso para ${newPoints} pontos!`);
        }
      }
    }

    console.log('Atualização de pontos concluída!');
    
    // Recarregar a página para ver as mudanças
    alert('Pontos das missões atualizados com sucesso! A página será recarregada para aplicar as mudanças.');
    window.location.reload();
    
  } catch (error) {
    console.error('Erro ao atualizar pontos das missões:', error);
    alert('Erro ao atualizar pontos das missões. Verifique o console para mais detalhes.');
  }
}

// Adiciona um botão na interface para executar o script
function addUpdateButton() {
  // Verifica se já existe um botão
  if (document.getElementById('update-missions-button')) {
    return;
  }
  
  // Cria o botão
  const button = document.createElement('button');
  button.id = 'update-missions-button';
  button.textContent = 'Atualizar Pontos das Missões';
  button.style.position = 'fixed';
  button.style.bottom = '20px';
  button.style.right = '20px';
  button.style.zIndex = '9999';
  button.style.padding = '10px 15px';
  button.style.backgroundColor = '#4CAF50';
  button.style.color = 'white';
  button.style.border = 'none';
  button.style.borderRadius = '5px';
  button.style.cursor = 'pointer';
  button.style.boxShadow = '0 2px 5px rgba(0,0,0,0.2)';
  
  // Adiciona evento de clique
  button.addEventListener('click', updateMissionPoints);
  
  // Adiciona o botão ao corpo da página
  document.body.appendChild(button);
}

// Executa quando o script é carregado
addUpdateButton();
