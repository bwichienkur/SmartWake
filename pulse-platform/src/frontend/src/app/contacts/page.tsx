'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { api, type Contact } from '@/lib/api';

export default function ContactsPage() {
  const router = useRouter();
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [newEmail, setNewEmail] = useState('');
  const [newFirstName, setNewFirstName] = useState('');

  const load = () => {
    if (!api.getToken()) { router.push('/login'); return; }
    api.getContacts({ search: search || undefined })
      .then((r) => setContacts(r.items))
      .catch(() => router.push('/login'))
      .finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, [router, search]);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    await api.createContact({ email: newEmail, firstName: newFirstName });
    setShowCreate(false);
    setNewEmail('');
    setNewFirstName('');
    load();
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold">Contacts</h1>
          <p className="text-slate-400 mt-1">Unified customer profiles and engagement history</p>
        </div>
        <button onClick={() => setShowCreate(true)} className="bg-indigo-600 hover:bg-indigo-500 px-4 py-2 rounded-lg text-sm font-medium">
          Add Contact
        </button>
      </div>

      <div className="mb-4">
        <input
          type="search"
          placeholder="Search by name or email..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full max-w-md bg-slate-900 border border-slate-700 rounded-lg px-4 py-2 text-sm"
        />
      </div>

      {showCreate && (
        <form onSubmit={handleCreate} className="mb-6 bg-slate-900 border border-slate-700 rounded-xl p-4 flex gap-3 items-end">
          <div>
            <label className="text-xs text-slate-400">Email</label>
            <input required type="email" value={newEmail} onChange={(e) => setNewEmail(e.target.value)}
              className="block bg-slate-800 border border-slate-600 rounded px-3 py-1.5 text-sm mt-1" />
          </div>
          <div>
            <label className="text-xs text-slate-400">First Name</label>
            <input value={newFirstName} onChange={(e) => setNewFirstName(e.target.value)}
              className="block bg-slate-800 border border-slate-600 rounded px-3 py-1.5 text-sm mt-1" />
          </div>
          <button type="submit" className="bg-indigo-600 px-4 py-1.5 rounded text-sm">Create</button>
          <button type="button" onClick={() => setShowCreate(false)} className="text-slate-400 text-sm px-2">Cancel</button>
        </form>
      )}

      {loading ? (
        <p className="text-slate-400">Loading contacts...</p>
      ) : (
        <div className="bg-slate-900/80 border border-slate-800 rounded-xl overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-slate-800 text-slate-400">
                <th className="text-left p-4 font-medium">Contact</th>
                <th className="text-left p-4 font-medium">Status</th>
                <th className="text-left p-4 font-medium">Lifecycle</th>
                <th className="text-left p-4 font-medium">Engagement</th>
                <th className="text-left p-4 font-medium">Source</th>
              </tr>
            </thead>
            <tbody>
              {contacts.map((c) => (
                <tr key={c.id} className="border-b border-slate-800/50 hover:bg-slate-800/30">
                  <td className="p-4">
                    <div className="font-medium">{c.displayName}</div>
                    <div className="text-slate-500 text-xs">{c.email}</div>
                  </td>
                  <td className="p-4"><span className="px-2 py-0.5 rounded-full text-xs bg-emerald-900/50 text-emerald-300">{c.status}</span></td>
                  <td className="p-4 text-slate-400">{c.lifecycleStage || '—'}</td>
                  <td className="p-4">
                    <div className="flex items-center gap-2">
                      <div className="w-16 h-1.5 bg-slate-700 rounded-full overflow-hidden">
                        <div className="h-full bg-indigo-500 rounded-full" style={{ width: `${c.engagementScore}%` }} />
                      </div>
                      <span className="text-xs text-slate-500">{c.engagementScore}</span>
                    </div>
                  </td>
                  <td className="p-4 text-slate-400">{c.source || '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
