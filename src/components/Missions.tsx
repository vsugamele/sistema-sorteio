import { useState, useEffect } from 'react';
import { Gift, AlertCircle, Loader2, Plus, Image as ImageIcon, Instagram, Coins, Send, Users, Video, AtSign, Gamepad2, DollarSign, ExternalLink, X, Upload } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { usePoints } from '../contexts/PointsContext';
import { useNavigate } from 'react-router-dom';

interface SocialMission {
  id: string;
  title: string;
  points_reward: number;
  type: 'registration' | 'instagram' | 'telegram' | 'deposit';
  link?: string;
  requirements?: {
    amount?: number;
  };
}

interface UserSocialMission {
  id: string;
  mission_id: string;
  proof_url: string | null;
  status: 'pending' | 'submitted' | 'approved' | 'rejected';
  completed_at: string | null;
}

export function Missions() {
  const navigate = useNavigate();
  const [missions, setMissions] = useState<SocialMission[]>([]);
  const [userMissions, setUserMissions] = useState<Record<string, UserSocialMission>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [uploading, setUploading] = useState<string | null>(null);
  const { points, fetchPoints } = usePoints();
  const [selectedMission, setSelectedMission] = useState<SocialMission | null>(null);
  const [showProofModal, setShowProofModal] = useState(false);

  useEffect(() => {
    fetchMissions();
  }, []);

  const fetchMissions = async () => {
    try {
      setLoading(true);
      setError(null);

      // Fetch deposit missions
      const { data: depositMissions, error: depositError } = await supabase
        .from('missions')
        .select(`
          id,
          title,
          points_reward,
          type,
          link,
          requirements
        `)
        .eq('active', true)
        .eq('type', 'deposit')
        .order('points_reward', { ascending: true });

      // Fetch other missions
      const { data: otherMissions, error: otherMissionsError } = await supabase
        .from('missions')
        .select(`
          id,
          title,
          points_reward,
          type,
          link,
          requirements
        `)
        .eq('active', true)
        .neq('type', 'deposit')
        .order('points_reward', { ascending: false });

      if (depositError) throw depositError;
      if (otherMissionsError) throw otherMissionsError;

      // Fetch user's mission progress
      const { data: userMissionsData, error: userMissionsError } = await supabase
        .from('user_missions')
        .select('*')
        .eq('user_id', (await supabase.auth.getUser()).data.user?.id);

      if (userMissionsError) throw userMissionsError;

      // Convert user missions to a map for easier lookup
      const userMissionsMap = userMissionsData?.reduce((acc, mission) => ({
        ...acc,
        [mission.mission_id]: mission
      }), {});

      setMissions([...(depositMissions || []), ...(otherMissions || [])]);
      setUserMissions(userMissionsMap || {});
    } catch (err) {
      console.error('Error fetching missions:', err);
      setError('Erro ao carregar missões. Tente novamente mais tarde.');
    } finally {
      setLoading(false);
    }
  };

  const handleFileUpload = async (missionId: string, file: File) => {
    try {
      setUploading(missionId);
      setShowProofModal(false);
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Usuário não autenticado');

      // Validate file type
      if (!file.type.startsWith('image/')) {
        throw new Error('Apenas imagens são permitidas');
      }

      // Create unique file name
      const fileExt = file.name.split('.').pop();
      const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`;
      const filePath = `mission-proofs/${fileName}`;

      // Upload file
      const { error: uploadError } = await supabase.storage
        .from('receipts')
        .upload(filePath, file);

      if (uploadError) throw uploadError;

      // Get public URL
      const { data: urlData } = await supabase.storage
        .from('receipts')
        .getPublicUrl(filePath);

      if (!urlData?.publicUrl) {
        throw new Error('Erro ao gerar URL da imagem');
      }

      // Create or update user mission
      const { error: missionError } = await supabase
        .from('user_missions')
        .insert({
          user_id: user.id,
          mission_id: missionId,
          proof_url: urlData.publicUrl,
          status: 'submitted',
          created_at: new Date().toISOString()
        })
        .match({
          user_id: user.id,
          mission_id: missionId
        });

      if (missionError) {
        // If entry already exists, update it instead
        if (missionError.code === '23505') {
          const { error: updateError } = await supabase
            .from('user_missions')
            .update({
              proof_url: urlData.publicUrl,
              status: 'submitted',
              created_at: new Date().toISOString()
            })
            .match({
              user_id: user.id,
              mission_id: missionId
            });

          if (updateError) throw updateError;
        } else {
          throw missionError;
        }
      }

      // Refresh missions
      await Promise.all([
        fetchMissions(),
        fetchPoints()
      ]);
    } catch (err) {
      console.error('Error uploading proof:', err);
      alert('Erro ao enviar comprovante. Tente novamente.');
    } finally {
      setUploading(null);
    }
  };

  const getMissionIcon = (type: SocialMission['type'], title?: string) => {
    // Check for specific mission types based on title
    if (title?.toLowerCase().includes('reels')) {
      return (
        <div className="relative">
          <div className="absolute inset-0 bg-gradient-to-br from-pink-500/30 to-purple-500/30 dark:from-pink-400/30 dark:to-purple-400/30 rounded-full blur-[6px] animate-pulse" />
          <div className="absolute inset-0 bg-gradient-to-tl from-pink-500/20 to-transparent rounded-full animate-spin-slow" />
          <Video className="w-6 h-6 text-pink-500 dark:text-pink-400 transform hover:scale-110 transition-transform" />
        </div>
      );
    } else if (title?.toLowerCase().includes('stories')) {
      return (
        <div className="relative">
          <div className="absolute inset-0 bg-gradient-to-br from-orange-500/30 to-red-500/30 dark:from-orange-400/30 dark:to-red-400/30 rounded-full blur-[6px] animate-pulse" />
          <div className="absolute inset-0 bg-gradient-to-tl from-orange-500/20 to-transparent rounded-full animate-spin-slow" />
          <Instagram className="w-6 h-6 text-orange-500 dark:text-orange-400 transform hover:scale-110 transition-transform" />
        </div>
      );
    } else if (title?.toLowerCase().includes('cadastro')) {
      return (
        <div className="relative">
          <div className="absolute inset-0 bg-gradient-to-br from-blue-500/30 to-indigo-500/30 dark:from-blue-400/30 dark:to-indigo-400/30 rounded-full blur-[6px] animate-pulse" />
          <div className="absolute inset-0 bg-gradient-to-tl from-blue-500/20 to-transparent rounded-full animate-spin-slow" />
          <Gamepad2 className="w-6 h-6 text-blue-500 dark:text-blue-400 transform hover:scale-110 transition-transform" />
        </div>
      );
    } else if (title?.toLowerCase().includes('depósito')) {
      return (
        <div className="relative">
          <div className="absolute inset-0 bg-gradient-to-br from-emerald-500/30 to-green-500/30 dark:from-emerald-400/30 dark:to-green-400/30 rounded-full blur-[6px] animate-pulse" />
          <div className="absolute inset-0 bg-gradient-to-tl from-emerald-500/20 to-transparent rounded-full animate-spin-slow" />
          <DollarSign className="w-6 h-6 text-emerald-500 dark:text-emerald-400 transform hover:scale-110 transition-transform" />
        </div>
      );
    }

    // Default icons based on type
    switch(type) {
      case 'registration':
        return (
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-br from-emerald-500/30 to-teal-500/30 dark:from-emerald-400/30 dark:to-teal-400/30 rounded-full blur-[6px] animate-pulse" />
            <div className="absolute inset-0 bg-gradient-to-tl from-emerald-500/20 to-transparent rounded-full animate-spin-slow" />
            <AtSign className="w-6 h-6 text-emerald-500 dark:text-emerald-400 transform hover:scale-110 transition-transform" />
          </div>
        );
      case 'instagram':
        return (
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-br from-fuchsia-500/30 to-pink-500/30 dark:from-fuchsia-400/30 dark:to-pink-400/30 rounded-full blur-[6px] animate-pulse" />
            <div className="absolute inset-0 bg-gradient-to-tr from-fuchsia-500/20 to-transparent rounded-full animate-spin-slow" />
            <Instagram className="w-6 h-6 text-fuchsia-500 dark:text-fuchsia-400 transform hover:scale-110 transition-transform" />
          </div>
        );
      case 'telegram':
        return (
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-br from-blue-500/30 to-indigo-500/30 dark:from-blue-400/30 dark:to-indigo-400/30 rounded-full blur-[6px] animate-pulse" />
            <div className="absolute inset-0 bg-gradient-to-bl from-blue-500/20 to-transparent rounded-full animate-spin-slow" />
            <Send className="w-6 h-6 text-blue-500 dark:text-blue-400 transform hover:scale-110 transition-transform animate-bounce-subtle" />
          </div>
        );
      default:
        return (
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-br from-violet-500/30 to-purple-500/30 dark:from-violet-400/30 dark:to-purple-400/30 rounded-full blur-[6px] animate-pulse" />
            <div className="absolute inset-0 bg-gradient-to-tr from-violet-500/20 to-transparent rounded-full animate-spin-slow" />
            <Users className="w-6 h-6 text-violet-500 dark:text-violet-400 transform hover:scale-110 transition-transform animate-bounce-subtle" />
          </div>
        );
    }
  };

  const getStatusBadge = (status: UserSocialMission['status']) => {
    const styles = {
      pending: 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300',
      submitted: 'bg-yellow-100 text-yellow-600 dark:bg-yellow-900/30 dark:text-yellow-400',
      approved: 'bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400',
      rejected: 'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400'
    };

    const labels = {
      pending: 'Pendente',
      submitted: 'Em Análise',
      approved: 'Aprovado',
      rejected: 'Recusado'
    };

    return (
      <span className={`px-3 py-1 rounded-full text-sm font-medium ${styles[status]}`}>
        {labels[status]}
      </span>
    );
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <Loader2 className="w-8 h-8 text-blue-500 animate-spin" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center min-h-[400px] text-red-500 gap-2">
        <AlertCircle className="w-6 h-6" />
        <span>{error}</span>
      </div>
    );
  }

  return (
    <div className="w-full max-w-4xl mx-auto p-6">
      {/* Navigation Buttons */}
      <div className="grid grid-cols-2 gap-4 mb-8">
        <button
          onClick={() => navigate('/receipt')}
          className="relative group overflow-hidden bg-gradient-to-r from-blue-500 to-indigo-500 hover:from-blue-600 hover:to-indigo-600 text-white rounded-xl p-4 transition-all duration-300 hover:shadow-lg hover:-translate-y-1"
        >
          <div className="absolute inset-0 bg-white/10 transform -skew-x-12 group-hover:skew-x-12 transition-transform duration-700 ease-out" />
          <div className="relative flex flex-col items-center gap-2">
            <Upload className="w-6 h-6" />
            <span className="font-medium">Volte para a Tela Principal</span>
          </div>
        </button>

        <button
          onClick={() => navigate('/roulette')}
          className="relative group overflow-hidden bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600 text-white rounded-xl p-4 transition-all duration-300 hover:shadow-lg hover:-translate-y-1"
        >
          <div className="absolute inset-0 bg-white/10 transform -skew-x-12 group-hover:skew-x-12 transition-transform duration-700 ease-out" />
          <div className="relative flex flex-col items-center gap-2">
            <Gift className="w-6 h-6" />
            <span className="font-medium">Raspadinha da Sorte</span>
          </div>
        </button>
      </div>

      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 dark:from-blue-400 dark:to-purple-400 bg-clip-text text-transparent mb-3">
          Missões Disponíveis
        </h1>
        <p className="text-gray-600 dark:text-gray-300 text-lg">
          Complete missões para ganhar pontos extras!
        </p>
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">
          Clique em uma missão para enviar seu comprovante ou arraste para o lado para ver mais opções
        </p>
        <div className="mt-4 inline-flex items-center gap-2 px-6 py-2 bg-gradient-to-r from-green-500/10 to-emerald-500/10 dark:from-green-500/20 dark:to-emerald-500/20 rounded-full">
          <Gift className="w-6 h-6 text-green-500" />
          <span className="text-xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 dark:from-green-400 dark:to-emerald-400 bg-clip-text text-transparent">
            {points.approved} pontos
          </span>
          {points.pending > 0 && (
            <span className="text-sm text-gray-500 dark:text-gray-400">
              (+{points.pending} pendentes)
            </span>
          )}
        </div>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-xl overflow-hidden">
        {/* Versão para desktop e mobile unificada com cards */}
        <div className="p-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {missions.map((mission) => {
            const userMission = userMissions[mission.id];
            
            return (
              <div 
                key={mission.id} 
                className="bg-gradient-to-br from-gray-50 to-gray-100 dark:from-gray-800 dark:to-gray-900 rounded-xl shadow-md hover:shadow-lg transition-all duration-300 overflow-hidden border border-gray-200 dark:border-gray-700 hover:border-blue-200 dark:hover:border-blue-800 group"
                onClick={() => {
                  setSelectedMission(mission);
                  setShowProofModal(true);
                }}
              >
                <div className="p-5">
                  <div className="flex items-start gap-4 mb-4">
                    <div className="relative p-3 rounded-lg overflow-hidden group-hover:scale-110 transition-transform duration-300 bg-gradient-to-br from-gray-100 to-white dark:from-gray-700 dark:to-gray-800 shadow-sm">
                      <div className="relative z-10">
                        {mission.type === 'deposit' ? (
                          <Coins className="w-7 h-7 text-green-500 dark:text-green-400 filter drop-shadow-md" />
                        ) : (
                          getMissionIcon(mission.type, mission.title)
                        )}
                      </div>
                    </div>
                    <div className="flex-1">
                      <h3 className="font-semibold text-gray-900 dark:text-white text-lg mb-1 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                        {mission.title}
                      </h3>
                      <div className="flex flex-wrap gap-2 items-center">
                        <div className="text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-800 px-3 py-1 rounded-full">
                          {mission.points_reward} {mission.points_reward === 1 ? 'ponto' : 'pontos'}
                        </div>
                        <div>
                          {userMission ? getStatusBadge(userMission.status) : getStatusBadge('pending')}
                        </div>
                      </div>
                      {mission.link && (
                        <a
                          onClick={(e) => {
                            e.stopPropagation();
                            e.preventDefault();
                            window.open(mission.link, '_blank', 'noopener,noreferrer');
                          }}
                          href={mission.link}
                          className="text-sm text-blue-500 dark:text-blue-400 hover:underline flex items-center gap-1 mt-2"
                        >
                          <ExternalLink className="w-3 h-3" />
                          Acessar Link
                        </a>
                      )}
                    </div>
                  </div>
                  
                  <div className="flex gap-2 mt-4 border-t border-gray-200 dark:border-gray-700 pt-4">
                    {userMission?.proof_url && (
                      <a
                        onClick={(e) => e.stopPropagation()}
                        href={userMission.proof_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex-1 py-2 px-3 bg-green-50 dark:bg-green-900/30 hover:bg-green-100 dark:hover:bg-green-900/50 rounded-lg transition-colors inline-flex items-center justify-center gap-2 text-green-600 hover:text-green-700 dark:text-green-400 dark:hover:text-green-300"
                      >
                        <ImageIcon className="w-4 h-4" />
                        <span className="text-sm">Ver Comprovante</span>
                      </a>
                    )}
                    {(!userMission || userMission.status === 'rejected') && (
                      <label className="cursor-pointer flex-1">
                        <div className="w-full py-2 px-3 bg-blue-50 dark:bg-blue-900/30 hover:bg-blue-100 dark:hover:bg-blue-900/50 rounded-lg transition-colors inline-flex items-center justify-center gap-2 text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300">
                          {uploading === mission.id ? (
                            <>
                              <Loader2 className="w-4 h-4 animate-spin" />
                              <span className="text-sm">Enviando...</span>
                            </>
                          ) : (
                            <>
                              <Plus className="w-4 h-4" />
                              <span className="text-sm">Enviar Comprovante</span>
                            </>
                          )}
                        </div>
                      </label>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
      
      {/* Modal de Envio de Comprovante */}
      {showProofModal && selectedMission && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-800 rounded-xl max-w-lg w-full animate-fade-in">
            <div className="p-6 space-y-6">
              <div className="flex justify-between items-center">
                <h3 className="text-xl font-bold text-gray-900 dark:text-white">
                  {selectedMission.title}
                </h3>
                <button
                  onClick={() => setShowProofModal(false)}
                  className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>
              
              <div className="space-y-4">
                <div className="flex items-center gap-3 text-gray-600 dark:text-gray-300">
                  <Gift className="w-5 h-5 text-green-500" />
                  <span>{selectedMission.points_reward} pontos</span>
                </div>
                
                {selectedMission.link && (
                  <a
                    href={selectedMission.link}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="w-full py-3 px-4 bg-blue-50 dark:bg-blue-900/30 hover:bg-blue-100 dark:hover:bg-blue-900/50 rounded-lg transition-colors flex items-center justify-center gap-2 text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300"
                  >
                    <ExternalLink className="w-5 h-5" />
                    <span>Acessar Link da Missão</span>
                  </a>
                )}
                
                <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
                  <p className="text-gray-600 dark:text-gray-300 mb-4">
                    Envie uma foto ou captura de tela como prova da missão concluída
                  </p>
                  
                  <input
                    type="file"
                    accept="image/*"
                    className="hidden"
                    id="proof-upload"
                    onChange={(e) => {
                      const file = e.target.files?.[0];
                      if (file) {
                        handleFileUpload(selectedMission.id, file);
                      }
                    }}
                    disabled={uploading === selectedMission.id}
                  />
                  <label
                    htmlFor="proof-upload"
                    className={`w-full py-3 px-4 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white rounded-lg transition-all duration-200 flex items-center justify-center gap-2 cursor-pointer ${
                      uploading === selectedMission.id ? 'opacity-75 cursor-not-allowed' : 'hover:shadow-lg hover:-translate-y-0.5'
                    }`}
                  >
                    {uploading === selectedMission.id ? (
                      <>
                        <Loader2 className="w-5 h-5 animate-spin" />
                        <span>Enviando...</span>
                      </>
                    ) : (
                      <>
                        <ImageIcon className="w-5 h-5" />
                        <span>Enviar Comprovante</span>
                      </>
                    )}
                  </label>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}