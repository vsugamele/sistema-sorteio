import { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { SignUp } from './components/SignUp';
import { Login } from './components/Login';
import { Missions } from './components/Missions';
import { AdminPanel } from './components/AdminPanel';
import { PromoMessage } from './components/PromoMessage';
import { Navigation } from './components/Navigation';
import Roulette from './components/Roulette';
import { PointsProvider } from './contexts/PointsContext';
import { ProtectedRoute } from './components/ProtectedRoute';
import { AccessDenied } from './components/AccessDenied';

export type View = 'login' | 'signup' | 'receipt' | 'admin' | 'roulette' | 'missions';
export type ViewSetter = (view: View) => void;

function App() {
  // Mantemos o estado view para compatibilidade com componentes existentes
  const [, setView] = useState<View>('login');

  return (
    <PointsProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login onLoginSuccess={() => setView('receipt')} onSignUpClick={() => setView('signup')} />} />
          <Route path="/signup" element={<SignUp onLoginClick={() => setView('login')} />} />
          <Route path="/acesso-negado" element={<AccessDenied />} />
          
          <Route path="/receipt" element={
            <ProtectedRoute>
              <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-900 dark:to-gray-800">
                <Navigation setView={setView} />
                <div className="max-w-2xl mx-auto p-4 pt-32 sm:pt-40">
                  <PromoMessage setView={setView} />
                </div>
              </div>
            </ProtectedRoute>
          } />
          
          <Route path="/roulette" element={
            <ProtectedRoute>
              <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-900 dark:to-gray-800">
                <Navigation setView={setView} />
                <div className="max-w-4xl mx-auto p-4 pt-24 sm:pt-32">
                  <Roulette setView={setView} />
                </div>
              </div>
            </ProtectedRoute>
          } />
          
          <Route path="/missions" element={
            <ProtectedRoute>
              <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-900 dark:to-gray-800">
                <Navigation setView={setView} />
                <div className="max-w-4xl mx-auto p-4 pt-24 sm:pt-32">
                  <Missions setView={setView} />
                </div>
              </div>
            </ProtectedRoute>
          } />
          
          <Route path="/admin" element={
            <ProtectedRoute adminOnly={true}>
              <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-900 dark:to-gray-800">
                <Navigation setView={setView} />
                <div className="max-w-7xl mx-auto p-4 pt-24 sm:pt-32">
                  <AdminPanel setView={setView} />
                </div>
              </div>
            </ProtectedRoute>
          } />
          
          <Route path="/" element={<Navigate to="/login" replace />} />
        </Routes>
      </Router>
    </PointsProvider>
  );
}

export default App;
