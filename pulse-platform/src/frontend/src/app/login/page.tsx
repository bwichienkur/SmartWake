'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { api } from '@/lib/api';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('admin@pulse.demo');
  const [password, setPassword] = useState('PulseDemo123!');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const res = await api.login(email, password);
      api.setToken(res.accessToken);
      router.push('/dashboard');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-950">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold"><span className="text-indigo-400">Pulse</span></h1>
          <p className="text-slate-400 mt-2">Enterprise Marketing Platform</p>
        </div>
        <form onSubmit={handleSubmit} className="bg-slate-900 border border-slate-800 rounded-xl p-8 space-y-4">
          {error && <div className="bg-red-900/30 border border-red-800 text-red-300 text-sm p-3 rounded-lg">{error}</div>}
          <div>
            <label className="text-sm text-slate-400">Email</label>
            <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required
              className="w-full mt-1 bg-slate-800 border border-slate-700 rounded-lg px-4 py-2.5 text-sm" />
          </div>
          <div>
            <label className="text-sm text-slate-400">Password</label>
            <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} required
              className="w-full mt-1 bg-slate-800 border border-slate-700 rounded-lg px-4 py-2.5 text-sm" />
          </div>
          <button type="submit" disabled={loading}
            className="w-full bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 py-2.5 rounded-lg font-medium text-sm">
            {loading ? 'Signing in...' : 'Sign In'}
          </button>
          <p className="text-center text-sm text-slate-500">
            Demo: admin@pulse.demo / PulseDemo123!
          </p>
        </form>
      </div>
    </div>
  );
}
