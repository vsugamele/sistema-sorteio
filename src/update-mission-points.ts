import { supabase } from './lib/supabase';

// Função para atualizar os pontos das missões específicas
async function updateMissionPoints() {
  console.log('Iniciando atualização dos pontos das missões...');

  try {
    // Buscar as missões pelos títulos para obter os IDs
    const { data: missions, error: fetchError } = await supabase
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
    const pointsMap: Record<string, number> = {
      'Indique nosso Grupo para 10 amigos': 20,
      'Poste seu link em 10 Grupos do Facebook': 15,
      'Faça um vídeo com um ganho seu e envie no suporte': 10
    };

    // Atualizar cada missão com os novos pontos
    for (const mission of missions) {
      const newPoints = pointsMap[mission.title];
      
      if (newPoints) {
        console.log(`Atualizando missão "${mission.title}" de ${mission.points_reward} para ${newPoints} pontos...`);
        
        const { error: updateError } = await supabase
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
  } catch (error) {
    console.error('Erro ao atualizar pontos das missões:', error);
  }
}

// Executar a função
updateMissionPoints().then(() => {
  console.log('Script finalizado.');
});
