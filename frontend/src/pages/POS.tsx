import { useState, useRef, useEffect } from 'react';
import AppLayout from '@/components/layout/AppLayout';
import { useAuth } from '@/contexts/AuthContext';
import { useStore } from '@/contexts/StoreContext';
import { formatCurrency } from '@/data/mockData';
import { Sale } from '@/types';
import BarcodeScanner from '@/components/BarcodeScanner';
import {
  Camera, Keyboard, Trash2, Plus, Minus, CreditCard,
  Banknote, Smartphone, Printer, X, Check, Search
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { motion, AnimatePresence } from 'framer-motion';
import { toast } from 'sonner';

const POS = () => {
  const { user } = useAuth();
  const { products, cart, addToCart, removeFromCart, updateCartQuantity, clearCart, cartTotal, completeSale } = useStore();
  const [barcodeInput, setBarcodeInput] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [showScanner, setShowScanner] = useState(false);
  const [showReceipt, setShowReceipt] = useState(false);
  const [lastSale, setLastSale] = useState<Sale | null>(null);
  const barcodeRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    barcodeRef.current?.focus();
  }, []);

  const handleBarcodeScan = (barcode: string) => {
    if (!barcode.trim()) return;
    const product = addToCart(barcode.trim());
    if (product) {
      toast.success(`Added: ${product.name}`);
    } else {
      toast.error('Product not found or out of stock');
    }
    setBarcodeInput('');
    barcodeRef.current?.focus();
  };

  const handleCheckout = async (method: 'cash' | 'card' | 'mobile') => {
    if (cart.length === 0) {
      toast.error('Cart is empty');
      return;
    }
    try {
      const sale = await completeSale(method, user!.id, user!.name);
      setLastSale(sale);
      setShowReceipt(true);
      toast.success('Sale completed!');
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Failed to complete sale.');
    }
  };

  const handlePrint = () => {
    if (!lastSale) return;

    const itemRows = lastSale.items.map(item =>
      `<div class="item">
        <span>${item.quantity}x ${item.product.name}</span>
        <span>${formatCurrency(item.product.price * item.quantity)}</span>
      </div>`
    ).join('');

    const div = document.createElement('div');
    div.id = '__receipt__';
    div.innerHTML = `
      <h2>TeraPayS</h2>
      <p>Receipt #${lastSale.id}</p>
      <p>${new Date(lastSale.timestamp).toLocaleString()}</p>
      <p>Cashier: ${lastSale.cashierName}</p>
      <hr/>
      ${itemRows}
      <hr/>
      <div class="row total"><span>TOTAL</span><span>${formatCurrency(lastSale.total)}</span></div>
      <div class="row"><span>Payment</span><span>${lastSale.paymentMethod}</span></div>
      <p style="margin-top:12px;text-align:center;font-size:10px;">Thank you!</p>
    `;
    document.body.appendChild(div);
    window.print();
    document.body.removeChild(div);
  };

  const filteredProducts = products.filter(p =>
    p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    p.barcode.includes(searchQuery)
  );

  const grandTotal = cartTotal;

  return (
    <AppLayout>
      <div className="flex flex-col lg:flex-row gap-4 h-auto lg:h-[calc(100vh-6rem)]">
        {/* Left - Product Grid & Scanner */}
        <div className="flex-1 flex flex-col min-h-0">
          {/* Barcode Input Bar */}
          <div className="flex gap-2 mb-4">
            <div className="flex-1 relative">
              <Keyboard className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <Input
                ref={barcodeRef}
                placeholder="Scan or type barcode..."
                value={barcodeInput}
                onChange={e => setBarcodeInput(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && handleBarcodeScan(barcodeInput)}
                className="pl-10 font-mono"
              />
            </div>
            <Button onClick={() => handleBarcodeScan(barcodeInput)} variant="default">
              Add
            </Button>
            <Button onClick={() => setShowScanner(true)} variant="outline" size="icon">
              <Camera className="w-4 h-4" />
            </Button>
          </div>

          {/* Product Search */}
          <div className="relative mb-4">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Search products..."
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
              className="pl-10"
            />
          </div>

          {/* Product Grid */}
          <div className="flex-1 overflow-auto grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-4 gap-3 content-start">
            {filteredProducts.map(product => (
              <motion.button
                key={product.id}
                whileTap={{ scale: 0.97 }}
                onClick={() => {
                  const p = addToCart(product.barcode);
                  if (p) toast.success(`Added: ${p.name}`);
                  else toast.error('Out of stock');
                }}
                className="glass-card rounded-xl p-4 text-left hover:border-primary/50 transition-all group"
              >
                <div className="flex items-start justify-between mb-2">
                  <span className="text-xs font-mono text-muted-foreground">{product.barcode.slice(-6)}</span>
                  <span className={`text-xs font-medium px-1.5 py-0.5 rounded ${
                    product.stock <= product.lowStockThreshold
                      ? 'bg-destructive/10 text-destructive'
                      : 'bg-accent text-accent-foreground'
                  }`}>
                    {product.stock}
                  </span>
                </div>
                <p className="text-sm font-medium text-foreground mb-1 line-clamp-2">{product.name}</p>
                <p className="text-sm font-bold text-primary">{formatCurrency(product.price)}</p>
              </motion.button>
            ))}
          </div>
        </div>

        {/* Right - Cart */}
        <div className="w-full lg:w-96 glass-card rounded-xl flex flex-col">
          <div className="p-4 border-b border-border">
            <div className="flex items-center justify-between">
              <h2 className="font-semibold text-foreground">Current Sale</h2>
              {cart.length > 0 && (
                <button onClick={clearCart} className="text-xs text-destructive hover:underline">
                  Clear All
                </button>
              )}
            </div>
            <p className="text-xs text-muted-foreground">{cart.length} items</p>
          </div>

          {/* Cart Items */}
          <div className="flex-1 overflow-auto p-4 space-y-2">
            <AnimatePresence>
              {cart.length === 0 ? (
                <div className="flex items-center justify-center h-32 text-muted-foreground text-sm">
                  Scan items to begin
                </div>
              ) : (
                cart.map(item => (
                  <motion.div
                    key={item.product.id}
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -20 }}
                    className="flex items-center gap-3 p-3 rounded-lg bg-muted/50"
                  >
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-foreground truncate">{item.product.name}</p>
                      <p className="text-xs text-muted-foreground">{formatCurrency(item.product.price)} each</p>
                    </div>
                    <div className="flex items-center gap-1.5">
                      <button
                        onClick={() => updateCartQuantity(item.product.id, item.quantity - 1)}
                        className="w-6 h-6 rounded bg-secondary flex items-center justify-center hover:bg-secondary/80"
                      >
                        <Minus className="w-3 h-3" />
                      </button>
                      <span className="text-sm font-mono w-6 text-center">{item.quantity}</span>
                      <button
                        onClick={() => updateCartQuantity(item.product.id, item.quantity + 1)}
                        className="w-6 h-6 rounded bg-secondary flex items-center justify-center hover:bg-secondary/80"
                      >
                        <Plus className="w-3 h-3" />
                      </button>
                    </div>
                    <p className="text-sm font-bold text-foreground w-20 text-right">
                      {formatCurrency(item.product.price * item.quantity)}
                    </p>
                    <button
                      onClick={() => removeFromCart(item.product.id)}
                      className="text-muted-foreground hover:text-destructive"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </motion.div>
                ))
              )}
            </AnimatePresence>
          </div>

          {/* Totals & Payment */}
          <div className="border-t border-border p-4 space-y-3">
            <div className="space-y-1 text-sm">
              <div className="flex justify-between text-lg font-bold text-foreground border-t border-border pt-2">
                <span>Total</span>
                <span className="text-primary">{formatCurrency(grandTotal)}</span>
              </div>
            </div>

            <div className="grid grid-cols-3 gap-2">
              <Button onClick={() => handleCheckout('cash')} className="flex-col h-14 gap-1" disabled={cart.length === 0}>
                <Banknote className="w-4 h-4" />
                <span className="text-xs">Cash</span>
              </Button>
              <Button onClick={() => handleCheckout('card')} variant="secondary" className="flex-col h-14 gap-1" disabled={cart.length === 0}>
                <CreditCard className="w-4 h-4" />
                <span className="text-xs">Card</span>
              </Button>
              <Button onClick={() => handleCheckout('mobile')} variant="secondary" className="flex-col h-14 gap-1" disabled={cart.length === 0}>
                <Smartphone className="w-4 h-4" />
                <span className="text-xs">Mobile</span>
              </Button>
            </div>
          </div>
        </div>
      </div>

      {/* Camera Scanner Dialog */}
      <Dialog open={showScanner} onOpenChange={setShowScanner}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Camera className="w-4 h-4" />
              Camera Scanner
            </DialogTitle>
          </DialogHeader>
          <BarcodeScanner
            active={showScanner}
            onScan={(barcode) => {
              setShowScanner(false);
              const product = addToCart(barcode);
              if (product) {
                toast.success(`Added: ${product.name}`);
              } else {
                toast.error(`Barcode ${barcode} not found or out of stock`);
              }
            }}
            onError={(msg) => toast.error(msg)}
          />
          <p className="text-xs text-muted-foreground text-center">
            Hold the barcode steady inside the frame.
          </p>
        </DialogContent>
      </Dialog>

      {/* Receipt Dialog */}
      <Dialog open={showReceipt} onOpenChange={setShowReceipt}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Check className="w-5 h-5 text-primary" />
              Sale Complete
            </DialogTitle>
          </DialogHeader>
          {lastSale && (
            <div id="print-receipt" className="print-receipt">
              <div className="text-center border-b border-dashed border-border pb-4 mb-4">
                <h3 className="font-bold text-foreground">MyPOS</h3>
                <p className="text-xs text-muted-foreground">Receipt #{lastSale.id}</p>
                <p className="text-xs text-muted-foreground">
                  {new Date(lastSale.timestamp).toLocaleString()}
                </p>
                <p className="text-xs text-muted-foreground">Cashier: {lastSale.cashierName}</p>
              </div>

              <div className="space-y-2 border-b border-dashed border-border pb-4 mb-4">
                {lastSale.items.map(item => (
                  <div key={item.product.id} className="flex justify-between text-sm">
                    <div>
                      <p className="text-foreground">{item.product.name}</p>
                      <p className="text-xs text-muted-foreground">
                        {item.quantity} x {formatCurrency(item.product.price)}
                      </p>
                    </div>
                    <span className="font-mono text-foreground">
                      {formatCurrency(item.product.price * item.quantity)}
                    </span>
                  </div>
                ))}
              </div>

              <div className="space-y-1 text-sm mb-4">
                <div className="flex justify-between font-bold text-foreground text-base">
                  <span>Total</span>
                  <span>{formatCurrency(lastSale.total)}</span>
                </div>
                <div className="flex justify-between text-muted-foreground">
                  <span>Payment</span>
                  <span className="capitalize">{lastSale.paymentMethod}</span>
                </div>
              </div>

              <div className="text-center text-xs text-muted-foreground">
                <p>Thank you for your purchase!</p>
                <p>Powered by MyPOS</p>
              </div>
            </div>
          )}

          <div className="flex gap-2 mt-4">
            <Button onClick={handlePrint} className="flex-1 gap-2">
              <Printer className="w-4 h-4" />
              Print Receipt
            </Button>
            <Button onClick={() => setShowReceipt(false)} variant="outline">
              Close
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </AppLayout>
  );
};

export default POS;
