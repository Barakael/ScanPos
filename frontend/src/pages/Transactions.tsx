import { useState } from 'react';
import AppLayout from '@/components/layout/AppLayout';
import { useQuery } from '@tanstack/react-query';
import api from '@/services/api';
import { formatCurrency } from '@/data/mockData';
import { Search, Receipt, Calendar, ChevronDown, ChevronRight, Banknote, CreditCard, Smartphone } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { motion, AnimatePresence } from 'framer-motion';

interface SaleItemRow {
  id: number;
  product_id: number;
  product_name: string;
  unit_price: number;
  quantity: number;
}

interface SaleRow {
  id: number;
  cashier_id: number;
  subtotal: number;
  tax: number;
  total: number;
  payment_method: 'cash' | 'card' | 'mobile';
  created_at: string;
  items: SaleItemRow[];
  cashier?: { id: number; name: string };
}

const METHOD_ICON = {
  cash:   <Banknote className="w-3.5 h-3.5" />,
  card:   <CreditCard className="w-3.5 h-3.5" />,
  mobile: <Smartphone className="w-3.5 h-3.5" />,
};

const METHOD_BADGE: Record<string, string> = {
  cash:   'bg-green-100 text-green-700',
  card:   'bg-blue-100 text-blue-700',
  mobile: 'bg-purple-100 text-purple-700',
};

export default function Transactions() {
  const [search, setSearch] = useState('');
  const [date, setDate] = useState('');
  const [expanded, setExpanded] = useState<number | null>(null);

  const { data: sales = [], isLoading, refetch, isFetching } = useQuery<SaleRow[]>({
    queryKey: ['sales-all', date],
    queryFn: async () => {
      const params = date ? `?date=${date}` : '';
      const { data } = await api.get(`/sales${params}`);
      return data;
    },
    staleTime: 1000 * 30,
  });

  const filtered = sales.filter(s => {
    const q = search.toLowerCase();
    return (
      String(s.id).includes(q) ||
      (s.cashier?.name ?? '').toLowerCase().includes(q) ||
      s.payment_method.includes(q) ||
      s.items.some(i => i.product_name.toLowerCase().includes(q))
    );
  });

  const totalRevenue = filtered.reduce((sum, s) => sum + s.total, 0);

  return (
    <AppLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-foreground flex items-center gap-2">
              <Receipt className="w-6 h-6 text-primary" /> Transactions
            </h1>
            <p className="text-sm text-muted-foreground">
              {filtered.length} transaction{filtered.length !== 1 ? 's' : ''} · {formatCurrency(totalRevenue)} total
            </p>
          </div>
          <Button variant="outline" size="sm" onClick={() => refetch()} disabled={isFetching} className="gap-2 self-start">
            Refresh
          </Button>
        </div>

        {/* Filters */}
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Search by ID, cashier, product, or payment method…"
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="pl-10"
            />
          </div>
          <div className="relative">
            <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
            <Input
              type="date"
              value={date}
              onChange={e => setDate(e.target.value)}
              className="pl-10 w-44"
            />
          </div>
          {date && (
            <Button variant="ghost" size="sm" onClick={() => setDate('')}>
              Clear date
            </Button>
          )}
        </div>

        {/* Table */}
        <div className="glass-card rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/40">
                  <th className="w-8 px-4 py-3" />
                  
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Date & Time</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Cashier</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Method</th>
                  <th className="text-right px-4 py-3 font-medium text-muted-foreground">Items</th>
                  <th className="text-right px-4 py-3 font-medium text-muted-foreground">Total</th>
                </tr>
              </thead>
              <tbody>
                {isLoading
                  ? Array.from({ length: 8 }).map((_, i) => (
                      <tr key={i} className="border-b border-border/40">
                        {Array.from({ length: 7 }).map((__, j) => (
                          <td key={j} className="px-4 py-3">
                            <div className="h-4 bg-muted rounded animate-pulse" />
                          </td>
                        ))}
                      </tr>
                    ))
                  : filtered.length === 0
                  ? (
                    <tr>
                      <td colSpan={7} className="px-4 py-12 text-center text-muted-foreground">
                        No transactions found
                      </td>
                    </tr>
                  )
                  : filtered.map((sale, i) => (
                    <>
                      <motion.tr
                        key={sale.id}
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        transition={{ delay: i * 0.02 }}
                        onClick={() => setExpanded(expanded === sale.id ? null : sale.id)}
                        className="border-b border-border/40 hover:bg-muted/30 transition-colors cursor-pointer"
                      >
                        <td className="px-4 py-3 text-muted-foreground">
                          {expanded === sale.id
                            ? <ChevronDown className="w-4 h-4" />
                            : <ChevronRight className="w-4 h-4" />
                          }
                        </td>
                      
                        <td className="px-4 py-3 text-muted-foreground">
                          {new Date(sale.created_at).toLocaleString()}
                        </td>
                        <td className="px-4 py-3 font-medium">{sale.cashier?.name ?? `User #${sale.cashier_id}`}</td>
                        <td className="px-4 py-3">
                          <span className={`inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded-full font-medium ${METHOD_BADGE[sale.payment_method] ?? 'bg-gray-100 text-gray-600'}`}>
                            {METHOD_ICON[sale.payment_method]}
                            {sale.payment_method}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-right text-muted-foreground">
                          {sale.items.reduce((s, it) => s + it.quantity, 0)}
                        </td>
                        <td className="px-4 py-3 text-right font-bold font-mono">
                          {formatCurrency(sale.total)}
                        </td>
                      </motion.tr>
                      <AnimatePresence>
                        {expanded === sale.id && (
                          <motion.tr
                            key={`${sale.id}-items`}
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            exit={{ opacity: 0 }}
                          >
                            <td colSpan={7} className="px-0 py-0 bg-muted/20">
                              <div className="px-12 py-3">
                                <table className="w-full text-xs">
                                  <thead>
                                    <tr className="text-muted-foreground">
                                      <th className="text-left py-1 font-medium">Product</th>
                                      <th className="text-right py-1 font-medium">Unit Price</th>
                                      <th className="text-right py-1 font-medium">Qty</th>
                                      <th className="text-right py-1 font-medium">Subtotal</th>
                                    </tr>
                                  </thead>
                                  <tbody>
                                    {sale.items.map(item => (
                                      <tr key={item.id} className="border-t border-border/20">
                                        <td className="py-1.5">{item.product_name}</td>
                                        <td className="py-1.5 text-right font-mono">{formatCurrency(item.unit_price)}</td>
                                        <td className="py-1.5 text-right">{item.quantity}</td>
                                        <td className="py-1.5 text-right font-mono font-medium">{formatCurrency(item.unit_price * item.quantity)}</td>
                                      </tr>
                                    ))}
                                  </tbody>
                                </table>
                              </div>
                            </td>
                          </motion.tr>
                        )}
                      </AnimatePresence>
                    </>
                  ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </AppLayout>
  );
}
