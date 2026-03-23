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

// ─── Shops API (super admin) ─────────────────────────────────────────────────
export interface ShopCreatePayload {
  name: string;
  address?: string;
  phone?: string;
  email?: string;
  owner_name: string;
  owner_email: string;
  owner_password: string;
}

export interface ShopUpdatePayload {
  name?: string;
  address?: string;
  phone?: string;
  email?: string;
}

export const shopsApi = {
  getAll: () => api.get('/shops').then(r => r.data),
  create: (data: ShopCreatePayload) => api.post('/shops', data).then(r => r.data),
  update: (id: number, data: ShopUpdatePayload) => api.put(`/shops/${id}`, data).then(r => r.data),
  delete: (id: number) => api.delete(`/shops/${id}`).then(r => r.data),
};

// ─── My Shop API (owner) ─────────────────────────────────────────────────────
export interface BranchPayload {
  name: string;
  address?: string;
  phone?: string;
}

export interface StaffPayload {
  name: string;
  email: string;
  password?: string;
  branch_id?: number | null;
}

export const myShopApi = {
  get:           ()                           => api.get('/my-shop').then(r => r.data),
  update:        (data: ShopUpdatePayload)    => api.put('/my-shop', data).then(r => r.data),
  getBranches:   ()                           => api.get('/my-shop/branches').then(r => r.data),
  createBranch:  (data: BranchPayload)        => api.post('/my-shop/branches', data).then(r => r.data),
  updateBranch:  (id: number, data: Partial<BranchPayload>) => api.put(`/my-shop/branches/${id}`, data).then(r => r.data),
  deleteBranch:  (id: number)                 => api.delete(`/my-shop/branches/${id}`).then(r => r.data),
  getStaff:      ()                           => api.get('/my-shop/staff').then(r => r.data),
  createStaff:   (data: StaffPayload)         => api.post('/my-shop/staff', data).then(r => r.data),
  updateStaff:   (id: number, data: Partial<StaffPayload>) => api.put(`/my-shop/staff/${id}`, data).then(r => r.data),
  deleteStaff:   (id: number)                 => api.delete(`/my-shop/staff/${id}`).then(r => r.data),
};
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
