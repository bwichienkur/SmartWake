import { useState, useEffect, useCallback } from "react";
import { api, type Message, type Contact, type Stats, type ComplianceReport, type ProviderHealth, type AnalyzeContentResponse } from "./api/client";
import { ComposePanel } from "./components/ComposePanel";
import { MessageList } from "./components/MessageList";
import { ContactList } from "./components/ContactList";
import { StatsBar } from "./components/StatsBar";
import { CompliancePanel } from "./components/CompliancePanel";
import { AiAnalyzer } from "./components/AiAnalyzer";

type Tab = "messages" | "contacts" | "compliance" | "ai";

export default function App() {
  const [tab, setTab] = useState<Tab>("messages");
  const [messages, setMessages] = useState<Message[]>([]);
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [stats, setStats] = useState<Stats | null>(null);
  const [compliance, setCompliance] = useState<ComplianceReport | null>(null);
  const [providers, setProviders] = useState<ProviderHealth[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<"" | "inbound" | "outbound">("");

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [statsData, messagesData, contactsData, complianceData, providersData] = await Promise.all([
        api.getStats(),
        api.getMessages(1, filter || undefined),
        api.getContacts(),
        api.getComplianceReport(),
        api.getProviderHealth(),
      ]);
      setStats(statsData);
      setMessages(messagesData.items);
      setContacts(contactsData);
      setCompliance(complianceData);
      setProviders(providersData);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load data");
    } finally {
      setLoading(false);
    }
  }, [filter]);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const handleSend = async (to: string, body: string, enableAi: boolean) => {
    await api.sendMessage(to, body, enableAi);
    await refresh();
  };

  const handleAddContact = async (name: string, phoneNumber: string) => {
    await api.createContact(name, phoneNumber);
    await refresh();
  };

  const handleDeleteContact = async (id: string) => {
    await api.deleteContact(id);
    await refresh();
  };

  const tabs: { id: Tab; label: string }[] = [
    { id: "messages", label: "Messages" },
    { id: "contacts", label: "Contacts" },
    { id: "compliance", label: "Compliance" },
    { id: "ai", label: "AI Studio" },
  ];

  return (
    <div className="app">
      <header className="header">
        <div className="header-brand">
          <div className="logo">EP</div>
          <div>
            <h1>Enterprise SMS Platform</h1>
            <p className="subtitle">Compliance-first messaging with AI intelligence and multi-provider failover</p>
          </div>
        </div>
        <div className="provider-pills">
          {providers.map((p) => (
            <span key={p.providerName} className={`provider-pill ${p.isHealthy ? "healthy" : "unhealthy"}`}>
              {p.providerName} · {(p.successRate * 100).toFixed(0)}%
            </span>
          ))}
        </div>
      </header>

      {stats && <StatsBar stats={stats} />}

      <nav className="tabs">
        {tabs.map((t) => (
          <button key={t.id} className={tab === t.id ? "tab active" : "tab"} onClick={() => setTab(t.id)}>
            {t.label}
          </button>
        ))}
      </nav>

      {error && <div className="banner banner-error">{error}</div>}

      <main className="main">
        {tab === "messages" && (
          <div className="messages-layout">
            <ComposePanel contacts={contacts} onSend={handleSend} />
            <div className="messages-panel">
              <div className="panel-header">
                <h2>Message History</h2>
                <div className="filters">
                  {(["", "outbound", "inbound"] as const).map((f) => (
                    <button key={f || "all"} className={filter === f ? "filter-btn active" : "filter-btn"} onClick={() => setFilter(f)}>
                      {f === "" ? "All" : f === "outbound" ? "Sent" : "Received"}
                    </button>
                  ))}
                  <button className="refresh-btn" onClick={refresh} disabled={loading}>Refresh</button>
                </div>
              </div>
              <MessageList messages={messages} loading={loading} />
            </div>
          </div>
        )}
        {tab === "contacts" && (
          <ContactList contacts={contacts} loading={loading} onAdd={handleAddContact} onDelete={handleDeleteContact} />
        )}
        {tab === "compliance" && compliance && <CompliancePanel report={compliance} />}
        {tab === "ai" && <AiAnalyzer onAnalyze={api.analyzeContent} />}
      </main>
    </div>
  );
}
