export default function ReportsPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-2">Reports</h1>
      <p className="text-slate-400 mb-8">Granular analytics with drill-down to individual contact events</p>
      <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
        {['Campaign Performance', 'Automation Performance', 'Revenue Attribution', 'Funnel Reporting', 'Cohort Analysis', 'Deliverability'].map((r) => (
          <div key={r} className="bg-slate-900/80 border border-slate-800 rounded-xl p-5 hover:border-indigo-600/50 cursor-pointer transition-colors">
            <h3 className="font-medium">{r}</h3>
            <p className="text-xs text-slate-500 mt-1">View report →</p>
          </div>
        ))}
      </div>
    </div>
  );
}
