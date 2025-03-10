import { Link } from 'react-router-dom';
import { Shield, AlertTriangle } from 'lucide-react';

export function AccessDenied() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50 p-4">
      <div className="max-w-md w-full bg-white rounded-lg shadow-lg overflow-hidden">
        <div className="bg-red-600 p-6 flex justify-center">
          <Shield className="text-white h-16 w-16" />
        </div>
        
        <div className="p-6">
          <div className="flex items-center justify-center mb-4">
            <AlertTriangle className="text-red-600 mr-2 h-6 w-6" />
            <h1 className="text-2xl font-bold text-gray-800">Acesso Negado</h1>
          </div>
          
          <p className="text-gray-600 mb-6 text-center">
            Você não tem permissão para acessar esta página. 
            Se você acredita que isso é um erro, entre em contato com um administrador.
          </p>
          
          <div className="flex justify-center">
            <Link 
              to="/" 
              className="px-4 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 transition-colors"
            >
              Voltar para a página inicial
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
