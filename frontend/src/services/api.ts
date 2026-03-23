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

// ─── Users API ────────────────────────────────────────────────────────────────
export interface UserPayload {
  name: string;
  email: string;
  role: 'super_admin' | 'owner' | 'cashier';
  password?: string;
}

export const usersApi = {
  getAll: () => api.get('/users').then(r => r.data),
  create: (data: UserPayload) => api.post('/users', data).then(r => r.data),
  update: (id: string | number, data: Partial<UserPayload>) =>
    api.put(`/users/${id}`, data).then(r => r.data),
  delete: (id: string | number) => api.delete(`/users/${id}`).then(r => r.data),
};

// ─── Settings API ─────────────────────────────────────────────────────────────
export interface SettingsPayload {
  store_name?: string;
  store_address?: string;
  store_phone?: string;
  store_email?: string;
  tax_rate?: number | string;
  currency?: string;
}

export const settingsApi = {
  getAll: () => api.get('/settings').then(r => r.data),
  update: (data: SettingsPayload) => api.put('/settings', data).then(r => r.data),
};
