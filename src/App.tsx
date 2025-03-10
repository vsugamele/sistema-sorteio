import React from 'react';
import { SignUp } from './components/SignUp';
import { Login } from './components/Login';
import { ReceiptUpload } from './components/ReceiptUpload';
import { Missions } from './components/Missions';
import { AdminPanel } from './components/AdminPanel';
import { PromoMessage } from './components/PromoMessage';
import { Navigation } from './components/Navigation';
import { Trophy } from 'lucide-react';
import Roulette from './components/Roulette';
import { PointsProvider } from './contexts/PointsContext';

export type View = 'login' | 'signup' | 'receipt' | 'admin' | 'roulette' | 'missions';
export type ViewSetter = (view: View) => void;

function App() {
  const [view, setView] = React.useState<View>('login');

  return (
    <PointsProvider>
    <>
      {view === 'login' && (
        <Login 
          onLoginSuccess={() => setView('receipt')}
          onSignUpClick={() => setView('signup')}
        />
      )}
      {view === 'signup' && <SignUp onLoginClick={() => setView('login')} />}
      {view === 'receipt' && (
        <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-900 dark:to-gray-800">
          <Navigation setView={setView} />
          <div className="max-w-2xl mx-auto p-4 pt-32 sm:pt-40">
            <PromoMessage setView={setView} />
          </div>
        </div>
      )}
      {view === 'roulette' && (
        <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-900 dark:to-gray-800">
          <Navigation setView={setView} />
          <div className="max-w-4xl mx-auto p-4 pt-24 sm:pt-32">
            <Roulette setView={setView} />
          </div>
        </div>
      )}
      {view === 'missions' && (
        <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-900 dark:to-gray-800">
          <Navigation setView={setView} />
          <div className="max-w-4xl mx-auto p-4 pt-24 sm:pt-32">
            <Missions setView={setView} />
          </div>
        </div>
      )}
      {view === 'admin' && (
        <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-900 dark:to-gray-800">
          <Navigation setView={setView} />
          <div className="pt-24 sm:pt-32">
            <AdminPanel setView={setView} />
          </div>
        </div>
      )}
    </>
    </PointsProvider>
  );
}

export default App;
