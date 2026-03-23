export type UserRole = 'super_admin' | 'owner' | 'cashier';

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  avatar?: string;
  shop_id?: string | null;
  branch_id?: string | null;
}

export interface Shop {
  id: number;
  name: string;
  owner_id: number | null;
  address: string | null;
  phone: string | null;
  email: string | null;
  owner?: { id: number; name: string; email: string };
  branches_count?: number;
  staff_count?: number;
  created_at: string;
}

export interface Branch {
  id: number;
  shop_id: number;
  name: string;
  address: string | null;
  phone: string | null;
  staff_count?: number;
  created_at: string;
}

export interface Product {
  id: string;
  name: string;
  barcode: string;
  price: number;
  stock: number;
  category: string;
  image?: string;
  lowStockThreshold: number;
}

export interface CartItem {
  product: Product;
  quantity: number;
}

export interface Sale {
  id: string;
  items: CartItem[];
  total: number;
  tax: number;
  cashierId: string;
  cashierName: string;
  timestamp: Date;
  paymentMethod: 'cash' | 'card' | 'mobile';
}

export interface DailySales {
  date: string;
  total: number;
  transactions: number;
}

export interface CategorySales {
  category: string;
  total: number;
  count: number;
}
