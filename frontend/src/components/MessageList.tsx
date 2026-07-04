import type { Message } from "../api/client";

interface Props {
  messages: Message[];
  loading: boolean;
}

function formatTime(iso: string): string {
  return new Date(iso).toLocaleString(undefined, {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function statusClass(status: string): string {
  return `status status-${status}`;
}

export function MessageList({ messages, loading }: Props) {
  if (loading && messages.length === 0) {
    return <div className="empty-state">Loading messages...</div>;
  }

  if (messages.length === 0) {
    return (
      <div className="empty-state">
        <p>No messages yet</p>
        <p className="muted">Send your first SMS using the compose panel</p>
      </div>
    );
  }

  return (
    <ul className="message-list">
      {messages.map((msg) => (
        <li key={msg.id} className={`message-item message-${msg.direction}`}>
          <div className="message-meta">
            <span className={`direction-badge ${msg.direction.toLowerCase()}`}>
              {msg.direction.toLowerCase() === "outbound" ? "Sent" : "Received"}
            </span>
            {msg.complianceDecision && (
              <span className="status">{msg.complianceDecision}</span>
            )}
            {msg.aiInsight && (
              <span className={`status ${msg.aiInsight.sentiment.toLowerCase()}`}>
                {msg.aiInsight.sentiment}
              </span>
            )}
            <span className={statusClass(msg.status)}>{msg.status}</span>
            <time>{formatTime(msg.createdAt)}</time>
          </div>
          <div className="message-numbers">
            <span>{msg.fromNumber}</span>
            <span className="arrow">→</span>
            <span>{msg.toNumber}</span>
          </div>
          <p className="message-body">{msg.body}</p>
        </li>
      ))}
    </ul>
  );
}
