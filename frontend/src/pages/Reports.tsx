import { useState } from 'react';
import AppLayout from '@/components/layout/AppLayout';
import { useStore } from '@/contexts/StoreContext';
import { formatCurrency } from '@/data/mockData';
import { useAuth } from '@/contexts/AuthContext';
import { useQuery } from '@tanstack/react-query';
import { subscriptionsApi, subscriptionPaymentsApi, SubscriptionRow, SubscriptionPaymentRow } from '@/services/api';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, LineChart, Line, AreaChart, Area
} from 'recharts';
import { Calendar, TrendingUp, DollarSign, ShoppingCart, CreditCard } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { motion } from 'framer-motion';

type Period = 'daily' | 'weekly' | 'monthly';
type Tab = 'sales' | 'payments';

const Reports = () => {
  const { sales } = useStore();
  const { user } = useAuth();
  const [period, setPeriod] = useState<Period>('daily');
  const [tab, setTab] = useState<Tab>('sales');

  // Payments data (owner only)
  const { data: subscription } = useQuery<SubscriptionRow | null>({
    queryKey: ['subscription-owner'],
    queryFn: subscriptionsApi.getOwner,
    enabled: user?.role === 'owner',
  });
  const { data: paymentHistory = [] } = useQuery<SubscriptionPaymentRow[]>({
    queryKey: ['subscription-payments'],
    queryFn: subscriptionPaymentsApi.getAll,
    enabled: user?.role === 'owner',
  });

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
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-foreground">Reports</h1>
            <p className="text-sm text-muted-foreground">Track performance across all time periods</p>
          </div>
          {/* Tab switcher */}
          <div className="flex gap-2">
            <Button variant={tab === 'sales' ? 'default' : 'outline'} size="sm" onClick={() => setTab('sales')}>
              <ShoppingCart className="w-3.5 h-3.5 mr-1.5" /> Sales
            </Button>
            {user?.role === 'owner' && (
              <Button variant={tab === 'payments' ? 'default' : 'outline'} size="sm" onClick={() => setTab('payments')}>
                <CreditCard className="w-3.5 h-3.5 mr-1.5" /> Subscription
              </Button>
            )}
          </div>
        </div>

        {/* ── PAYMENTS TAB ────────────────────────────────────────── */}
        {tab === 'payments' && (
          <div className="space-y-6">
            {/* Subscription card */}
            {subscription ? (
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="glass-card rounded-xl p-5 col-span-2">
                  <p className="text-xs text-muted-foreground mb-1">Current Plan</p>
                  <p className="text-2xl font-bold">{subscription.plan_name}</p>
                  <p className="text-sm text-muted-foreground">${subscription.plan_price.toFixed(2)} / month</p>
                  <span className={`inline-block mt-3 text-xs px-2 py-0.5 rounded-full font-medium ${
                    subscription.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                  }`}>{subscription.status}</span>
                </div>
                <div className="glass-card rounded-xl p-5">
                  <p className="text-xs text-muted-foreground mb-1">Next Payment Due</p>
                  <p className="text-lg font-bold">{subscription.next_due_at ? new Date(subscription.next_due_at).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' }) : '—'}</p>
                  {subscription.days_until_due !== null && (
                    <p className={`text-xs mt-1 ${subscription.days_until_due < 0 ? 'text-red-600' : subscription.days_until_due <= 7 ? 'text-yellow-600' : 'text-muted-foreground'}`}>
                      {subscription.days_until_due < 0 ? `${Math.abs(subscription.days_until_due)} days overdue` : subscription.days_until_due === 0 ? 'Due today' : `${subscription.days_until_due} days left`}
                    </p>
                  )}
                </div>
              </div>
            ) : (
              <div className="glass-card rounded-xl p-8 text-center text-muted-foreground">
                No active subscription. Contact your platform administrator.
              </div>
            )}

            {/* Payment history table */}
            <div className="glass-card rounded-xl p-6">
              <h3 className="text-sm font-semibold mb-4">Payment History</h3>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b">
                      <th className="text-left px-4 py-2 font-medium text-muted-foreground">Plan</th>
                      <th className="text-left px-4 py-2 font-medium text-muted-foreground">Amount</th>
                      <th className="text-left px-4 py-2 font-medium text-muted-foreground">Due Date</th>
                      <th className="text-left px-4 py-2 font-medium text-muted-foreground">Paid On</th>
                      <th className="text-left px-4 py-2 font-medium text-muted-foreground">Method</th>
                      <th className="text-left px-4 py-2 font-medium text-muted-foreground">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {paymentHistory.map(p => (
                      <tr key={p.id} className="border-b hover:bg-muted/30 transition-colors">
                        <td className="px-4 py-3">{p.plan_name}</td>
                        <td className="px-4 py-3 font-mono">${p.amount.toFixed(2)}</td>
                        <td className="px-4 py-3">{p.due_date ? new Date(p.due_date).toLocaleDateString() : '—'}</td>
                        <td className="px-4 py-3">{p.paid_at ? new Date(p.paid_at).toLocaleDateString() : '—'}</td>
                        <td className="px-4 py-3 capitalize">{p.payment_method ?? '—'}</td>
                        <td className="px-4 py-3">
                          <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                            p.status === 'paid'    ? 'bg-green-100 text-green-700' :
                            p.status === 'pending' ? 'bg-yellow-100 text-yellow-700' :
                            'bg-red-100 text-red-700'
                          }`}>{p.status}</span>
                        </td>
                      </tr>
                    ))}
                    {paymentHistory.length === 0 && (
                      <tr><td colSpan={6} className="py-8 text-center text-muted-foreground">No payment history yet</td></tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* ── SALES TAB ───────────────────────────────────────────── */}
        {tab === 'sales' && (
          <>
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
          </>
        )}
      </div>
    </AppLayout>
  );
};

export default Reports;
