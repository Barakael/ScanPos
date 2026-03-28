import { useState } from 'react';
import AppLayout from '@/components/layout/AppLayout';
import { useStore } from '@/contexts/StoreContext';
import { formatCurrency } from '@/data/mockData';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, LineChart, Line, AreaChart, Area
} from 'recharts';
import { TrendingUp, DollarSign, ShoppingCart } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { motion } from 'framer-motion';

type Period = 'daily' | 'weekly' | 'monthly';

const Reports = () => {
  const { sales } = useStore();
  const [period, setPeriod] = useState<Period>('daily');

  const today = new Date();

  const todaySales = sales.filter(s => new Date(s.timestamp).toDateString() === today.toDateString());
  const weekSales = sales.filter(s => {
    const d = new Date(s.timestamp);
    const diff = (today.getTime() - d.getTime()) / (1000 * 60 * 60 * 24);
    return diff <= 7;
  });
  const monthSales = sales.filter(s => {
    const d = new Date(s.timestamp);
    return d.getMonth() === today.getMonth() && d.getFullYear() === today.getFullYear();
  });

  const currentSales = period === 'daily' ? todaySales : period === 'weekly' ? weekSales : monthSales;
  const totalRevenue = currentSales.reduce((sum, s) => sum + s.total, 0);
  const totalTransactions = currentSales.length;
  const avgTransaction = totalTransactions > 0 ? Math.round(totalRevenue / totalTransactions) : 0;

  // Payment method breakdown
  const paymentBreakdown = currentSales.reduce((acc, s) => {
    acc[s.paymentMethod] = (acc[s.paymentMethod] || 0) + s.total;
    return acc;
  }, {} as Record<string, number>);

  const paymentData = Object.entries(paymentBreakdown).map(([method, total]) => ({
    method: method.charAt(0).toUpperCase() + method.slice(1),
    total,
  }));

  // Hourly breakdown for daily view
  const hourlyData = Array.from({ length: 24 }, (_, hour) => {
    const hourSales = todaySales.filter(s => new Date(s.timestamp).getHours() === hour);
    return {
      hour: `${hour}:00`,
      total: hourSales.reduce((sum, s) => sum + s.total, 0),
      count: hourSales.length,
    };
  }).filter(h => h.total > 0 || h.count > 0);

  // Weekly chart from real sales (last 7 days)
  const weeklyChartData = Array.from({ length: 7 }, (_, i) => {
    const d = new Date();
    d.setDate(d.getDate() - (6 - i));
    const label = d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    const dayTotal = sales
      .filter(s => new Date(s.timestamp).toDateString() === d.toDateString())
      .reduce((sum, s) => sum + s.total, 0);
    return { date: label, total: dayTotal };
  });

  const stats = [
    { label: 'Total Revenue', value: formatCurrency(totalRevenue), icon: DollarSign, color: 'text-primary bg-primary/10' },
    { label: 'Transactions', value: totalTransactions.toString(), icon: ShoppingCart, color: 'text-info bg-info/10' },
    { label: 'Avg. Transaction', value: formatCurrency(avgTransaction), icon: TrendingUp, color: 'text-warning bg-warning/10' },
  ];

  return (
    <AppLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Reports</h1>
          <p className="text-sm text-muted-foreground">Track performance across all time periods</p>
        </div>

        {/* Period filter */}
            <div className="flex gap-2">
              {(['daily', 'weekly', 'monthly'] as Period[]).map(p => (
                <Button key={p} variant={period === p ? 'default' : 'outline'} size="sm" onClick={() => setPeriod(p)} className="capitalize">
                  {p}
                </Button>
              ))}
            </div>

        {/* Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {stats.map((stat, i) => (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.1 }}
              className="glass-card rounded-xl p-5"
            >
              <div className={`inline-flex p-2 rounded-lg mb-3 ${stat.color}`}>
                <stat.icon className="w-5 h-5" />
              </div>
              <p className="text-2xl font-bold text-foreground">{stat.value}</p>
              <p className="text-xs text-muted-foreground mt-1">{stat.label}</p>
            </motion.div>
          ))}
        </div>

        {/* Charts */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="glass-card rounded-xl p-6">
            <h3 className="text-sm font-semibold text-foreground mb-4">
              {period === 'daily' ? 'Hourly Sales' : 'Sales Trend'}
            </h3>
            <ResponsiveContainer width="100%" height={280}>
              {period === 'daily' ? (
                <AreaChart data={hourlyData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="hsl(220 22% 83%)" />
                  <XAxis dataKey="hour" tick={{ fontSize: 11 }} stroke="hsl(222 25% 55%)" />
                  <YAxis tick={{ fontSize: 11 }} stroke="hsl(222 25% 55%)" tickFormatter={v => `${(v / 1000).toFixed(0)}k`} />
                  <Tooltip formatter={(value: number) => formatCurrency(value)} contentStyle={{ background: 'hsl(220 25% 98%)', border: '1px solid hsl(220 22% 83%)', borderRadius: '8px', fontSize: '12px' }} />
                  <Area type="monotone" dataKey="total" stroke="hsl(43, 100%, 50%)" fill="hsl(43, 100%, 50%)" fillOpacity={0.15} />
                </AreaChart>
              ) : (
                <BarChart data={weeklyChartData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="hsl(220 22% 83%)" />
                  <XAxis dataKey="date" tick={{ fontSize: 11 }} stroke="hsl(222 25% 55%)" />
                  <YAxis tick={{ fontSize: 11 }} stroke="hsl(222 25% 55%)" tickFormatter={v => `${(v / 1000).toFixed(0)}k`} />
                  <Tooltip formatter={(value: number) => formatCurrency(value)} contentStyle={{ background: 'hsl(220 25% 98%)', border: '1px solid hsl(220 22% 83%)', borderRadius: '8px', fontSize: '12px' }} />
                  <Bar dataKey="total" fill="hsl(43, 100%, 50%)" radius={[4, 4, 0, 0]} />
                </BarChart>
              )}
            </ResponsiveContainer>
          </div>

          <div className="glass-card rounded-xl p-6">
            <h3 className="text-sm font-semibold text-foreground mb-4">Payment Methods</h3>
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={paymentData} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(220 22% 83%)" />
                <XAxis type="number" tick={{ fontSize: 11 }} stroke="hsl(222 25% 55%)" tickFormatter={v => `${(v / 1000).toFixed(0)}k`} />
                <YAxis dataKey="method" type="category" tick={{ fontSize: 12 }} stroke="hsl(222 25% 55%)" width={60} />
                <Tooltip formatter={(value: number) => formatCurrency(value)} contentStyle={{ background: 'hsl(220 25% 98%)', border: '1px solid hsl(220 22% 83%)', borderRadius: '8px', fontSize: '12px' }} />
                <Bar dataKey="total" fill="hsl(222, 100%, 40%)" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Transaction List */}
        <div className="glass-card rounded-xl p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm font-semibold text-foreground">Transaction History</h3>
            <span className="text-xs text-muted-foreground">{currentSales.length} transactions</span>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-border">
                  <th className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">ID</th>
                  <th className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">Date & Time</th>
                  <th className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">Cashier</th>
                  <th className="text-center text-xs font-semibold text-muted-foreground px-4 py-3">Items</th>
                  <th className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">Payment</th>
                  <th className="text-right text-xs font-semibold text-muted-foreground px-4 py-3">Total</th>
                </tr>
              </thead>
              <tbody>
                {currentSales.map(sale => (
                  <tr key={sale.id} className="border-b border-border/50 hover:bg-muted/30 transition-colors">
                    <td className="px-4 py-3 text-xs font-mono text-muted-foreground">{sale.id}</td>
                    <td className="px-4 py-3 text-sm text-foreground">{new Date(sale.timestamp).toLocaleString()}</td>
                    <td className="px-4 py-3 text-sm text-muted-foreground">{sale.cashierName}</td>
                    <td className="px-4 py-3 text-sm text-center text-foreground">{sale.items.length}</td>
                    <td className="px-4 py-3">
                      <span className="text-xs px-2 py-1 rounded-full bg-secondary text-secondary-foreground capitalize">
                        {sale.paymentMethod}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm text-right font-bold text-foreground">{formatCurrency(sale.total)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            {currentSales.length === 0 && (
              <div className="text-center py-12 text-muted-foreground text-sm">No transactions for this period</div>
            )}
          </div>
        </div>
      </div>
    </AppLayout>
  );
};

export default Reports;
