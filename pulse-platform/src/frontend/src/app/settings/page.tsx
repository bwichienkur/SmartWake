export default function SettingsPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-2">Settings</h1>
      <p className="text-slate-400 mb-8">Workspace configuration, team, API keys, and billing</p>
      <div className="space-y-4">
        {['Team & Permissions', 'API Keys', 'Brands', 'Integrations', 'Billing & Usage', 'Data Retention', 'Audit Log'].map((s) => (
          <div key={s} className="bg-slate-900/80 border border-slate-800 rounded-xl p-4 flex items-center justify-between">
            <span>{s}</span>
            <span className="text-slate-500 text-sm">→</span>
          </div>
        ))}
      </div>
    </div>
  );
}
