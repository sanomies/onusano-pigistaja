import { useState, useEffect } from 'react';
import { db } from './supabase';
import LoginGate from './components/LoginGate';
import Dashboard from './components/Dashboard';

export default function App() {
  const [user, setUser]   = useState(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    db.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      setReady(true);
    });
  }, []);

  if (!ready) return null;

  return user
    ? <Dashboard user={user} onLogout={() => setUser(null)} />
    : <LoginGate onLogin={setUser} />;
}
