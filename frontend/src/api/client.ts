export interface Message {
  id: string;
  direction: "inbound" | "outbound" | string;
  status: string;
  intent: string;
  priority: string;
  fromNumber: string;
  toNumber: string;
  body: string;
  providerName?: string | null;
  complianceDecision?: string | null;
  createdAt: string;
  scheduledFor?: string | null;
  sentAt?: string | null;
  aiInsight?: AiInsight | null;
}

export interface AiInsight {
  sentiment: string;
  sentimentScore: number;
  complianceRiskScore: number;
  suggestedPriority?: string | null;
  contentSuggestions?: string | null;
  requiresHumanReview: boolean;
}

export interface Contact {
  id: string;
  name: string;
  phoneNumber: string;
  email?: string | null;
  consentStatus: string;
  createdAt: string;
}

export interface Stats {
  totalMessages: number;
  sent: number;
  received: number;
  blocked: number;
  failed: number;
  contacts: number;
  deliveryRate: number;
  avgComplianceRisk: number;
}

export interface ComplianceReport {
  optOutCount: number;
  blockedMessages: number;
  scheduledMessages: number;
  highRiskMessages: number;
  topBlockReasons: string[];
}

export interface ProviderHealth {
  providerName: string;
  isHealthy: boolean;
  successRate: number;
  consecutiveFailures: number;
}

export interface PaginatedMessages {
  items: Message[];
  total: number;
  page: number;
  pageSize: number;
}

export interface AnalyzeContentResponse {
  complianceRiskScore: number;
  riskLevel: string;
  issues: string[];
  suggestedBody?: string | null;
  recommendedIntent?: string | null;
}

const API_KEY = import.meta.env.VITE_API_KEY ?? "";

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const res = await fetch(`/api${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      "X-Api-Key": API_KEY,
      ...options.headers,
    },
  });

  if (!res.ok) {
    const error = await res.json().catch(() => ({ error: res.statusText }));
    throw new Error(error.error ?? "Request failed");
  }

  if (res.status === 204) return undefined as T;
  return res.json();
}

export const api = {
  getStats: () => request<Stats>("/analytics/stats"),
  getComplianceReport: () => request<ComplianceReport>("/analytics/compliance"),
  getProviderHealth: () => request<ProviderHealth[]>("/analytics/providers"),
  getMessages: (page = 1, direction?: string) =>
    request<PaginatedMessages>(`/messages?page=${page}&pageSize=20${direction ? `&direction=${direction}` : ""}`),
  sendMessage: (to: string, body: string, enableAiOptimization = false) =>
    request("/messages/send", {
      method: "POST",
      body: JSON.stringify({ to, body, enableAiOptimization, intent: "Transactional" }),
    }),
  getContacts: () => request<Contact[]>("/contacts"),
  createContact: (name: string, phoneNumber: string) =>
    request<Contact>("/contacts", { method: "POST", body: JSON.stringify({ name, phoneNumber, consentStatus: "OptedIn" }) }),
  deleteContact: (id: string) => request<void>(`/contacts/${id}`, { method: "DELETE" }),
  analyzeContent: (body: string, intent = "Transactional") =>
    request<AnalyzeContentResponse>("/ai/analyze", { method: "POST", body: JSON.stringify({ body, intent }) }),
};
