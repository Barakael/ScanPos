import AppLayout from '@/components/layout/AppLayout';
import { useAuth } from '@/contexts/AuthContext';
import { useStore } from '@/contexts/StoreContext';
import { formatCurrency } from '@/data/mockData';
import {
  ShoppingCart, Package, TrendingUp, AlertTriangle,
  DollarSign, ArrowUpRight, ArrowDownRight, Users, Store,
  Activity, CreditCard, CheckCircle2, Clock, Trophy
} from 'lucide-react';
import { motion } from 'framer-motion';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { useQuery } from '@tanstack/react-query';
import api from '@/services/api';
import { TopProduct } from '@/services/api';

// ── Admin dashboard data ──────────────────────────────────────────────────────
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
  recent_activity: { id: number; action: string; description: string; ip_address: string | null; created_at: string; user: { name: string; role: string } | null }[];
}

function AdminDashboard() {
  const { user } = useAuth();
  const { data, isLoading } = useQuery<AdminDashboardData>({
    queryKey: ['admin-dashboard'],
    queryFn: () => api.get('/dashboard').then(r => r.data),
    refetchInterval: 60_000,
  });

  const stats = [
    { title: 'Total Shops',           value: data?.total_shops.toString() ?? '—',         icon: Store,          color: 'text-primary',   bg: 'bg-primary/10' },
    { title: 'Total Users',           value: data?.total_users.toString() ?? '—',          icon: Users,          color: 'text-info',      bg: 'bg-info/10' },
    { title: 'Monthly Recurring Rev', value: `$${(data?.mrr ?? 0).toFixed(2)}`,            icon: CreditCard,     color: 'text-warning',   bg: 'bg-warning/15' },
    { title: 'Active Subscriptions',  value: data?.active_subscriptions.toString() ?? '—', icon: CheckCircle2,   color: 'text-green-600', bg: 'bg-green-100' },
    { title: 'Overdue Payments',      value: data?.overdue_payments.toString() ?? '0',     icon: Clock,          color: data?.overdue_payments ? 'text-red-600' : 'text-muted-foreground', bg: data?.overdue_payments ? 'bg-red-100' : 'bg-muted/40' },
  ];

  const actionLabel: Record<string, string> = {
    login:        'Login',
    sale_created: 'Sale',
    user_created: 'User Created',
    user_deleted: 'User Deleted',
    shop_created: 'Shop Created',
    shop_deleted: 'Shop Deleted',
  };

  const actionColor: Record<string, string> = {
    login:        'bg-info/10 text-info',
    sale_created: 'bg-warning/10 text-warning',
    user_created: 'bg-primary/10 text-primary',
    user_deleted: 'bg-destructive/10 text-destructive',
    shop_created: 'bg-primary/10 text-primary',
    shop_deleted: 'bg-destructive/10 text-destructive',
  };

  const recentActivity = (data?.recent_activity ?? []).filter(log => log.action !== 'sale_created');

  if (isLoading) {
    return (
      <AppLayout>
        <div className="flex items-center justify-center h-64 text-muted-foreground">Loading dashboard…</div>
      </AppLayout>
    );
  }

  return (
    <AppLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-foreground">
            Good {new Date().getHours() < 12 ? 'morning' : 'afternoon'}, {user?.name?.split(' ')[0]}
          </h1>
          <p className="text-muted-foreground text-sm">Platform management overview</p>
        </div>

        {/* Stat cards */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {stats.map((stat, i) => (
            <motion.div
              key={stat.title}
              initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.07 }}
              className="glass-card rounded-xl p-5 border border-border/40 hover:shadow-xl transition-shadow"
            >
              <div className={`p-2 rounded-lg ${stat.bg} w-fit mb-3`}>
                <stat.icon className={`w-5 h-5 ${stat.color}`} />
              </div>
              <p className="text-2xl font-bold text-foreground">{stat.value}</p>
              <p className="text-xs text-muted-foreground mt-1">{stat.title}</p>
            </motion.div>
          ))}
        </div>

        {/* Recent activity */}
        <div className="glass-card rounded-xl p-6">
          <h3 className="text-sm font-semibold text-foreground mb-4 flex items-center gap-2">
            <Activity className="w-4 h-4 text-info" /> Recent Activity
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
            {recentActivity.length === 0 ? (
              <p className="text-sm text-muted-foreground">No activity yet.</p>
            ) : recentActivity.map(log => (
              <div key={log.id} className="flex items-start gap-3 p-3 rounded-lg bg-muted/50">
                <span className={`text-[10px] font-semibold px-1.5 py-0.5 rounded-full whitespace-nowrap ${actionColor[log.action] ?? 'bg-muted text-muted-foreground'}`}>
                  {actionLabel[log.action] ?? log.action}
                </span>
                <div className="flex-1 min-w-0">
                  <p className="text-xs text-foreground truncate">{log.description}</p>
                  <p className="text-[10px] text-muted-foreground mt-0.5">
                    {new Date(log.created_at).toLocaleString()}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </AppLayout>
  );
}


const Dashboard = () => {
  const { user } = useAuth();

  if (user?.role === 'super_admin') {
    return <AdminDashboard />;
  }

  const { products, sales } = useStore();

  // Fetch top products from API
  const { data: dashboardData } = useQuery<{ top_products?: TopProduct[] }>({
    queryKey: ['owner-dashboard'],
    queryFn: () => api.get('/dashboard').then(r => r.data),
    refetchInterval: 120_000,
  });
  const topProducts = dashboardData?.top_products ?? [];

  const todaySales = sales.filter(s =>
    new Date(s.timestamp).toDateString() === new Date().toDateString()
  );
  const todayTotal = todaySales.reduce((sum, s) => sum + s.total, 0);
  const lowStockProducts = products.filter(p => p.stock <= p.lowStockThreshold);
  const totalProducts = products.length;
  const totalStock = products.reduce((sum, p) => sum + p.stock, 0);

  // Build last-7-days chart data from real sales
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

  const COLORS = [
    'hsl(43, 100%, 50%)',   // gold
    'hsl(222, 100%, 40%)',  // navy
    'hsl(153, 60%, 40%)',   // green
    'hsl(210, 80%, 55%)',   // blue
    'hsl(280, 60%, 55%)',   // purple
    'hsl(0, 72%, 55%)',     // red
  ];

  const stats = [
    {
      title: "Today's Sales",
      value: formatCurrency(todayTotal),
      change: '+12.5%',
      positive: true,
      icon: DollarSign,
      color: 'text-warning',
      bg: 'bg-warning/15',
    },
    {
      title: 'Transactions',
      value: todaySales.length.toString(),
      change: '+8.2%',
      positive: true,
      icon: ShoppingCart,
      color: 'text-info',
      bg: 'bg-info/10',
    },
    {
      title: 'Products',
      value: totalProducts.toString(),
      subtitle: `${totalStock} units`,
      icon: Package,
      color: 'text-primary',
      bg: 'bg-primary/10',
    },
    {
      title: 'Low Stock',
      value: lowStockProducts.length.toString(),
      change: 'Needs attention',
      positive: false,
      icon: AlertTriangle,
      color: 'text-destructive',
      bg: 'bg-destructive/10',
    },
  ];

  return (
    <AppLayout>
      <div className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-2xl font-bold text-foreground">
            Good {new Date().getHours() < 12 ? 'morning' : 'afternoon'}, {user?.name?.split(' ')[0]}
          </h1>
          <p className="text-muted-foreground text-sm">Here's your store overview for today</p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {stats.map((stat, i) => (
            <motion.div
              key={stat.title}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.1 }}
              className="glass-card rounded-xl p-5 stat-glow border border-border/40 hover:shadow-xl transition-shadow duration-200"
            >
              <div className="flex items-start justify-between mb-3">
                <div className={`p-2 rounded-lg ${stat.bg}`}>
                  <stat.icon className={`w-5 h-5 ${stat.color}`} />
                </div>
                {stat.change && (
                  <span className={`flex items-center gap-1 text-xs font-medium ${
                    stat.positive ? 'text-warning' : 'text-destructive'
                  }`}>
                    {stat.positive ? <ArrowUpRight className="w-3 h-3" /> : <ArrowDownRight className="w-3 h-3" />}
                    {stat.change}
                  </span>
                )}
              </div>
              <p className="text-2xl font-bold text-foreground">{stat.value}</p>
              <p className="text-xs text-muted-foreground mt-1">{stat.subtitle || stat.title}</p>
            </motion.div>
          ))}
        </div>

        {/* Charts Row */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Weekly Sales Chart */}
          <div className="lg:col-span-2 glass-card rounded-xl p-6">
            <h3 className="text-sm font-semibold text-foreground mb-4">Weekly Sales Overview</h3>
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={weeklySales}>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(220 22% 83%)" />
                <XAxis dataKey="day" tick={{ fontSize: 12 }} stroke="hsl(222 25% 55%)" />
                <YAxis tick={{ fontSize: 12 }} stroke="hsl(222 25% 55%)" tickFormatter={v => `${(v / 1000).toFixed(0)}k`} />
                <Tooltip
                  formatter={(value: number) => formatCurrency(value)}
                  contentStyle={{ background: 'hsl(220 25% 98%)', border: '1px solid hsl(220 22% 83%)', borderRadius: '8px', fontSize: '12px' }}
                />
                <Bar dataKey="sales" fill="hsl(43, 100%, 50%)" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>

          {/* Category Distribution */}
          <div className="glass-card rounded-xl p-6">
            <h3 className="text-sm font-semibold text-foreground mb-4">Stock by Category</h3>
            <ResponsiveContainer width="100%" height={200}>
              <PieChart>
                <Pie
                  data={categoryData}
                  cx="50%"
                  cy="50%"
                  innerRadius={50}
                  outerRadius={80}
                  paddingAngle={3}
                  dataKey="value"
                >
                  {categoryData.map((_, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip contentStyle={{ background: 'hsl(220 25% 98%)', border: '1px solid hsl(220 22% 83%)', borderRadius: '8px', fontSize: '12px' }} />
              </PieChart>
            </ResponsiveContainer>
            <div className="grid grid-cols-2 gap-2 mt-2">
              {categoryData.slice(0, 6).map((cat, i) => (
                <div key={cat.name} className="flex items-center gap-2 text-xs">
                  <div className="w-2 h-2 rounded-full" style={{ background: COLORS[i % COLORS.length] }} />
                  <span className="text-muted-foreground truncate">{cat.name}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Low Stock Alert & Recent Sales */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Low Stock */}
          <div className="glass-card rounded-xl p-6">
            <h3 className="text-sm font-semibold text-foreground mb-4 flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 text-warning" />
              Low Stock Alerts
            </h3>
            <div className="space-y-3">
              {lowStockProducts.length === 0 ? (
                <p className="text-sm text-muted-foreground">All products are well stocked!</p>
              ) : (
                lowStockProducts.map(p => (
                  <div key={p.id} className="flex items-center justify-between p-3 rounded-lg bg-muted/50">
                    <div>
                      <p className="text-sm font-medium text-foreground">{p.name}</p>
                      <p className="text-xs text-muted-foreground font-mono">{p.barcode}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-bold text-destructive">{p.stock} left</p>
                      <p className="text-xs text-muted-foreground">Min: {p.lowStockThreshold}</p>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>

          {/* Recent Sales */}
          <div className="glass-card rounded-xl p-6">
            <h3 className="text-sm font-semibold text-foreground mb-4 flex items-center gap-2">
              <TrendingUp className="w-4 h-4 text-primary" />
              Recent Transactions
            </h3>
            <div className="space-y-3">
              {sales.slice(0, 5).map(sale => (
                <div key={sale.id} className="flex items-center justify-between p-3 rounded-lg bg-muted/50">
                  <div>
                    <p className="text-sm font-medium text-foreground">{sale.items.length} items</p>
                    <p className="text-xs text-muted-foreground">
                      {new Date(sale.timestamp).toLocaleTimeString()} · {sale.cashierName}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-bold text-foreground">{formatCurrency(sale.total)}</p>
                    <span className="text-xs px-2 py-0.5 rounded-full bg-accent text-accent-foreground capitalize">
                      {sale.paymentMethod}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Top Products */}
        <div className="glass-card rounded-xl p-6">
          <h3 className="text-sm font-semibold text-foreground mb-4 flex items-center gap-2">
            <Trophy className="w-4 h-4 text-warning" /> Top Selling Products (All Time)
          </h3>
          {topProducts.length === 0 ? (
            <p className="text-sm text-muted-foreground">Start making sales to see your top products.</p>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3">
              {topProducts.map((p, i) => (
                <div key={p.product_id} className="bg-muted/50 rounded-lg p-3">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="text-xs font-bold text-muted-foreground">#{i + 1}</span>
                    <span className="text-xs px-1.5 py-0.5 rounded bg-accent text-accent-foreground">{p.category}</span>
                  </div>
                  <p className="text-sm font-semibold truncate">{p.name}</p>
                  <p className="text-lg font-bold mt-1">{p.total_sold} <span className="text-xs font-normal text-muted-foreground">sold</span></p>
                  <p className="text-xs text-muted-foreground">{formatCurrency(p.total_revenue)}</p>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </AppLayout>
  );
};

export default Dashboard;
