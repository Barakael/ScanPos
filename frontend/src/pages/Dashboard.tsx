import AppLayout from '@/components/layout/AppLayout';
import { useAuth } from '@/contexts/AuthContext';
import { useStore } from '@/contexts/StoreContext';
import { formatCurrency } from '@/data/mockData';
import {
  ShoppingCart, Package, TrendingUp, AlertTriangle,
  DollarSign, ArrowUpRight, ArrowDownRight, Users, Store,
  Activity, CreditCard, CheckCircle2, Clock, Trophy, type LucideIcon
} from 'lucide-react';
import { motion } from 'framer-motion';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { useQuery } from '@tanstack/react-query';
import api from '@/services/api';
import { TopProduct } from '@/services/api';
import { cn } from '@/lib/utils';

const BRAND = {
  primary: '#174050',
  accent: '#AB6F44',
} as const;

const CHART_COLORS = [BRAND.primary, BRAND.accent, '#2A6B7A', '#C4895E', '#4A8A9A', '#8B5A3C'];

type StatCardProps = {
  title: string;
  value: string;
  subtitle?: string;
  change?: string;
  positive?: boolean;
  icon: LucideIcon;
  tone?: 'primary' | 'accent' | 'danger' | 'muted';
  index?: number;
};

function StatCard({
  title,
  value,
  subtitle,
  change,
  positive,
  icon: Icon,
  tone = 'primary',
  index = 0,
}: StatCardProps) {
  const tones = {
    primary: {
      icon: 'text-[#174050] dark:text-[#8FCBD6]',
      bg: 'bg-[#174050]/10 dark:bg-[#8FCBD6]/15',
    },
    accent: {
      icon: 'text-[#AB6F44]',
      bg: 'bg-[#AB6F44]/15',
    },
    danger: {
      icon: 'text-red-600 dark:text-red-400',
      bg: 'bg-red-50 dark:bg-red-950/40',
    },
    muted: {
      icon: 'text-muted-foreground',
      bg: 'bg-muted',
    },
  }[tone];

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.05 }}
      className="rounded-xl border border-border bg-card p-3 sm:p-4 shadow-sm"
    >
      <div className="mb-2 flex items-start justify-between gap-2">
        <div className={cn('flex h-8 w-8 items-center justify-center rounded-lg', tones.bg)}>
          <Icon className={cn('h-4 w-4', tones.icon)} />
        </div>
        {change && (
          <span
            className={cn(
              'flex items-center gap-0.5 text-[10px] sm:text-xs font-medium',
              positive ? 'text-[#AB6F44]' : 'text-red-600 dark:text-red-400'
            )}
          >
            {positive ? <ArrowUpRight className="h-3 w-3" /> : <ArrowDownRight className="h-3 w-3" />}
            <span className="truncate max-w-[4.5rem] sm:max-w-none">{change}</span>
          </span>
        )}
      </div>
      <p className="text-lg sm:text-2xl font-bold tabular-nums leading-tight text-foreground">
        {value}
      </p>
      <p className="mt-0.5 text-[11px] sm:text-xs text-muted-foreground leading-snug">
        {subtitle || title}
      </p>
    </motion.div>
  );
}

function SectionCard({
  title,
  icon: Icon,
  children,
  className,
}: {
  title: string;
  icon?: LucideIcon;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div className={cn('rounded-xl border border-border bg-card p-4 sm:p-5 shadow-sm', className)}>
      <h3 className="mb-3 sm:mb-4 flex items-center gap-2 text-sm sm:text-base font-semibold text-foreground">
        {Icon && <Icon className="h-4 w-4 text-[#AB6F44]" />}
        {title}
      </h3>
      {children}
    </div>
  );
}

// ── Admin dashboard ───────────────────────────────────────────────────────────
interface AdminDashboardData {
  role: string;
  total_shops: number;
  total_users: number;
  today_total: number;
  today_transactions: number;
  mrr: number;
  active_subscriptions: number;
  overdue_payments: number;
  top_products: TopProduct[];
  weekly_sales: { date: string; total: number; transactions: number }[];
  recent_activity: {
    id: number;
    action: string;
    description: string;
    ip_address: string | null;
    created_at: string;
    user: { name: string; role: string } | null;
  }[];
}

