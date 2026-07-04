import { useState } from "react";
import type { AnalyzeContentResponse } from "../api/client";

interface Props {
  onAnalyze: (body: string, intent: string) => Promise<AnalyzeContentResponse>;
}

export function AiAnalyzer({ onAnalyze }: Props) {
  const [body, setBody] = useState("");
  const [intent, setIntent] = useState("Transactional");
  const [result, setResult] = useState<AnalyzeContentResponse | null>(null);
  const [loading, setLoading] = useState(false);

  const handleAnalyze = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      setResult(await onAnalyze(body, intent));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="ai-panel">
      <h2>AI Content Studio</h2>
      <p className="muted">Analyze compliance risk, optimize content, and detect issues before sending</p>

      <form onSubmit={handleAnalyze}>
        <label>
          Intent
          <select value={intent} onChange={(e) => setIntent(e.target.value)}>
            {["Otp", "Transactional", "CustomerCare", "Notification", "Marketing", "Events"].map((i) => (
              <option key={i} value={i}>{i}</option>
            ))}
          </select>
        </label>
        <label>
          Message Body
          <textarea value={body} onChange={(e) => setBody(e.target.value)} rows={5} placeholder="Enter message to analyze..." required />
        </label>
        <button type="submit" className="btn-primary" disabled={loading}>{loading ? "Analyzing..." : "Analyze with AI"}</button>
      </form>

      {result && (
        <div className="ai-result">
          <div className={`risk-badge risk-${result.riskLevel.toLowerCase()}`}>
            Risk: {result.riskLevel} ({(result.complianceRiskScore * 100).toFixed(0)}%)
          </div>
          {result.issues.length > 0 && (
            <ul className="issue-list">
              {result.issues.map((issue) => <li key={issue}>{issue}</li>)}
            </ul>
          )}
          {result.suggestedBody && (
            <div className="suggestion">
              <strong>Suggested improvement:</strong>
              <p>{result.suggestedBody}</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
