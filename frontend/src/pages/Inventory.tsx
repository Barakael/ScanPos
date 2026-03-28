import { useState } from 'react';
import AppLayout from '@/components/layout/AppLayout';
import { useStore } from '@/contexts/StoreContext';
import { useAuth } from '@/contexts/AuthContext';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { categoriesApi, ShopCategory } from '@/services/api';
import { formatCurrency } from '@/data/mockData';
import { Product } from '@/types';
import {
  Search, Plus, Edit2, Trash2, Package, AlertTriangle, Save, Tag, ChevronDown,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { motion, AnimatePresence } from 'framer-motion';
import { toast } from 'sonner';

type Tab = 'products' | 'categories';

const emptyProduct = { name: '', barcode: '', price: 0, stock: 0, category: '', lowStockThreshold: 10 };

const Inventory = () => {
  const { products, addProduct, updateProduct, deleteProduct } = useStore();
  const { user } = useAuth();
  const qc = useQueryClient();
  const canManage = user?.role === 'owner' || user?.role === 'super_admin';

  const [tab, setTab] = useState<Tab>('products');
  const [search, setSearch] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [form, setForm] = useState(emptyProduct);
  const [filter, setFilter] = useState<'all' | 'low'>('all');
  const [newCatName, setNewCatName] = useState('');

  // ── Categories from API ──────────────────────────────────────────────────
  const { data: apiCategories = [], isLoading: catsLoading } = useQuery<ShopCategory[]>({
    queryKey: ['categories'],
    queryFn: categoriesApi.getAll,
  });

  const allCategoryNames = [
    ...new Set([
      ...apiCategories.map(c => c.name),
      ...products.map(p => p.category).filter(Boolean),
    ]),
  ].sort();

  const addCategoryMutation = useMutation({
    mutationFn: (name: string) => categoriesApi.create(name),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['categories'] });
      setNewCatName('');
      toast.success('Category added');
    },
    onError: (err: Error) => toast.error(err.message),
  });

  const deleteCategoryMutation = useMutation({
    mutationFn: (id: number) => categoriesApi.delete(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['categories'] });
      toast.success('Category removed');
    },
    onError: (err: Error) => toast.error(err.message),
  });

  const filtered = products
    .filter(p => filter === 'low' ? p.stock <= p.lowStockThreshold : true)
    .filter(p =>
      p.name.toLowerCase().includes(search.toLowerCase()) ||
      p.barcode.includes(search) ||
      p.category.toLowerCase().includes(search.toLowerCase())
    );

  const openAdd = () => {
    setEditingProduct(null);
    setForm(emptyProduct);
    setShowForm(true);
  };

  const openEdit = (product: Product) => {
    setEditingProduct(product);
    setForm({
      name: product.name,
      barcode: product.barcode,
      price: product.price,
      stock: product.stock,
      category: product.category,
      lowStockThreshold: product.lowStockThreshold,
    });
    setShowForm(true);
  };

  const handleSave = async () => {
    if (!form.name || !form.barcode || !form.category || form.price <= 0) {
      toast.error(!form.category ? 'Category is required' : 'Please fill all required fields (name, barcode, price > 0, category)');
      return;
    }
    try {
      if (editingProduct) {
        await updateProduct(editingProduct.id, form);
        toast.success('Product updated');
      } else {
        await addProduct(form);
        toast.success('Product added');
      }
      setShowForm(false);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Failed to save product.');
    }
  };

  const handleDelete = async (id: string, name: string) => {
    if (confirm(`Delete "${name}"?`)) {
      try {
        await deleteProduct(id);
        toast.success('Product deleted');
      } catch (err) {
        toast.error(err instanceof Error ? err.message : 'Failed to delete product.');
      }
    }
  };

  const handleAddCategory = () => {
    const trimmed = newCatName.trim();
    if (!trimmed) return;
    addCategoryMutation.mutate(trimmed);
  };

  return (
    <AppLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-foreground">Inventory</h1>
            <p className="text-sm text-muted-foreground">
              {products.length} products · {products.reduce((s, p) => s + p.stock, 0)} total units
            </p>
          </div>
          {canManage && tab === 'products' && (
            <Button onClick={openAdd} className="gap-2">
              <Plus className="w-4 h-4" /> Add Product
            </Button>
          )}
        </div>

        {/* Tab switcher */}
        <div className="flex gap-2 border-b border-border pb-0">
          {(['products', 'categories'] as Tab[]).map(t => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`px-4 py-2 text-sm font-medium capitalize transition-colors border-b-2 -mb-px ${
                tab === t
                  ? 'border-primary text-primary'
                  : 'border-transparent text-muted-foreground hover:text-foreground'
              }`}
            >
              {t === 'products' ? (
                <span className="flex items-center gap-1.5"><Package className="w-3.5 h-3.5" /> Products</span>
              ) : (
                <span className="flex items-center gap-1.5"><Tag className="w-3.5 h-3.5" /> Categories</span>
              )}
            </button>
          ))}
        </div>

        <AnimatePresence mode="wait">
          {/* ── PRODUCTS TAB ─────────────────────────────────────────── */}
          {tab === 'products' && (
            <motion.div
              key="products"
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={{ duration: 0.15 }}
              className="space-y-4"
            >
              {/* Filters */}
              <div className="flex flex-col sm:flex-row gap-3">
                <div className="relative flex-1">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                  <Input
                    placeholder="Search by name, barcode, or category…"
                    value={search}
                    onChange={e => setSearch(e.target.value)}
                    className="pl-10"
                  />
                </div>
                <div className="flex gap-2">
                  <Button variant={filter === 'all' ? 'default' : 'outline'} size="sm" onClick={() => setFilter('all')}>All</Button>
                  <Button variant={filter === 'low' ? 'default' : 'outline'} size="sm" onClick={() => setFilter('low')} className="gap-1">
                    <AlertTriangle className="w-3 h-3" /> Low Stock
                  </Button>
                </div>
              </div>

              {/* Product Table */}
              <div className="glass-card rounded-xl overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead>
                      <tr className="border-b border-border">
                        <th className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">Product</th>
                        <th className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">Barcode</th>
                        <th className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">Category</th>
                        <th className="text-right text-xs font-semibold text-muted-foreground px-4 py-3">Price</th>
                        <th className="text-right text-xs font-semibold text-muted-foreground px-4 py-3">Stock</th>
                        <th className="text-right text-xs font-semibold text-muted-foreground px-4 py-3">Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filtered.map((product, i) => (
                        <motion.tr
                          key={product.id}
                          initial={{ opacity: 0 }}
                          animate={{ opacity: 1 }}
                          transition={{ delay: i * 0.03 }}
                          className="border-b border-border/50 hover:bg-muted/30 transition-colors"
                        >
                          <td className="px-4 py-3">
                            <div className="flex items-center gap-3">
                              <div className="w-8 h-8 rounded-lg bg-accent flex items-center justify-center">
                                <Package className="w-4 h-4 text-accent-foreground" />
                              </div>
                              <span className="text-sm font-medium text-foreground">{product.name}</span>
                            </div>
                          </td>
                          <td className="px-4 py-3 text-sm font-mono text-muted-foreground">{product.barcode}</td>
                          <td className="px-4 py-3">
                            <span className="text-xs px-2 py-1 rounded-full bg-secondary text-secondary-foreground">
                              {product.category}
                            </span>
                          </td>
                          <td className="px-4 py-3 text-sm text-right font-medium text-foreground">{formatCurrency(product.price)}</td>
                          <td className="px-4 py-3 text-right">
                            <span className={`text-sm font-bold ${product.stock <= product.lowStockThreshold ? 'text-destructive' : 'text-foreground'}`}>
                              {product.stock}
                            </span>
                          </td>
                          <td className="px-4 py-3 text-right">
                            <div className="flex items-center justify-end gap-1">
                              {canManage && (
                                <>
                                  <button onClick={() => openEdit(product)} className="p-1.5 rounded hover:bg-muted text-muted-foreground hover:text-foreground">
                                    <Edit2 className="w-4 h-4" />
                                  </button>
                                  <button onClick={() => handleDelete(product.id, product.name)} className="p-1.5 rounded hover:bg-destructive/10 text-muted-foreground hover:text-destructive">
                                    <Trash2 className="w-4 h-4" />
                                  </button>
                                </>
                              )}
                            </div>
                          </td>
                        </motion.tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                {filtered.length === 0 && (
                  <div className="text-center py-12 text-muted-foreground text-sm">No products found</div>
                )}
              </div>
            </motion.div>
          )}

          {/* ── CATEGORIES TAB ───────────────────────────────────────── */}
          {tab === 'categories' && (
            <motion.div
              key="categories"
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={{ duration: 0.15 }}
              className="space-y-4"
            >
              {canManage && (
                <div className="glass-card rounded-xl p-5">
                  <h3 className="text-sm font-semibold mb-3">Add New Category</h3>
                  <div className="flex gap-2">
                    <Input
                      placeholder="e.g. Beverages, Dairy, Electronics…"
                      value={newCatName}
                      onChange={e => setNewCatName(e.target.value)}
                      onKeyDown={e => e.key === 'Enter' && handleAddCategory()}
                      className="flex-1"
                    />
                    <Button
                      onClick={handleAddCategory}
                      disabled={!newCatName.trim() || addCategoryMutation.isPending}
                      className="gap-2"
                    >
                      <Plus className="w-4 h-4" />
                      {addCategoryMutation.isPending ? 'Adding…' : 'Add'}
                    </Button>
                  </div>
                </div>
              )}

              <div className="glass-card rounded-xl overflow-hidden">
                <div className="px-5 py-3 border-b border-border">
                  <h3 className="text-sm font-semibold">
                    Your Categories
                    <span className="ml-2 text-xs text-muted-foreground font-normal">({apiCategories.length})</span>
                  </h3>
                </div>
                {catsLoading ? (
                  <div className="p-8 text-center text-muted-foreground text-sm">Loading…</div>
                ) : apiCategories.length === 0 ? (
                  <div className="p-8 text-center">
                    <Tag className="w-8 h-8 mx-auto mb-2 text-muted-foreground opacity-50" />
                    <p className="text-sm text-muted-foreground">No categories yet.</p>
                    {canManage && <p className="text-xs text-muted-foreground mt-1">Add your first category above.</p>}
                  </div>
                ) : (
                  <div className="divide-y divide-border">
                    {apiCategories.map(cat => {
                      const productCount = products.filter(p => p.category === cat.name).length;
                      return (
                        <motion.div
                          key={cat.id}
                          layout
                          initial={{ opacity: 0 }}
                          animate={{ opacity: 1 }}
                          exit={{ opacity: 0 }}
                          className="flex items-center justify-between px-5 py-3 hover:bg-muted/20 transition-colors"
                        >
                          <div className="flex items-center gap-3">
                            <span className="w-7 h-7 rounded-lg bg-primary/10 flex items-center justify-center">
                              <Tag className="w-3.5 h-3.5 text-primary" />
                            </span>
                            <span className="text-sm font-medium">{cat.name}</span>
                            <span className="text-xs text-muted-foreground">{productCount} product{productCount !== 1 ? 's' : ''}</span>
                          </div>
                          {canManage && (
                            <button
                              onClick={() => deleteCategoryMutation.mutate(cat.id)}
                              disabled={deleteCategoryMutation.isPending}
                              className="p-1.5 rounded hover:bg-destructive/10 text-muted-foreground hover:text-destructive transition-colors"
                              title="Delete category"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          )}
                        </motion.div>
                      );
                    })}
                  </div>
                )}
              </div>

              {/* Pill buttons for product categories not yet in API list */}
              {allCategoryNames.filter(n => !apiCategories.some(c => c.name === n)).length > 0 && (
                <div className="rounded-xl border border-dashed border-border p-4">
                  <p className="text-xs text-muted-foreground mb-2 flex items-center gap-1">
                    <ChevronDown className="w-3 h-3" />
                    Categories used in existing products (click to save):
                  </p>
                  <div className="flex flex-wrap gap-2">
                    {allCategoryNames
                      .filter(n => !apiCategories.some(c => c.name === n))
                      .map(name => (
                        <button
                          key={name}
                          onClick={() => canManage && addCategoryMutation.mutate(name)}
                          className={`text-xs px-2.5 py-1 rounded-full bg-secondary text-secondary-foreground transition-colors ${canManage ? 'hover:bg-primary hover:text-primary-foreground cursor-pointer' : ''}`}
                          title={canManage ? `Save "${name}" as a category` : name}
                        >
                          {name}
                        </button>
                      ))}
                  </div>
                </div>
              )}
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Add / Edit Product Dialog */}
      <Dialog open={showForm} onOpenChange={setShowForm}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editingProduct ? 'Edit Product' : 'Add New Product'}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="col-span-2 space-y-2">
                <Label>Product Name *</Label>
                <Input value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} placeholder="e.g. Coca Cola 500ml" />
              </div>
              <div className="space-y-2">
                <Label>Barcode *</Label>
                <Input value={form.barcode} onChange={e => setForm({ ...form, barcode: e.target.value })} placeholder="e.g. 5449000000996" className="font-mono" />
              </div>
              <div className="space-y-2">
                <Label>Category *</Label>
                {apiCategories.length > 0 ? (
                  <select
                    value={form.category}
                    onChange={e => setForm({ ...form, category: e.target.value })}
                    className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
                  >
                    <option value="">Select category…</option>
                    {allCategoryNames.map(c => (
                      <option key={c} value={c}>{c}</option>
                    ))}
                  </select>
                ) : (
                  <>
                    <Input
                      value={form.category}
                      onChange={e => setForm({ ...form, category: e.target.value })}
                      placeholder="e.g. Beverages"
                      list="cat-list"
                    />
                    <datalist id="cat-list">
                      {allCategoryNames.map(c => <option key={c} value={c} />)}
                    </datalist>
                    <p className="text-xs text-muted-foreground">
                      No saved categories.{' '}
                      <button type="button" className="underline" onClick={() => { setShowForm(false); setTab('categories'); }}>
                        Add categories first
                      </button>.
                    </p>
                  </>
                )}
              </div>
              <div className="space-y-2">
                <Label>Price (TZS) *</Label>
                <Input type="number" value={form.price} onChange={e => setForm({ ...form, price: Number(e.target.value) })} />
              </div>
              <div className="space-y-2">
                <Label>Stock</Label>
                <Input type="number" value={form.stock} onChange={e => setForm({ ...form, stock: Number(e.target.value) })} />
              </div>
              <div className="col-span-2 space-y-2">
                <Label>Low Stock Threshold</Label>
                <Input type="number" value={form.lowStockThreshold} onChange={e => setForm({ ...form, lowStockThreshold: Number(e.target.value) })} />
              </div>
            </div>
            <div className="flex gap-2 justify-end">
              <Button variant="outline" onClick={() => setShowForm(false)}>Cancel</Button>
              <Button onClick={handleSave} className="gap-2">
                <Save className="w-4 h-4" /> {editingProduct ? 'Update' : 'Add'} Product
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </AppLayout>
  );
};

export default Inventory;

