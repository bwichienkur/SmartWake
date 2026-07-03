'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { api, type Campaign } from '@/lib/api';

export default function CampaignsPage() {
  const router = useRouter();
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!api.getToken()) { router.push('/login'); return; }
    api.getCampaigns()
      .then((r) => setCampaigns(r.items))
      .catch(() => router.push('/login'))
      .finally(() => setLoading(false));
  }, [router]);

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold">Campaigns</h1>
          <p className="text-slate-400 mt-1">Email campaigns with A/B testing and approval workflows</p>
        </div>
        <button className="bg-indigo-600 hover:bg-indigo-500 px-4 py-2 rounded-lg text-sm font-medium">
          New Campaign
        </button>
      </div>

      {loading ? (
        <p className="text-slate-400">Loading campaigns...</p>
      ) : campaigns.length === 0 ? (
        <div className="bg-slate-900/80 border border-slate-800 rounded-xl p-12 text-center">
          <p className="text-slate-400 mb-4">No campaigns yet. Create your first email campaign.</p>
          <button className="bg-indigo-600 hover:bg-indigo-500 px-6 py-2 rounded-lg text-sm">Create Campaign</button>
        </div>
      ) : (
        <div className="grid gap-4">
          {campaigns.map((c) => (
            <div key={c.id} className="bg-slate-900/80 border border-slate-800 rounded-xl p-5 flex items-center justify-between">
              <div>
                <h3 className="font-medium">{c.name}</h3>
                <p className="text-sm text-slate-400">{c.subject || 'No subject'}</p>
              </div>
              <div className="flex items-center gap-6 text-sm">
                <span className="px-2 py-0.5 rounded-full text-xs bg-slate-800 text-slate-300">{c.status}</span>
                <div className="text-slate-400">{c.totalSent} sent</div>
                <div className="text-slate-400">{c.totalOpened} opens</div>
                <div className="text-emerald-400">${c.totalRevenue}</div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
