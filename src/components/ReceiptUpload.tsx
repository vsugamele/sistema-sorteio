import React, { useState, useEffect } from 'react';
import { Upload, CheckCircle, AlertCircle, Loader2, HelpCircle, X, Check } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface FileWithPreview extends File {
  preview?: string;
}

export function ReceiptUpload() {
  const [file, setFile] = useState<FileWithPreview | null>(null);
  const [platform, setPlatform] = useState('');
  const [amount, setAmount] = useState('');
  const [status, setStatus] = useState<'idle' | 'success' | 'error'>('idle');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showExampleModal, setShowExampleModal] = useState(false);
  const [showInstructionsModal, setShowInstructionsModal] = useState(false);
  const [dontShowAgain, setDontShowAgain] = useState(false);

  // Mostrar instruções quando o componente montar
  useEffect(() => {
    const shouldShow = localStorage.getItem('showInstructions') !== 'false';
    setShowInstructionsModal(shouldShow);
  }, []);

  const handleDontShowAgain = () => {
    setDontShowAgain(!dontShowAgain);
  };

  const handleCloseInstructions = () => {
    setShowInstructionsModal(false);
    if (dontShowAgain) {
      localStorage.setItem('showInstructions', 'false');
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = e.target.files?.[0];
    if (selectedFile) {
      const fileWithPreview = selectedFile as FileWithPreview;
      if (selectedFile.type.startsWith('image/')) {
        fileWithPreview.preview = URL.createObjectURL(selectedFile);
      }
      setFile(fileWithPreview);
      setStatus('idle');
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    setIsSubmitting(true);
    
    if (!file || !platform || !amount) {
      setStatus('error');
      setIsSubmitting(false);
      return;
    }

    try {
      // Criar nome único para o arquivo
      const fileExt = file.name.split('.').pop();
      const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`;
      const filePath = `receipts/${fileName}`;

      // Upload do arquivo para o Storage do Supabase
      const { error: uploadError, data: uploadData } = await supabase.storage
        .from('receipts')
        .upload(filePath, file);

      if (uploadError) throw uploadError;

      // Obter URL pública do arquivo
      const { data: urlData } = await supabase.storage
        .from('receipts')
        .getPublicUrl(filePath);

      if (!urlData?.publicUrl) {
        throw new Error('Erro ao gerar URL do comprovante');
      }

      // Garantir que a URL seja acessível
      const response = await fetch(urlData.publicUrl, { method: 'HEAD' });
      if (!response.ok) {
        throw new Error('URL do comprovante não está acessível');
      }

      // Inserir o depósito na tabela
      const { error: depositError } = await supabase
        .from('deposits')
        .insert([
          {
            amount: parseFloat(amount),
            platform,
            receipt_url: urlData.publicUrl,
            status: 'pending'
          }
        ]);

      if (depositError) throw depositError;

      setStatus('success');
      console.log('Comprovante enviado com sucesso:', urlData.publicUrl);

      // Limpar formulário após sucesso
      setFile(null);
      setAmount('');
      setPlatform('');
      setIsSubmitting(false);
    } catch (error) {
      console.error('Erro ao enviar comprovante:', error instanceof Error ? error.message : error);
      setStatus('error');
      setIsSubmitting(false);
    }
  };

  return (
    <div className="w-full bg-white dark:bg-gray-800 rounded-xl shadow-lg p-4 sm:p-6">
      <h2 className="text-xl sm:text-2xl font-bold text-gray-800 dark:text-white mb-4 sm:mb-6">
        Registre sua Participação
      </h2>
      
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="space-y-2">
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-200">
            Plataforma
          </label>
          <select
            value={platform}
            onChange={(e) => setPlatform(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
            required
          >
            <option value="">Selecione a plataforma</option>
            <option value="BR4BET">BR4BET</option>
            <option value="LOTOGREEN">LOTOGREEN</option>
            <option value="MCGAMES">MCGAMES</option>
            <option value="GOLDEBET">GOLDEBET</option>
            <option value="ONABET">ONABET</option>
            <option value="SEGUROBET">SEGUROBET</option>
          </select>
        </div>

        <div className="space-y-2">
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-200">
            Valor do Depósito
          </label>
          <input
            type="number"
            step="0.01"
            min="0"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
            placeholder="Digite o valor do depósito"
            required
          />
        </div>

        <div className="space-y-2">
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-200">
            Arquivo (Envie seu Comprovante)
            <button
              type="button"
              onClick={() => setShowExampleModal(true)}
              className="ml-2 inline-flex items-center text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 text-sm"
            >
              <HelpCircle className="w-4 h-4 mr-1" />
              Ver exemplo
            </button>
          </label>
          <div className="relative">
            <input
              type="file"
              onChange={handleFileChange}
              accept="image/*,.pdf"
              className="hidden"
              id="file-upload"
            />
            <label
              htmlFor="file-upload"
              className="flex items-center justify-center w-full px-3 sm:px-4 py-4 sm:py-6 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg cursor-pointer hover:border-blue-500 transition-colors"
            >
              {file ? (
                <div className="space-y-2 text-center">
                  {file.preview ? (
                    <img
                      src={file.preview}
                      alt="Preview"
                      className="mx-auto h-24 sm:h-32 w-auto object-cover rounded"
                    />
                  ) : (
                    <div className="flex items-center justify-center">
                      <CheckCircle className="w-6 h-6 sm:w-8 sm:h-8 text-green-500 dark:text-green-400" />
                    </div>
                  )}
                  <span className="text-xs sm:text-sm text-gray-600 dark:text-gray-300">{file.name}</span>
                </div>
              ) : (
                <div className="text-center">
                  <Upload className="mx-auto h-8 w-8 sm:h-12 sm:w-12 text-gray-400" />
                  <p className="mt-2 text-xs sm:text-sm text-gray-600 dark:text-gray-300">
                    Clique para fazer upload
                  </p>
                  <p className="text-xs hidden sm:block text-gray-500 dark:text-gray-400">
                    PDF ou imagens (máx. 10MB)
                  </p>
                </div>
              )}
            </label>
          </div>
        </div>

        {status === 'error' && (
          <div className="flex items-center gap-2 text-red-600 dark:text-red-400">
            <AlertCircle className="w-5 h-5" />
            <span className="text-sm">
              Ocorreu um erro. Tente novamente.
            </span>
          </div>
        )}

        {status === 'success' && (
          <div className="flex items-center gap-2 text-green-600 dark:text-green-400">
            <CheckCircle className="w-5 h-5" />
            <span className="text-sm">
              Comprovante enviado com sucesso!
            </span>
          </div>
        )}

        <button
          type="submit"
          disabled={isSubmitting}
          className={`w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition-all focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 flex items-center justify-center gap-2 ${
            isSubmitting ? 'opacity-75 cursor-not-allowed' : ''
          }`}
          aria-busy={isSubmitting}
          aria-disabled={isSubmitting}
        >
          {isSubmitting ? (
            <>
              <Loader2 className="w-5 h-5 animate-spin" aria-hidden="true" />
              <span>Registrando...</span>
            </>
          ) : (
            'Registre sua Participação'
          )}
        </button>
      </form>

      {/* Modal de Exemplo */}
      {showExampleModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-800 rounded-xl p-6 max-w-md w-full">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                Exemplo de Comprovante
              </h3>
              <button
                onClick={() => setShowExampleModal(false)}
                className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            <div className="relative aspect-[9/16] w-full bg-gray-100 dark:bg-gray-700 rounded-lg overflow-hidden">
              <div className="absolute inset-0 flex flex-col items-center justify-center p-6 text-center">
                <AlertCircle className="w-12 h-12 text-gray-400 dark:text-gray-500 mb-4" />
                <p className="text-gray-600 dark:text-gray-400 text-sm">
                  Envie uma foto clara do comprovante mostrando:
                </p>
                <ul className="mt-4 text-left text-sm text-gray-600 dark:text-gray-400 space-y-2">
                  <li className="flex items-center gap-2">
                    <CheckCircle className="w-4 h-4 text-green-500" />
                    Valor do depósito
                  </li>
                  <li className="flex items-center gap-2">
                    <CheckCircle className="w-4 h-4 text-green-500" />
                    Data e hora
                  </li>
                  <li className="flex items-center gap-2">
                    <CheckCircle className="w-4 h-4 text-green-500" />
                    Nome/CNPJ do destinatário
                  </li>
                  <li className="flex items-center gap-2">
                    <CheckCircle className="w-4 h-4 text-green-500" />
                    Comprovante completo e legível
                  </li>
                </ul>
              </div>
            </div>
            <p className="mt-6 text-sm text-gray-600 dark:text-gray-300">
              Certifique-se que todas as informações estejam visíveis e legíveis no comprovante.
            </p>
          </div>
        </div>
      )}

      {/* Modal de Instruções Inicial */}
      {showInstructionsModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-800 rounded-xl p-6 max-w-lg w-full animate-fade-in">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
                Como Participar
              </h3>
              <button
                onClick={handleCloseInstructions}
                className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            
            <div className="space-y-6">
              <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
                <h4 className="text-lg font-semibold text-blue-700 dark:text-blue-300 mb-2">
                  Siga os passos abaixo:
                </h4>
                <ol className="space-y-4 text-gray-600 dark:text-gray-300">
                  <li className="flex items-start gap-3">
                    <span className="flex-shrink-0 w-6 h-6 bg-blue-100 dark:bg-blue-800 rounded-full flex items-center justify-center text-blue-600 dark:text-blue-400 font-medium">
                      1
                    </span>
                    <span>Selecione a plataforma onde você fez o depósito</span>
                  </li>
                  <li className="flex items-start gap-3">
                    <span className="flex-shrink-0 w-6 h-6 bg-blue-100 dark:bg-blue-800 rounded-full flex items-center justify-center text-blue-600 dark:text-blue-400 font-medium">
                      2
                    </span>
                    <span>Digite o valor exato do depósito realizado</span>
                  </li>
                  <li className="flex items-start gap-3">
                    <span className="flex-shrink-0 w-6 h-6 bg-blue-100 dark:bg-blue-800 rounded-full flex items-center justify-center text-blue-600 dark:text-blue-400 font-medium">
                      3
                    </span>
                    <span>Faça o upload do comprovante de depósito (foto ou PDF)</span>
                  </li>
                </ol>
              </div>
              
              <div className="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-4">
                <h4 className="text-lg font-semibold text-yellow-700 dark:text-yellow-300 mb-2 flex items-center gap-2">
                  <AlertCircle className="w-5 h-5" />
                  Importante
                </h4>
                <ul className="space-y-2 text-gray-600 dark:text-gray-300">
                  <li className="flex items-center gap-2">
                    <CheckCircle className="w-4 h-4 text-green-500" />
                    O comprovante deve estar legível
                  </li>
                  <li className="flex items-center gap-2">
                    <CheckCircle className="w-4 h-4 text-green-500" />
                    Todas as informações devem estar visíveis
                  </li>
                  <li className="flex items-center gap-2">
                    <CheckCircle className="w-4 h-4 text-green-500" />
                    Aguarde a aprovação do seu comprovante
                  </li>
                </ul>
              </div>
            </div>

            <div className="mt-6 space-y-4">
              <label className="flex items-center gap-2 cursor-pointer group">
                <div 
                  className={`w-5 h-5 rounded border transition-colors ${
                    dontShowAgain 
                      ? 'bg-blue-600 border-blue-600 group-hover:bg-blue-700' 
                      : 'border-gray-300 dark:border-gray-600 group-hover:border-blue-500'
                  }`}
                  onClick={handleDontShowAgain}
                >
                  {dontShowAgain && (
                    <Check className="w-4 h-4 text-white" />
                  )}
                </div>
                <span 
                  className="text-sm text-gray-600 dark:text-gray-300"
                  onClick={handleDontShowAgain}
                >
                  Não mostrar novamente
                </span>
              </label>

              <button
                onClick={handleCloseInstructions}
                className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white py-3 px-6 rounded-xl font-medium text-lg shadow-lg hover:shadow-xl transition-all duration-200 hover:-translate-y-0.5"
              >
                Entendi, vamos começar!
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}