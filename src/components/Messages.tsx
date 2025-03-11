import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { Bell, X } from 'lucide-react';

interface Message {
  id: string;
  title: string;
  content: string;
  created_at: string;
  expires_at: string | null;
  user_id: string | null;
}

export function Messages() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [showMessages, setShowMessages] = useState(false);

  useEffect(() => {
    fetchMessages();
  }, []);

  const fetchMessages = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const now = new Date().toISOString();

      const { data, error } = await supabase
        .from('user_messages')
        .select('*')
        .or(`user_id.is.null,user_id.eq.${user.id}`)
        .or(`expires_at.is.null,expires_at.gt.${now}`)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setMessages(data || []);
      
      // If there are messages, show the notification
      if (data && data.length > 0) {
        setShowMessages(true);
      }
    } catch (error) {
      console.error('Erro ao buscar mensagens:', error);
    }
  };

  if (messages.length === 0) return null;

  return (
    <div className="fixed bottom-4 right-4 z-50">
      {showMessages ? (
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg max-w-sm w-full p-4 border border-gray-200 dark:border-gray-700">
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white flex items-center gap-2">
              <Bell className="w-5 h-5 text-blue-500" />
              Mensagens
            </h3>
            <button
              onClick={() => setShowMessages(false)}
              className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
          <div className="space-y-4 max-h-96 overflow-y-auto">
            {messages.map((message) => (
              <div
                key={message.id}
                className="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3 border border-gray-100 dark:border-gray-600"
              >
                <h4 className="font-medium text-gray-900 dark:text-white mb-1">
                  {message.title}
                </h4>
                <p className="text-gray-600 dark:text-gray-300 text-sm whitespace-pre-wrap">
                  {message.content}
                </p>
                <div className="mt-2 text-xs text-gray-500 dark:text-gray-400">
                  {new Date(message.created_at).toLocaleDateString('pt-BR')}
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : (
        <button
          onClick={() => setShowMessages(true)}
          className="bg-blue-500 hover:bg-blue-600 text-white rounded-full p-3 shadow-lg flex items-center gap-2"
        >
          <Bell className="w-5 h-5" />
          <span className="text-sm font-medium">
            {messages.length} {messages.length === 1 ? 'mensagem' : 'mensagens'}
          </span>
        </button>
      )}
    </div>
  );
}
