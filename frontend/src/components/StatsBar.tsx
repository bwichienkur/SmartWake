import type { Stats } from "../api/client";

interface Props {
  stats: Stats;
}

export function StatsBar({ stats }: Props) {
  return (
    <div className="stats-bar">
      <div className="stat">
        <span className="stat-value">{stats.totalMessages}</span>
        <span className="stat-label">Total</span>
      </div>
      <div className="stat">
        <span className="stat-value">{stats.sent}</span>
        <span className="stat-label">Sent</span>
      </div>
      <div className="stat">
        <span className="stat-value">{stats.received}</span>
        <span className="stat-label">Received</span>
      </div>
      <div className="stat">
        <span className="stat-value">{stats.deliveryRate}%</span>
        <span className="stat-label">Delivery Rate</span>
      </div>
      <div className="stat">
        <span className="stat-value">{stats.blocked}</span>
        <span className="stat-label">Blocked</span>
      </div>
      <div className="stat">
        <span className="stat-value">{(stats.avgComplianceRisk * 100).toFixed(0)}%</span>
        <span className="stat-label">Avg AI Risk</span>
      </div>
    </div>
  );
}
