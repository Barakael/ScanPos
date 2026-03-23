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

// ─── Settings API (owner — their own shop) ────────────────────────────────────
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
