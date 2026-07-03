const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

export interface AuthResponse {
  accessToken: string;
  tokenType: string;
  expiresIn: number;
  user: { id: string; email: string; firstName: string; lastName: string; fullName: string };
  workspace: { id: string; organizationId: string; name: string; slug: string; permissions: string[] };
}

export interface Contact {
  id: string;
  email: string;
  firstName?: string;
  lastName?: string;
  displayName: string;
  status: string;
  engagementScore: number;
  lifecycleStage?: string;
  source?: string;
  createdAt: string;
}

export interface Campaign {
  id: string;
  brandId: string;
  name: string;
  subject?: string;
  status: string;
  totalSent: number;
  totalDelivered: number;
  totalOpened: number;
  totalClicked: number;
  totalRevenue: number;
  createdAt: string;
}

export interface PagedResult<T> {
  items: T[];
  nextCursor?: string;
  hasMore: boolean;
}

export interface ExecutiveDashboard {
  totalContacts: number;
  contactGrowth: number;
  totalSent: number;
  totalDelivered: number;
  totalOpened: number;
  totalClicked: number;
  totalBounced: number;
  totalRevenue: number;
  deliveryRate: number;
  openRate: number;
  clickRate: number;
  bounceRate: number;
  dailyMetrics: Array<{
    date: string;
    sent: number;
    delivered: number;
    opened: number;
    clicked: number;
    revenue: number;
  }>;
}

class ApiClient {
  private token: string | null = null;

  setToken(token: string | null) {
    this.token = token;
    if (typeof window !== 'undefined') {
      if (token) localStorage.setItem('pulse_token', token);
      else localStorage.removeItem('pulse_token');
    }
  }

  getToken(): string | null {
    if (this.token) return this.token;
    if (typeof window !== 'undefined') {
      this.token = localStorage.getItem('pulse_token');
    }
    return this.token;
  }

  private async request<T>(path: string, options: RequestInit = {}): Promise<T> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(options.headers as Record<string, string>),
    };
    const token = this.getToken();
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const res = await fetch(`${API_URL}${path}`, { ...options, headers });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: res.statusText }));
      throw new Error(err.message || `HTTP ${res.status}`);
    }
    if (res.status === 204) return undefined as T;
    return res.json();
  }

  login(email: string, password: string) {
    return this.request<AuthResponse>('/api/v1/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
  }

  register(data: { email: string; password: string; firstName: string; lastName: string; organizationName: string; workspaceName: string }) {
    return this.request<AuthResponse>('/api/v1/auth/register', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  getContacts(params?: { search?: string; after?: string }) {
    const qs = new URLSearchParams();
    if (params?.search) qs.set('search', params.search);
    if (params?.after) qs.set('after', params.after);
    return this.request<PagedResult<Contact>>(`/api/v1/contacts?${qs}`);
  }

  createContact(data: { email: string; firstName?: string; lastName?: string }) {
    return this.request<Contact>('/api/v1/contacts', { method: 'POST', body: JSON.stringify(data) });
  }

  getCampaigns(params?: { status?: string; search?: string }) {
    const qs = new URLSearchParams();
    if (params?.status) qs.set('status', params.status);
    if (params?.search) qs.set('search', params.search);
    return this.request<PagedResult<Campaign>>(`/api/v1/campaigns?${qs}`);
  }

  getExecutiveDashboard() {
    return this.request<ExecutiveDashboard>('/api/v1/reports/executive');
  }
}

export const api = new ApiClient();
