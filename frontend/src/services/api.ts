import axios from 'axios';

const api = axios.create({
  baseURL: '/api',
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
});

// Attach Bearer token on every request
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('pos_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Global error normaliser
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const message =
      error.response?.data?.message ||
      error.response?.data?.errors?.[Object.keys(error.response?.data?.errors ?? {})[0]]?.[0] ||
      error.message ||
      'An unexpected error occurred.';
    return Promise.reject(new Error(message));
  }
);

export default api;

// ─── Users API (super_admin) ──────────────────────────────────────────────────
export interface UserPayload {
  name: string;
  email: string;
  role: 'super_admin' | 'owner' | 'cashier';
  password?: string;
}

export const usersApi = {
  getAll: () => api.get('/users').then(r => r.data),
  update: (id: string | number, data: Partial<UserPayload>) =>
    api.put(`/users/${id}`, data).then(r => r.data),
  delete: (id: string | number) => api.delete(`/users/${id}`).then(r => r.data),
};

// ─── Shops API (super_admin) ──────────────────────────────────────────────────
export interface ShopPayload {
  name: string;
  address?: string;
  phone?: string;
  email?: string;
  tax_rate?: number | string;
  currency?: string;
  owner_name: string;
  owner_email: string;
  owner_password: string;
}

export interface ShopUpdatePayload {
  name?: string;
  address?: string;
  phone?: string;
  email?: string;
  tax_rate?: number | string;
  currency?: string;
}

export const shopsApi = {
  getAll: () => api.get('/shops').then(r => r.data),
  getOne: (id: number) => api.get(`/shops/${id}`).then(r => r.data),
  create: (data: ShopPayload) => api.post('/shops', data).then(r => r.data),
  update: (id: number, data: ShopUpdatePayload) => api.put(`/shops/${id}`, data).then(r => r.data),
  delete: (id: number) => api.delete(`/shops/${id}`).then(r => r.data),
};

// ─── Branches API (owner) ─────────────────────────────────────────────────────
export interface BranchPayload {
  name: string;
  address?: string;
  phone?: string;
}

export const branchesApi = {
  getAll: () => api.get('/branches').then(r => r.data),
  create: (data: BranchPayload) => api.post('/branches', data).then(r => r.data),
  update: (id: number, data: Partial<BranchPayload>) => api.put(`/branches/${id}`, data).then(r => r.data),
  delete: (id: number) => api.delete(`/branches/${id}`).then(r => r.data),
};

// ─── Staff API (owner) ────────────────────────────────────────────────────────
export interface StaffPayload {
  name: string;
  email: string;
  password?: string;
  branch_id: number;
}

export const staffApi = {
  getAll: () => api.get('/staff').then(r => r.data),
  create: (data: StaffPayload) => api.post('/staff', data).then(r => r.data),
  update: (id: number, data: Partial<StaffPayload>) => api.put(`/staff/${id}`, data).then(r => r.data),
  delete: (id: number) => api.delete(`/staff/${id}`).then(r => r.data),
};

// ─── Activity Logs API (super_admin) ─────────────────────────────────────────
export interface ActivityLogEntry {
  id: number;
  action: string;
  description: string;
  ip_address: string | null;
  created_at: string;
  user: { id: number; name: string; email: string; role: string } | null;
}

export interface PaginatedResponse<T> {
  data: T[];
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

export const activityLogsApi = {
  getAll: (params?: { action?: string; date?: string; page?: number }) =>
    api.get('/activity-logs', { params }).then(r => r.data as PaginatedResponse<ActivityLogEntry>),
};

// ─── Admin Reports API (super_admin) ─────────────────────────────────────────
export interface ShopReportRow {
  id: number;
  name: string;
  currency: string;
  cashier_count: number;
  revenue: number;
  transactions: number;
}

export interface AdminReportSummary {
  total_shops: number;
  total_users: number;
  total_revenue: number;
  total_transactions: number;
}

export interface AdminReportData {
  summary: AdminReportSummary;
  shop_breakdown: ShopReportRow[];
  daily_revenue: { date: string; total: number; transactions: number }[];
  top_shop: ShopReportRow | null;
}

export const adminReportsApi = {
  get: () => api.get('/admin/reports').then(r => r.data as AdminReportData),
};

export interface OwnerSettingsPayload {
  name?: string;
  address?: string;
  phone?: string;
  email?: string;
  tax_rate?: number | string;
  currency?: string;
}

export const settingsApi = {
  get: () => api.get('/settings').then(r => r.data),
  update: (data: OwnerSettingsPayload) => api.put('/settings', data).then(r => r.data),
};

// ─── Plans API ────────────────────────────────────────────────────────────────
export interface Plan {
  id: number;
  name: string;
  slug: string;
  price: number;
  max_branches: number;
  max_staff: number;
  is_active: boolean;
}

export const plansApi = {
  getAll: () => api.get('/plans').then(r => r.data as Plan[]),
};

// ─── Subscriptions API ────────────────────────────────────────────────────────
export interface SubscriptionRow {
  id: number;
  shop_id: number;
  shop_name: string;
  plan_id: number;
  plan_name: string;
  plan_price: number;
  status: 'active' | 'past_due' | 'cancelled' | 'trialing';
  starts_at: string;
  next_due_at: string;
  days_until_due: number | null;
}

export interface AssignPlanPayload {
  shop_id: number;
  plan_id: number;
  starts_at?: string;
}

export const subscriptionsApi = {
  get: () => api.get('/subscriptions').then(r => r.data as SubscriptionRow | SubscriptionRow[] | null),
  /** owner's single subscription */
  getOwner: () => api.get('/subscriptions').then(r => r.data as SubscriptionRow | null),
  /** super_admin list */
  getAll: () => api.get('/subscriptions').then(r => r.data as SubscriptionRow[]),
  assign: (data: AssignPlanPayload) => api.post('/subscriptions', data).then(r => r.data),
};

// ─── Subscription Payments API ────────────────────────────────────────────────
export interface SubscriptionPaymentRow {
  id: number;
  shop_id: number;
  shop_name: string;
  plan_name: string;
  amount: number;
  status: 'pending' | 'paid' | 'failed' | 'refunded';
  payment_method: string | null;
  reference: string | null;
  due_date: string;
  paid_at: string | null;
  notes: string | null;
}

export interface MarkPaidPayload {
  payment_method?: string;
  reference?: string;
  notes?: string;
}

export const subscriptionPaymentsApi = {
  getAll: () => api.get('/subscription-payments').then(r => r.data as SubscriptionPaymentRow[]),
  markPaid: (id: number, data?: MarkPaidPayload) =>
    api.put(`/subscription-payments/${id}/mark-paid`, data ?? {}).then(r => r.data as SubscriptionPaymentRow),
};

// ─── Top Product type (used in dashboard + reports) ───────────────────────────
export interface TopProduct {
  product_id: number;
  name: string;
  category: string;
  total_sold: number;
  total_revenue: number;
}

// Updated AdminReportSummary (includes MRR + subscription stats)
export interface AdminReportSummaryExtended extends AdminReportSummary {
  mrr: number;
  active_subscriptions: number;
  overdue_payments: number;
}

export interface AdminReportDataExtended {
  summary: AdminReportSummaryExtended;
  shop_breakdown: ShopReportRow[];
  daily_revenue: { date: string; total: number; transactions: number }[];
  top_shop: ShopReportRow | null;
  top_products: TopProduct[];
  payment_stats: Record<string, { status: string; count: number; total: number }>;
}

