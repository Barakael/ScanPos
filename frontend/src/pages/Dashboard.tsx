import AppLayout from '@/components/layout/AppLayout';
import { useAuth } from '@/contexts/AuthContext';
import { useStore } from '@/contexts/StoreContext';
import { formatCurrency } from '@/data/mockData';
import {
  ShoppingCart, Package, TrendingUp, AlertTriangle,
  DollarSign, ArrowUpRight, ArrowDownRight, Users
} from 'lucide-react';
import { motion } from 'framer-motion';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

const Dashboard = () => {
  const { user } = useAuth();
  const { products, sales } = useStore();

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
      </div>
    </AppLayout>
  );
};

export default Dashboard;
