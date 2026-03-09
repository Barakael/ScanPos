import { useState } from 'react';
import AppLayout from '@/components/layout/AppLayout';
import { useStore } from '@/contexts/StoreContext';
import { formatCurrency } from '@/data/mockData';
import { Product } from '@/types';
import {
  Search, Plus, Edit2, Trash2, Package, AlertTriangle, X, Save
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { motion } from 'framer-motion';
import { toast } from 'sonner';

const emptyProduct = { name: '', barcode: '', price: 0, stock: 0, category: '', lowStockThreshold: 10 };

const Inventory = () => {
  const { products, addProduct, updateProduct, deleteProduct } = useStore();
  const [search, setSearch] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [form, setForm] = useState(emptyProduct);
  const [filter, setFilter] = useState<'all' | 'low'>('all');

  const categories = [...new Set(products.map(p => p.category))];

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
    if (!form.name || !form.barcode || form.price <= 0) {
      toast.error('Please fill all required fields');
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

  return (
    <AppLayout>
      <div className="space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-foreground">Inventory</h1>
            <p className="text-sm text-muted-foreground">{products.length} products · {products.reduce((s, p) => s + p.stock, 0)} total units</p>
          </div>
          <Button onClick={openAdd} className="gap-2">
            <Plus className="w-4 h-4" /> Add Product
          </Button>
        </div>

        {/* Filters */}
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Search by name, barcode, or category..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="pl-10"
            />
          </div>
          <div className="flex gap-2">
            <Button variant={filter === 'all' ? 'default' : 'outline'} size="sm" onClick={() => setFilter('all')}>
              All
            </Button>
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
                      <span className={`text-sm font-bold ${
                        product.stock <= product.lowStockThreshold ? 'text-destructive' : 'text-foreground'
                      }`}>
                        {product.stock}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex items-center justify-end gap-1">
                        <button onClick={() => openEdit(product)} className="p-1.5 rounded hover:bg-muted text-muted-foreground hover:text-foreground">
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button onClick={() => handleDelete(product.id, product.name)} className="p-1.5 rounded hover:bg-destructive/10 text-muted-foreground hover:text-destructive">
                          <Trash2 className="w-4 h-4" />
                        </button>
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
      </div>

      {/* Add/Edit Dialog */}
      <Dialog open={showForm} onOpenChange={setShowForm}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editingProduct ? 'Edit Product' : 'Add New Product'}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="col-span-2 space-y-2">
                <Label>Product Name</Label>
                <Input value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} placeholder="e.g. Coca Cola 500ml" />
              </div>
              <div className="space-y-2">
                <Label>Barcode</Label>
                <Input value={form.barcode} onChange={e => setForm({ ...form, barcode: e.target.value })} placeholder="e.g. 5449000000996" className="font-mono" />
              </div>
              <div className="space-y-2">
                <Label>Category</Label>
                <Input
                  value={form.category}
                  onChange={e => setForm({ ...form, category: e.target.value })}
                  placeholder="e.g. Beverages"
                  list="categories"
                />
                <datalist id="categories">
                  {categories.map(c => <option key={c} value={c} />)}
                </datalist>
              </div>
              <div className="space-y-2">
                <Label>Price (TZS)</Label>
                <Input type="number" value={form.price} onChange={e => setForm({ ...form, price: Number(e.target.value) })} />
              </div>
              <div className="space-y-2">
                <Label>Stock</Label>
                <Input type="number" value={form.stock} onChange={e => setForm({ ...form, stock: Number(e.target.value) })} />
              </div>
              <div className="space-y-2">
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
