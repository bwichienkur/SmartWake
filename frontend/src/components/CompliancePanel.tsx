import type { ComplianceReport } from "../api/client";

interface Props {
  report: ComplianceReport;
}

export function CompliancePanel({ report }: Props) {
  return (
    <div className="compliance-panel">
      <h2>Compliance Dashboard</h2>
      <p className="muted">Automated TCPA/CTIA enforcement at the message router layer</p>

      <div className="compliance-grid">
        <div className="stat"><span className="stat-value">{report.optOutCount}</span><span className="stat-label">Opt-Outs</span></div>
        <div className="stat"><span className="stat-value">{report.blockedMessages}</span><span className="stat-label">Blocked</span></div>
        <div className="stat"><span className="stat-value">{report.scheduledMessages}</span><span className="stat-label">Quiet-Hour Deferred</span></div>
        <div className="stat"><span className="stat-value">{report.highRiskMessages}</span><span className="stat-label">High AI Risk</span></div>
      </div>

      <section className="compliance-section">
        <h3>Top Block Reasons</h3>
        {report.topBlockReasons.length === 0 ? (
          <p className="muted">No blocked messages yet</p>
        ) : (
          <ul className="reason-list">
            {report.topBlockReasons.map((reason) => (
              <li key={reason}>{reason}</li>
            ))}
          </ul>
        )}
      </section>

      <section className="compliance-section">
        <h3>Built-in Protections</h3>
        <ul className="feature-list">
          <li>Automatic STOP/UNSUBSCRIBE keyword processing</li>
          <li>Quiet hours enforcement for marketing (8 PM – 8 AM local)</li>
          <li>Spam content detection and review queue</li>
          <li>10DLC campaign tracking and rate limits</li>
          <li>Tamper-evident audit trail per message</li>
        </ul>
      </section>
    </div>
  );
}