function AdminDashboard() {
  const { user } = useAuth();
  const { data, isLoading } = useQuery<AdminDashboardData>({
    queryKey: ['admin-dashboard'],
    queryFn: () => api.get('/dashboard').then(r => r.data),
    refetchInterval: 60_000,
  });

  const stats: StatCardProps[] = [
    { title: 'Total Shops', value: data?.total_shops.toString() ?? '—', icon: Store, tone: 'primary' },
    { title: 'Total Users', value: data?.total_users.toString() ?? '—', icon: Users, tone: 'accent' },
    { title: 'Monthly Recurring Rev', value: `${(data?.mrr ?? 0).toFixed(2)}`, icon: CreditCard, tone: 'accent' },
    { title: 'Active Subscriptions', value: data?.active_subscriptions.toString() ?? '—', icon: CheckCircle2, tone: 'primary' },
    {
      title: 'Overdue Payments',
      value: data?.overdue_payments.toString() ?? '0',
      icon: Clock,
      tone: data?.overdue_payments ? 'danger' : 'muted',
    },
  ];

  const actionLabel: Record<string, string> = {
    login: 'Login',
    sale_created: 'Sale',
    user_created: 'User Created',
    user_deleted: 'User Deleted',
    shop_created: 'Shop Created',
    shop_deleted: 'Shop Deleted',
  };

  const actionColor: Record<string, string> = {
    login: 'bg-[#174050]/10 text-[#174050]',
    sale_created: 'bg-[#AB6F44]/15 text-[#AB6F44]',
    user_created: 'bg-[#174050]/10 text-[#174050]',
    user_deleted: 'bg-red-50 text-red-600',
    shop_created: 'bg-[#174050]/10 text-[#174050]',
    shop_deleted: 'bg-red-50 text-red-600',
  };

  const recentActivity = (data?.recent_activity ?? []).filter(log => log.action !== 'sale_created');

  if (isLoading) {
    return (
      <AppLayout>
        <div className="flex h-64 items-center justify-center text-sm text-muted-foreground">
          Loading dashboard…
        </div>
      </AppLayout>
    );
  }

  return (
    <AppLayout>
      <div className="space-y-4 sm:space-y-6">
        <div>
          <h1 className="text-xl sm:text-2xl font-semibold tracking-tight text-foreground">
            Good {new Date().getHours() < 12 ? 'morning' : 'afternoon'}, {user?.name?.split(' ')[0]}
          </h1>
          <p className="text-xs sm:text-sm text-muted-foreground">Platform management overview</p>
        </div>

        {/* 2×2 on small screens; wraps cleanly with 5 cards */}
        <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
          {stats.map((stat, i) => (
            <StatCard key={stat.title} {...stat} index={i} />
          ))}
        </div>

        <SectionCard title="Recent Activity" icon={Activity}>
          <div className="grid grid-cols-1 gap-2 md:grid-cols-2">
            {recentActivity.length === 0 ? (
              <p className="text-xs sm:text-sm text-muted-foreground">No activity yet.</p>
            ) : (
              recentActivity.map(log => (
                <div key={log.id} className="flex items-start gap-2 sm:gap-3 rounded-lg bg-muted/40 p-2.5 sm:p-3">
                  <span
                    className={cn(
                      'whitespace-nowrap rounded-full px-1.5 py-0.5 text-[10px] font-semibold',
                      actionColor[log.action] ?? 'bg-muted text-muted-foreground'
                    )}
                  >
                    {actionLabel[log.action] ?? log.action}
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-xs sm:text-sm text-foreground">{log.description}</p>
                    <p className="mt-0.5 text-[10px] sm:text-xs text-muted-foreground">
                      {new Date(log.created_at).toLocaleString()}
                    </p>
                  </div>
                </div>
              ))
            )}
          </div>
        </SectionCard>
      </div>
    </AppLayout>
  );
}

