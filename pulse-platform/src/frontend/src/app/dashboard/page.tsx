'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { api, type ExecutiveDashboard } from '@/lib/api';

function MetricCard({ label, value, sub, trend }: { label: string; value: string | number; sub?: string; trend?: 'up' | 'down' }) {
  return (
    <div className="bg-slate-900/80 border border-slate-800 rounded-xl p-5">
      <p className="text-sm text-slate-400">{label}</p>
      <p className="text-2xl font-semibold mt-1">{value}</p>
      {sub && (
        <p className={`text-xs mt-1 ${trend === 'up' ? 'text-emerald-400' : trend === 'down' ? 'text-red-400' : 'text-slate-500'}`}>
          {sub}
        </p>
      )}
    </div>
  );
}

export default function DashboardPage() {
  const router = useRouter();
  const [data, setData] = useState<ExecutiveDashboard | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!api.getToken()) { router.push('/login'); return; }
    api.getExecutiveDashboard()
      .then(setData)
      .catch(() => router.push('/login'))
      .finally(() => setLoading(false));
  }, [router]);

  if (loading) return <div className="text-slate-400">Loading dashboard...</div>;
  if (!data) return null;

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold">Executive Dashboard</h1>
        <p className="text-slate-400 mt-1">Last 30 days performance overview</p>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <MetricCard label="Total Contacts" value={data.totalContacts.toLocaleString()} sub={`+${data.contactGrowth} new`} trend="up" />
        <MetricCard label="Emails Sent" value={data.totalSent.toLocaleString()} />
        <MetricCard label="Open Rate" value={`${data.openRate}%`} sub={`${data.totalOpened.toLocaleString()} opens`} />
        <MetricCard label="Revenue" value={`$${data.totalRevenue.toLocaleString()}`} trend="up" />
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <MetricCard label="Delivery Rate" value={`${data.deliveryRate}%`} />
        <MetricCard label="Click Rate" value={`${data.clickRate}%`} sub={`${data.totalClicked.toLocaleString()} clicks`} />
        <MetricCard label="Bounce Rate" value={`${data.bounceRate}%`} trend={data.bounceRate > 2 ? 'down' : undefined} />
        <MetricCard label="Delivered" value={data.totalDelivered.toLocaleString()} />
      </div>

      <div className="bg-slate-900/80 border border-slate-800 rounded-xl p-6">
        <h2 className="text-lg font-semibold mb-4">Onboarding Checklist</h2>
        <div className="space-y-3">
          {[
            { label: 'Verify sending domain (SPF/DKIM/DMARC)', done: false },
            { label: 'Import your first contacts', done: data.totalContacts > 3 },
            { label: 'Create your first campaign', done: false },
            { label: 'Set up an automation workflow', done: false },
            { label: 'Connect ecommerce integration', done: false },
          ].map((item) => (
            <div key={item.label} className="flex items-center gap-3">
              <span className={`w-5 h-5 rounded-full border flex items-center justify-center text-xs ${item.done ? 'bg-emerald-600 border-emerald-600' : 'border-slate-600'}`}>
                {item.done ? '✓' : ''}
              </span>
              <span className={item.done ? 'text-slate-400 line-through' : ''}>{item.label}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
