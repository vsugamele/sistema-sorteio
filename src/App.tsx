import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { SignUp } from './components/SignUp';
import { Login } from './components/Login';
import { Missions } from './components/Missions';
import { AdminPanel } from './components/AdminPanel';
import { PromoMessage } from './components/PromoMessage';
import { Navigation } from './components/Navigation';
import { Messages } from './components/Messages';
import Roulette from './components/Roulette';
import { PointsProvider } from './contexts/PointsContext';
import { ProtectedRoute } from './components/ProtectedRoute';
import { AccessDenied } from './components/AccessDenied';

function App() {
  return (
    <PointsProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<SignUp />} />
          <Route path="/acesso-negado" element={<AccessDenied />} />
          
          <Route path="/receipt" element={
            <ProtectedRoute>
              <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-900 dark:to-gray-800">
                <Navigation />
                <div className="max-w-2xl mx-auto p-4 pt-4 sm:pt-4">
                  <PromoMessage />
                </div>
                <Messages />
              </div>
            </ProtectedRoute>
          } />
          
          <Route path="/roulette" element={
            <ProtectedRoute>
              <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-900 dark:to-gray-800">
                <Navigation />
                <div className="max-w-4xl mx-auto p-4 pt-4 sm:pt-4">
                  <Roulette />
                </div>
                <Messages />
              </div>
            </ProtectedRoute>
          } />
          
          <Route path="/missions" element={
            <ProtectedRoute>
              <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-900 dark:to-gray-800">
                <Navigation />
                <div className="max-w-4xl mx-auto p-4 pt-4 sm:pt-4">
                  <Missions />
                </div>
                <Messages />
              </div>
            </ProtectedRoute>
          } />
          
          <Route path="/admin" element={
            <ProtectedRoute>
              <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-900 dark:to-gray-800">
                <Navigation />
                <div className="max-w-7xl mx-auto p-4 pt-4 sm:pt-4">
                  <AdminPanel />
                </div>
                <Messages />
              </div>
            </ProtectedRoute>
          } />
          
          <Route path="/" element={<Navigate to="/login" replace />} />
          
          {/* Redirecionar qualquer outra rota para login */}
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </Router>
    </PointsProvider>
  );
}

export default App;
