import { supabase } from './supabase';

// Interface para mensagens
export interface Message {
  id: string;
  title: string;
  content: string;
  created_at: string;
  expires_at: string | null;
  user_id: string | null;
  created_by: string | null;
  users?: {
    raw_user_meta_data: {
      name: string;
      phone: string;
    };
  };
}

// Função para verificar e corrigir o sistema de mensagens
export async function verifyMessageSystem(): Promise<{ success: boolean; message: string }> {
  try {
    // Verificar se a tabela user_messages existe
    const { error: tableCheckError } = await supabase
      .from('user_messages')
      .select('id')
      .limit(1);
    
    if (tableCheckError) {
      console.error('Erro ao verificar tabela user_messages:', tableCheckError);
      return { 
        success: false, 
        message: `A tabela user_messages não existe ou está inacessível: ${tableCheckError.message}` 
      };
    }
    
    // Verificar se o usuário atual está autenticado
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      return { 
        success: false, 
        message: 'Usuário não autenticado. Faça login primeiro.' 
      };
    }
    
    // Tentar enviar uma mensagem de teste para verificar permissões
    const testMessage = {
      title: 'Teste de Sistema',
      content: 'Esta é uma mensagem de teste para verificar o sistema de mensagens.',
      user_id: user.id, // Enviar apenas para o usuário atual
      created_by: user.id
    };
    
    const { error: insertError } = await supabase
      .from('user_messages')
      .insert(testMessage);
    
    if (insertError) {
      console.error('Erro ao inserir mensagem de teste:', insertError);
      
      // Se o erro for de permissão, tentar corrigir
      if (insertError.code === 'PGRST301' || 
          insertError.message.includes('permission') || 
          insertError.message.includes('policy')) {
        
        return { 
          success: false, 
          message: `Erro de permissão ao inserir mensagem: ${insertError.message}. Entre em contato com o administrador.` 
        };
      }
      
      return { 
        success: false, 
        message: `Erro ao inserir mensagem: ${insertError.message}` 
      };
    }
    
    // Verificar se a mensagem foi inserida corretamente
    const { data: messages, error: fetchError } = await supabase
      .from('user_messages')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })
      .limit(1);
    
    if (fetchError) {
      console.error('Erro ao buscar mensagem de teste:', fetchError);
      return { 
        success: false, 
        message: `Erro ao buscar mensagem de teste: ${fetchError.message}` 
      };
    }
    
    if (!messages || messages.length === 0) {
      return { 
        success: false, 
        message: 'A mensagem de teste foi inserida, mas não pôde ser recuperada.' 
      };
    }
    
    return { 
      success: true, 
      message: 'Sistema de mensagens verificado e funcionando corretamente.' 
    };
  } catch (error: any) {
    console.error('Erro inesperado ao verificar sistema de mensagens:', error);
    return { 
      success: false, 
      message: `Erro inesperado: ${error.message || error}` 
    };
  }
}

// Função para buscar mensagens para o usuário atual
export async function fetchUserMessages(): Promise<{ messages: Message[]; error: string | null }> {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      return { 
        messages: [], 
        error: 'Usuário não autenticado. Faça login primeiro.' 
      };
    }
    
    const now = new Date().toISOString();
    
    // Buscar mensagens para o usuário atual ou para todos os usuários (user_id = null)
    // e que não tenham expirado (expires_at = null ou expires_at > agora)
    const { data, error } = await supabase
      .from('user_messages')
      .select(`
        *,
        users!user_messages_user_id_fkey (
          raw_user_meta_data
        )
      `)
      .or(`user_id.is.null,user_id.eq.${user.id}`)
      .or(`expires_at.is.null,expires_at.gt.${now}`)
      .order('created_at', { ascending: false });
    
    if (error) {
      console.error('Erro ao buscar mensagens:', error);
      return { 
        messages: [], 
        error: `Erro ao buscar mensagens: ${error.message}` 
      };
    }
    
    return { 
      messages: data || [], 
      error: null 
    };
  } catch (error: any) {
    console.error('Erro inesperado ao buscar mensagens:', error);
    return { 
      messages: [], 
      error: `Erro inesperado: ${error.message || error}` 
    };
  }
}

// Função para enviar uma mensagem
export async function sendMessage(
  title: string, 
  content: string, 
  userId: string | null = null, 
  expiresAt: string | null = null
): Promise<{ success: boolean; message: string }> {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      return { 
        success: false, 
        message: 'Usuário não autenticado. Faça login primeiro.' 
      };
    }
    
    // Formatar a data de expiração
    let formattedExpiresAt = null;
    if (expiresAt) {
      const expiresAtDate = new Date(expiresAt);
      // Garantir que a data de expiração está no futuro
      if (expiresAtDate > new Date()) {
        formattedExpiresAt = expiresAtDate.toISOString();
      }
    }
    
    const { error } = await supabase
      .from('user_messages')
      .insert({
        title,
        content,
        user_id: userId,
        expires_at: formattedExpiresAt,
        created_by: user.id
      });
    
    if (error) {
      console.error('Erro ao enviar mensagem:', error);
      return { 
        success: false, 
        message: `Erro ao enviar mensagem: ${error.message}` 
      };
    }
    
    return { 
      success: true, 
      message: 'Mensagem enviada com sucesso!' 
    };
  } catch (error: any) {
    console.error('Erro inesperado ao enviar mensagem:', error);
    return { 
      success: false, 
      message: `Erro inesperado: ${error.message || error}` 
    };
  }
}
