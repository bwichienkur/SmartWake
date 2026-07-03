export default function DeliverabilityPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-2">Deliverability</h1>
      <p className="text-slate-400 mb-8">Domain health, ISP performance, and sending reputation</p>
      <div className="bg-emerald-900/20 border border-emerald-800/50 rounded-xl p-6 mb-6">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm text-emerald-400">Deliverability Health Score</p>
            <p className="text-4xl font-bold mt-1">—</p>
          </div>
          <p className="text-sm text-slate-400">Configure sending domain to see score</p>
        </div>
      </div>
      <div className="grid grid-cols-3 gap-4">
        {['SPF', 'DKIM', 'DMARC'].map((r) => (
          <div key={r} className="bg-slate-900/80 border border-slate-800 rounded-xl p-4 text-center">
            <p className="font-medium">{r}</p>
            <p className="text-xs text-slate-500 mt-1">Not configured</p>
          </div>
        ))}
      </div>
    </div>
  );
}