// ── Owner / Cashier dashboard ─────────────────────────────────────────────────
const Dashboard = () => {
  const { user } = useAuth();

  if (user?.role === 'super_admin') {
    return <AdminDashboard />;
  }

  const { products, sales } = useStore();

  const { data: dashboardData } = useQuery<{ top_products?: TopProduct[] }>({
    queryKey: ['owner-dashboard'],
    queryFn: () => api.get('/dashboard').then(r => r.data),
    refetchInterval: 120_000,
  });
  const topProducts = dashboardData?.top_products ?? [];

  const todaySales = sales.filter(
    s => new Date(s.timestamp).toDateString() === new Date().toDateString()
  );
  const todayTotal = todaySales.reduce((sum, s) => sum + s.total, 0);
  const lowStockProducts = products.filter(p => p.stock <= p.lowStockThreshold);
  const totalProducts = products.length;
  const totalStock = products.reduce((sum, p) => sum + p.stock, 0);

  const weeklySales = Array.from({ length: 7 }, (_, i) => {
    const d = new Date();
    d.setDate(d.getDate() - (6 - i));
    const label = d.toLocaleDateString('en-US', { weekday: 'short' });
    const dayTotal = sales
      .filter(s => new Date(s.timestamp).toDateString() === d.toDateString())
      .reduce((sum, s) => sum + s.total, 0);
    return { day: label, sales: dayTotal };
  });

  const categoryData = products.reduce((acc, p) => {
    const existing = acc.find(c => c.name === p.category);
    if (existing) {
      existing.value += p.stock;
    } else {
      acc.push({ name: p.category, value: p.stock });
    }
    return acc;
  }, [] as { name: string; value: number }[]);

  const stats: StatCardProps[] = [
    {
      title: "Today's Sales",
      value: formatCurrency(todayTotal),
      change: '+12.5%',
      positive: true,
      icon: DollarSign,
      tone: 'accent',
    },
    {
      title: 'Transactions',
      value: todaySales.length.toString(),
      change: '+8.2%',
      positive: true,
      icon: ShoppingCart,
      tone: 'primary',
    },
    {
      title: 'Products',
      value: totalProducts.toString(),
      subtitle: `${totalStock} units`,
      icon: Package,
      tone: 'primary',
    },
    {
      title: 'Low Stock',
      value: lowStockProducts.length.toString(),
      change: lowStockProducts.length ? 'Needs attention' : undefined,
      positive: false,
      icon: AlertTriangle,
      tone: lowStockProducts.length ? 'danger' : 'muted',
    },
  ];

  return (
    <AppLayout>
      <div className="space-y-4 sm:space-y-6">
        <div>
          <h1 className="text-xl sm:text-2xl font-semibold tracking-tight text-foreground">
            Good {new Date().getHours() < 12 ? 'morning' : 'afternoon'}, {user?.name?.split(' ')[0]}
          </h1>
          <p className="text-xs sm:text-sm text-muted-foreground">Here&apos;s your store overview for today</p>
        </div>

        {/* 2×2 on small screens for owner & cashier */}
        <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
          {stats.map((stat, i) => (
            <StatCard key={stat.title} {...stat} index={i} />
          ))}
        </div>

        <div className="grid grid-cols-1 gap-4 lg:grid-cols-3 lg:gap-6">
          <SectionCard title="Weekly Sales Overview" className="lg:col-span-2">
            <ResponsiveContainer width="100%" height={240}>
              <BarChart data={weeklySales}>
                <CartesianGrid strokeDasharray="3 3" stroke="#17405022" />
                <XAxis dataKey="day" tick={{ fontSize: 11 }} stroke="#17405099" />
                <YAxis
                  tick={{ fontSize: 11 }}
                  stroke="#17405099"
                  tickFormatter={v => `${(v / 1000).toFixed(0)}k`}
                />
                <Tooltip
                  formatter={(value: number) => formatCurrency(value)}
                  contentStyle={{
                    background: 'hsl(var(--card))',
                    border: '1px solid hsl(var(--border))',
                    borderRadius: '8px',
                    fontSize: '12px',
                    color: 'hsl(var(--foreground))',
                  }}
                />
                <Bar dataKey="sales" fill={BRAND.accent} radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </SectionCard>

          <SectionCard title="Stock by Category">
            <ResponsiveContainer width="100%" height={180}>
              <PieChart>
                <Pie
                  data={categoryData}
                  cx="50%"
                  cy="50%"
                  innerRadius={45}
                  outerRadius={70}
                  paddingAngle={3}
                  dataKey="value"
                >
                  {categoryData.map((_, index) => (
                    <Cell key={`cell-${index}`} fill={CHART_COLORS[index % CHART_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    background: 'hsl(var(--card))',
                    border: '1px solid hsl(var(--border))',
                    borderRadius: '8px',
                    fontSize: '12px',
                    color: 'hsl(var(--foreground))',
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
            <div className="mt-2 grid grid-cols-2 gap-2">
              {categoryData.slice(0, 6).map((cat, i) => (
                <div key={cat.name} className="flex items-center gap-2 text-[11px] sm:text-xs">
                  <div
                    className="h-2 w-2 shrink-0 rounded-full"
                    style={{ background: CHART_COLORS[i % CHART_COLORS.length] }}
                  />
                  <span className="truncate text-muted-foreground">{cat.name}</span>
                </div>
              ))}
            </div>
          </SectionCard>
        </div>

        <div className="grid grid-cols-1 gap-4 md:grid-cols-2 md:gap-6">
          <SectionCard title="Low Stock Alerts" icon={AlertTriangle}>
            <div className="space-y-2 sm:space-y-3">
              {lowStockProducts.length === 0 ? (
                <p className="text-xs sm:text-sm text-muted-foreground">All products are well stocked!</p>
              ) : (
                lowStockProducts.map(p => (
                  <div
                    key={p.id}
                    className="flex items-center justify-between rounded-lg bg-muted/40 p-2.5 sm:p-3"
                  >
                    <div className="min-w-0">
                      <p className="truncate text-xs sm:text-sm font-medium text-foreground">{p.name}</p>
                      <p className="font-mono text-[10px] sm:text-xs text-muted-foreground">{p.barcode}</p>
                    </div>
                    <div className="shrink-0 text-right">
                      <p className="text-xs sm:text-sm font-bold text-red-600">{p.stock} left</p>
                      <p className="text-[10px] sm:text-xs text-muted-foreground">Min: {p.lowStockThreshold}</p>
                    </div>
                  </div>
                ))
              )}
            </div>
          </SectionCard>

          <SectionCard title="Recent Transactions" icon={TrendingUp}>
            <div className="space-y-2 sm:space-y-3">
              {sales.slice(0, 5).map(sale => (
                <div
                  key={sale.id}
                  className="flex items-center justify-between rounded-lg bg-muted/40 p-2.5 sm:p-3"
                >
                  <div className="min-w-0">
                    <p className="text-xs sm:text-sm font-medium text-foreground">{sale.items.length} items</p>
                    <p className="text-[10px] sm:text-xs text-muted-foreground">
                      {new Date(sale.timestamp).toLocaleTimeString()} · {sale.cashierName}
                    </p>
                  </div>
                  <div className="shrink-0 text-right">
                    <p className="text-xs sm:text-sm font-bold text-foreground">
                      {formatCurrency(sale.total)}
                    </p>
                    <span className="rounded-full bg-[#AB6F44]/15 px-2 py-0.5 text-[10px] sm:text-xs capitalize text-[#AB6F44]">
                      {sale.paymentMethod}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </SectionCard>
        </div>

        <SectionCard title="Top Selling Products" icon={Trophy}>
          {topProducts.length === 0 ? (
            <p className="text-xs sm:text-sm text-muted-foreground">
              Start making sales to see your top products.
            </p>
          ) : (
            <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
              {topProducts.map((p, i) => (
                <div key={p.product_id} className="rounded-lg bg-muted/40 p-3">
                  <div className="mb-1.5 flex items-center gap-2">
                    <span className="text-[10px] sm:text-xs font-bold text-muted-foreground">#{i + 1}</span>
                    <span className="rounded bg-[#174050]/10 px-1.5 py-0.5 text-[10px] sm:text-xs text-[#174050]">
                      {p.category}
                    </span>
                  </div>
                  <p className="truncate text-xs sm:text-sm font-semibold text-foreground">
                    {p.name}
                  </p>
                  <p className="mt-1 text-base sm:text-lg font-bold tabular-nums text-[#AB6F44]">
                    {p.total_sold}{' '}
                    <span className="text-[10px] sm:text-xs font-normal text-muted-foreground">sold</span>
                  </p>
                  <p className="text-[10px] sm:text-xs text-muted-foreground">
                    {formatCurrency(p.total_revenue)}
                  </p>
                </div>
              ))}
            </div>
          )}
        </SectionCard>
      </div>
    </AppLayout>
  );
};

export default Dashboard;
