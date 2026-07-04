import { useState } from "react";
import type { Contact } from "../api/client";

interface Props {
  contacts: Contact[];
  loading: boolean;
  onAdd: (name: string, phoneNumber: string) => Promise<void>;
  onDelete: (id: string) => Promise<void>;
}

export function ContactList({ contacts, loading, onAdd, onDelete }: Props) {
  const [name, setName] = useState("");
  const [phoneNumber, setPhoneNumber] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError(null);
    try {
      await onAdd(name, phoneNumber);
      setName("");
      setPhoneNumber("");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to add contact");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="contacts-panel">
      <form className="contact-form" onSubmit={handleSubmit}>
        <h2>Add Contact</h2>
        <div className="form-row">
          <label>
            Name
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Jane Doe"
              required
            />
          </label>
          <label>
            Phone
            <input
              type="tel"
              value={phoneNumber}
              onChange={(e) => setPhoneNumber(e.target.value)}
              placeholder="+1 555 123 4567"
              required
            />
          </label>
          <button type="submit" className="btn-primary" disabled={saving}>
            {saving ? "Adding..." : "Add"}
          </button>
        </div>
        {error && <p className="form-error">{error}</p>}
      </form>

      {loading && contacts.length === 0 ? (
        <div className="empty-state">Loading contacts...</div>
      ) : contacts.length === 0 ? (
        <div className="empty-state">
          <p>No contacts yet</p>
          <p className="muted">Add contacts for quick access when composing messages</p>
        </div>
      ) : (
        <ul className="contact-list">
          {contacts.map((contact) => (
            <li key={contact.id} className="contact-item">
              <div className="contact-avatar">{contact.name.charAt(0).toUpperCase()}</div>
              <div className="contact-info">
                <strong>{contact.name}</strong>
                <span>{contact.phoneNumber}</span>
              </div>
              <button
                className="btn-danger"
                onClick={() => onDelete(contact.id)}
                aria-label={`Delete ${contact.name}`}
              >
                Delete
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
