import { useState } from "react";
import type { Contact } from "../api/client";

interface Props {
  contacts: Contact[];
  onSend: (to: string, body: string, enableAi: boolean) => Promise<void>;
}

export function ComposePanel({ contacts, onSend }: Props) {
  const [to, setTo] = useState("");
  const [body, setBody] = useState("");
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [enableAi, setEnableAi] = useState(true);

  const charCount = body.length;
  const segments = Math.ceil(charCount / 160) || 1;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSending(true);
    setError(null);
    setSuccess(false);

    try {
      await onSend(to, body, enableAi);
      setBody("");
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to send");
    } finally {
      setSending(false);
    }
  };

  const selectContact = (phone: string) => {
    setTo(phone);
  };

  return (
    <aside className="compose-panel">
      <h2>Compose</h2>
      <form onSubmit={handleSubmit}>
        <label>
          To
          <input
            type="tel"
            value={to}
            onChange={(e) => setTo(e.target.value)}
            placeholder="+1 555 123 4567"
            required
          />
        </label>

        {contacts.length > 0 && (
          <div className="quick-contacts">
            {contacts.slice(0, 5).map((c) => (
              <button
                key={c.id}
                type="button"
                className="contact-chip"
                onClick={() => selectContact(c.phoneNumber)}
              >
                {c.name}
              </button>
            ))}
          </div>
        )}

        <label>
          Message
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            placeholder="Type your message..."
            rows={5}
            maxLength={1600}
            required
          />
          <span className="char-count">
            {charCount} chars · {segments} segment{segments !== 1 ? "s" : ""}
          </span>
        </label>

        <label className="checkbox-label">
          <input type="checkbox" checked={enableAi} onChange={(e) => setEnableAi(e.target.checked)} />
          Enable AI compliance optimization
        </label>

        {error && <p className="form-error">{error}</p>}
        {success && <p className="form-success">Message sent!</p>}

        <button type="submit" className="btn-primary" disabled={sending}>
          {sending ? "Sending..." : "Send SMS"}
        </button>
      </form>
    </aside>
  );
}
