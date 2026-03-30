import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../products/presentation/bloc/products_bloc.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../sales/presentation/bloc/sales_bloc.dart';
import '../../../sales/presentation/bloc/sales_event.dart';
import '../../../sales/presentation/bloc/sales_state.dart';
import '../widgets/barcode_scanner_widget.dart';
import '../widgets/payment_method_dialog.dart';
import '../widgets/receipt_dialog.dart';
import '../../domain/models/cart_item.dart';

// ════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ════════════════════════════════════════════════════════════════════════════
class _T {
  // Colors
  static const bg         = Color(0xFFF5F6FA);
  static const white      = Color(0xFFFFFFFF);
  static const card       = Color(0xFFFFFFFF);
  static const primary    = Color(0xFF1E3A5F);
  static const primaryLt  = Color(0xFF2B527A);
  static const accent     = Color(0xFF00C896);
  static const accentSoft = Color(0x1A00C896);
  static const danger     = Color(0xFFFF4D4D);
  static const dangerSoft = Color(0x1AFF4D4D);
  static const warn       = Color(0xFFFFA726);
  static const warnSoft   = Color(0x1AFFA726);
  static const ink        = Color(0xFF1A2332);
  static const inkMid     = Color(0xFF64748B);
  static const inkLight   = Color(0xFFCBD5E1);
  static const border     = Color(0xFFE8EDF5);

  // Typography helpers
  static TextStyle ts(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = ink,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF1E3A5F).withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get floatShadow => [
        BoxShadow(
          color: const Color(0xFF1E3A5F).withOpacity(0.14),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

// ════════════════════════════════════════════════════════════════════════════
// MAIN PAGE
// ════════════════════════════════════════════════════════════════════════════
class POSPage extends StatefulWidget {
  const POSPage({super.key});

  @override
  State<POSPage> createState() => _POSPageState();
}

class _POSPageState extends State<POSPage> with TickerProviderStateMixin {
  final List<CartItem> _cart = [];
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _showScanner = false;

  // Animations
  late final AnimationController _cartBadgeCtrl;
  late final Animation<double>   _cartBadgeAnim;

  @override
  void initState() {
    super.initState();
    context.read<ProductsBloc>().add(const ProductsFetchRequested());

    _cartBadgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _cartBadgeAnim = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _cartBadgeCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _cartBadgeCtrl.dispose();
    super.dispose();
  }

  // ── Cart logic ─────────────────────────────────────────────────────────────
  void _addToCart(ProductEntity product) {
    HapticFeedback.lightImpact();
    setState(() {
      final idx = _cart.indexWhere((i) => i.product.id == product.id);
      if (idx != -1) {
        if (_cart[idx].quantity < product.stock) {
          _cart[idx] = CartItem(
              product: product, quantity: _cart[idx].quantity + 1);
          _cartBadgeCtrl.forward(from: 0);
        } else {
          _toast('Max stock reached for ${product.name}', isError: true);
        }
      } else {
        if (product.stock > 0) {
          _cart.add(CartItem(product: product, quantity: 1));
          _cartBadgeCtrl.forward(from: 0);
        } else {
          _toast('${product.name} is out of stock', isError: true);
        }
      }
    });
  }

  void _updateQty(String id, int qty) {
    setState(() {
      final idx = _cart.indexWhere((i) => i.product.id == id);
      if (idx == -1) return;
      if (qty <= 0) {
        _cart.removeAt(idx);
      } else if (qty <= _cart[idx].product.stock) {
        _cart[idx] = CartItem(product: _cart[idx].product, quantity: qty);
      } else {
        _toast('Insufficient stock', isError: true);
      }
    });
  }

  void _removeFromCart(String id) =>
      setState(() => _cart.removeWhere((i) => i.product.id == id));

  void _clearCart() => setState(() => _cart.clear());

  double get _subtotal =>
      _cart.fold(0.0, (s, i) => s + i.product.price * i.quantity);
  double get _tax   => _subtotal * 0.18;
  double get _total => _subtotal + _tax;
  int get _itemCount => _cart.fold(0, (s, i) => s + i.quantity);

  // ── Sale processing ────────────────────────────────────────────────────────
  void _showPaymentDialog() {
    if (_cart.isEmpty) { _toast('Add items to cart first', isError: true); return; }
    showDialog(
      context: context,
      builder: (_) => PaymentMethodDialog(
        total: _total,
        onPaymentMethodSelected: (method) {
          Navigator.of(context).pop();
          _processSale(method);
        },
      ),
    );
  }

  void _processSale(String paymentMethod) {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    context.read<SalesBloc>().add(SaleCreateRequested({
      'items': _cart.map((i) => {
        'product_id': i.product.id,
        'quantity':   i.quantity,
        'price':      i.product.price,
      }).toList(),
      'subtotal':       _subtotal,
      'tax':            _tax,
      'total':          _total,
      'payment_method': paymentMethod,
      'cashier_id':     auth.user.id,
    }));
  }

  // ── Toast ──────────────────────────────────────────────────────────────────
  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor: isError ? _T.danger : _T.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: Colors.white, size: 16,
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(msg,
              style: _T.ts(13, weight: FontWeight.w500, color: Colors.white))),
        ]),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Open cart bottom sheet ─────────────────────────────────────────────────
  void _openCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CartSheet(
        cart:       _cart,
        subtotal:   _subtotal,
        tax:        _tax,
        total:      _total,
        onUpdateQty:   _updateQty,
        onRemove:      _removeFromCart,
        onClear:       _clearCart,
        onCheckout:    _showPaymentDialog,
      ),
    );
  }

  // ── Open add product popup ─────────────────────────────────────────────────
  void _openAddPopup() {
    final state = context.read<ProductsBloc>().state;
    if (state is! ProductsLoaded) {
      _toast('Products still loading…', isError: true);
      return;
    }
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _AddProductDialog(
        products:   state.products,
        cartIds:    _cart.map((i) => i.product.id).toSet(),
        onAdd:      _addToCart,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_showScanner) {
      return BarcodeScannerWidget(
        onBarcodeDetected: (barcode) {
          setState(() => _showScanner = false);
          final s = context.read<ProductsBloc>().state;
          if (s is ProductsLoaded) {
            try {
              _addToCart(s.products.firstWhere((p) => p.barcode == barcode));
            } catch (_) {
              _toast('Barcode not found', isError: true);
            }
          }
        },
        onClose: () => setState(() => _showScanner = false),
      );
    }

    return BlocListener<SalesBloc, SalesState>(
      listener: (ctx, state) {
        if (state is SaleCreated) {
          showDialog(
            context: ctx,
            builder: (_) => ReceiptDialog(
              sale: state.sale,
              onClose: () { Navigator.of(ctx).pop(); _clearCart(); },
            ),
          );
        } else if (state is SalesError) {
          _toast(state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: _T.bg,
        body: SafeArea(
          child: Column(children: [
            _TopBar(
              onHistoryTap: () => context.push(RouteNames.sales),
              onScanTap:    () => setState(() => _showScanner = true),
              onAddTap:     _openAddPopup,
            ),
            _SearchRow(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
            Expanded(child: _ProductsBody(
              searchQuery: _searchQuery,
              onAddToCart: _addToCart,
              cart:        _cart,
            )),
          ]),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _CartFAB(
          itemCount:  _itemCount,
          total:      _total,
          badgeAnim:  _cartBadgeAnim,
          onTap:      _openCart,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TOP BAR
// ════════════════════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onHistoryTap,
    required this.onScanTap,
    required this.onAddTap,
  });
  final VoidCallback onHistoryTap, onScanTap, onAddTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: _T.primary,
        boxShadow: [
          BoxShadow(
            color: _T.primary.withOpacity(0.3),
            blurRadius: 10, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        // Logo + title
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _T.accent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.point_of_sale_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Point of Sale',
              style: _T.ts(15, weight: FontWeight.w700, color: Colors.white)),
          Text('Tap product to add to cart',
              style: _T.ts(11, color: Colors.white60)),
        ]),
        const Spacer(),
        // Actions
        _TopAction(icon: Icons.history_rounded,    onTap: onHistoryTap),
        const SizedBox(width: 8),
        _TopAction(icon: Icons.qr_code_scanner_rounded, onTap: onScanTap),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onAddTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _T.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text('Add', style: _T.ts(12, weight: FontWeight.w700,
                  color: Colors.white)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _TopAction extends StatelessWidget {
  const _TopAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SEARCH ROW
// ════════════════════════════════════════════════════════════════════════════
class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String>  onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: _T.ts(14, color: _T.ink),
        decoration: InputDecoration(
          hintText: 'Search products by name or barcode…',
          hintStyle: _T.ts(13, color: _T.inkMid),
          prefixIcon: const Icon(Icons.search_rounded, color: _T.inkMid, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () { controller.clear(); onChanged(''); },
                  child: const Icon(Icons.close_rounded,
                      color: _T.inkMid, size: 18),
                )
              : null,
          filled: true,
          fillColor: _T.bg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _T.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _T.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _T.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PRODUCTS BODY
// ════════════════════════════════════════════════════════════════════════════
class _ProductsBody extends StatelessWidget {
  const _ProductsBody({
    required this.searchQuery,
    required this.onAddToCart,
    required this.cart,
  });
  final String searchQuery;
  final void Function(ProductEntity) onAddToCart;
  final List<CartItem> cart;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, state) {
        if (state is ProductsLoading) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(color: _T.primary, strokeWidth: 2),
              const SizedBox(height: 12),
              Text('Loading products…',
                  style: _T.ts(13, color: _T.inkMid)),
            ]),
          );
        }
        if (state is ProductsError) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _T.dangerSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded,
                    color: _T.danger, size: 28),
              ),
              const SizedBox(height: 12),
              Text('Failed to load products',
                  style: _T.ts(14, weight: FontWeight.w600, color: _T.ink)),
              const SizedBox(height: 4),
              Text('Check your connection and try again',
                  style: _T.ts(12, color: _T.inkMid)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context
                    .read<ProductsBloc>()
                    .add(const ProductsFetchRequested()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _T.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Retry',
                      style: _T.ts(13,
                          weight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ]),
          );
        }
        if (state is ProductsLoaded) {
          final products = state.products.where((p) {
            if (searchQuery.isEmpty) return true;
            final nameMatch = p.name.toLowerCase().contains(searchQuery);
            final barcodeMatch = p.barcode?.contains(searchQuery) ?? false;
            return nameMatch || barcodeMatch;
          }).toList();

          if (products.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.search_off_rounded,
                    color: _T.inkLight, size: 48),
                const SizedBox(height: 8),
                Text('No products found',
                    style: _T.ts(14, weight: FontWeight.w600,
                        color: _T.inkMid)),
              ]),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemCount: products.length,
            itemBuilder: (_, i) {
              final p = products[i];
              final cartItem =
                  cart.where((c) => c.product.id == p.id).firstOrNull;
              return _ProductCard(
                product:    p,
                cartQty:    cartItem?.quantity ?? 0,
                onTap:      () => onAddToCart(p),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PRODUCT CARD
// ════════════════════════════════════════════════════════════════════════════
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.cartQty,
    required this.onTap,
  });
  final ProductEntity product;
  final int cartQty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stock == 0;
    return GestureDetector(
      onTap: outOfStock ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cartQty > 0 ? _T.accent : _T.border,
            width: cartQty > 0 ? 2 : 1,
          ),
          boxShadow: _T.cardShadow,
        ),
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image / icon
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: outOfStock
                          ? _T.bg
                          : _T.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _ProductIcon(outOfStock: outOfStock),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  style: _T.ts(13,
                      weight: FontWeight.w600,
                      color: outOfStock ? _T.inkMid : _T.ink),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CurrencyFormatter.format(product.price),
                      style: _T.ts(13,
                          weight: FontWeight.w700, color: _T.primary),
                    ),
                    _StockBadge(stock: product.stock),
                  ],
                ),
              ],
            ),
          ),

          // In-cart badge
          if (cartQty > 0)
            Positioned(
              top: 8, right: 8,
              child: Container(
                width: 22, height: 22,
                decoration: const BoxDecoration(
                  color: _T.accent, shape: BoxShape.circle),
                child: Center(
                  child: Text('$cartQty',
                      style: _T.ts(11,
                          weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),

          // Out-of-stock overlay
          if (outOfStock)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _T.danger,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Out of Stock',
                        style: _T.ts(10,
                            weight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class _ProductIcon extends StatelessWidget {
  const _ProductIcon({required this.outOfStock});
  final bool outOfStock;
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.inventory_2_outlined,
        color: outOfStock ? _T.inkLight : _T.primary.withOpacity(0.3),
        size: 36);
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock});
  final int stock;
  @override
  Widget build(BuildContext context) {
    final low = stock > 0 && stock <= 5;
    final out = stock == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: out
            ? _T.dangerSoft
            : low
                ? _T.warnSoft
                : _T.accentSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        out ? 'Out' : '$stock left',
        style: _T.ts(10,
            weight: FontWeight.w600,
            color: out ? _T.danger : low ? _T.warn : _T.accent),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CART FAB
// ════════════════════════════════════════════════════════════════════════════
class _CartFAB extends StatelessWidget {
  const _CartFAB({
    required this.itemCount,
    required this.total,
    required this.badgeAnim,
    required this.onTap,
  });
  final int itemCount;
  final double total;
  final Animation<double> badgeAnim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_T.primary, _T.primaryLt],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _T.floatShadow,
        ),
        child: Row(children: [
          ScaleTransition(
            scale: badgeAnim,
            child: Stack(clipBehavior: Clip.none, children: [
              const Icon(Icons.shopping_cart_rounded,
                  color: Colors.white, size: 24),
              if (itemCount > 0)
                Positioned(
                  top: -6, right: -8,
                  child: Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(
                      color: _T.accent, shape: BoxShape.circle),
                    child: Center(
                      child: Text('$itemCount',
                          style: _T.ts(10,
                              weight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              itemCount == 0
                  ? 'Cart is empty'
                  : '$itemCount item${itemCount > 1 ? 's' : ''} in cart',
              style: _T.ts(13, weight: FontWeight.w600, color: Colors.white),
            ),
          ),
          if (itemCount > 0) ...[
            Text(
              CurrencyFormatter.format(total),
              style: _T.ts(14, weight: FontWeight.w800, color: _T.accent),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white60, size: 20),
          ],
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CART BOTTOM SHEET
// ════════════════════════════════════════════════════════════════════════════
class _CartSheet extends StatelessWidget {
  const _CartSheet({
    required this.cart,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.onUpdateQty,
    required this.onRemove,
    required this.onClear,
    required this.onCheckout,
  });
  final List<CartItem> cart;
  final double subtotal, tax, total;
  final void Function(String, int) onUpdateQty;
  final void Function(String) onRemove;
  final VoidCallback onClear, onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: _T.inkLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
          child: Row(children: [
            const Icon(Icons.shopping_cart_rounded,
                color: _T.primary, size: 22),
            const SizedBox(width: 8),
            Text('Cart',
                style: _T.ts(17, weight: FontWeight.w700, color: _T.ink)),
            if (cart.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _T.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${cart.length}',
                    style: _T.ts(11,
                        weight: FontWeight.w700, color: Colors.white)),
              ),
            ],
            const Spacer(),
            if (cart.isNotEmpty)
              TextButton.icon(
                onPressed: () { Navigator.of(context).pop(); onClear(); },
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: _T.danger),
                label: Text('Clear all',
                    style: _T.ts(12,
                        weight: FontWeight.w600, color: _T.danger)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                ),
              ),
          ]),
        ),

        const Divider(height: 1, color: _T.border),

        // Items
        if (cart.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.shopping_cart_outlined,
                  color: _T.inkLight, size: 48),
              const SizedBox(height: 10),
              Text('Your cart is empty',
                  style: _T.ts(14,
                      weight: FontWeight.w600, color: _T.inkMid)),
            ]),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              itemCount: cart.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: _T.border),
              itemBuilder: (_, i) => _CartRow(
                item:          cart[i],
                onIncrease: () =>
                    onUpdateQty(cart[i].product.id, cart[i].quantity + 1),
                onDecrease: () =>
                    onUpdateQty(cart[i].product.id, cart[i].quantity - 1),
                onRemove:   () => onRemove(cart[i].product.id),
              ),
            ),
          ),

        // Summary + checkout
        if (cart.isNotEmpty) ...[
          const Divider(height: 1, color: _T.border),
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 14, 20,
                14 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(children: [
              _SummRow('Subtotal', subtotal),
              const SizedBox(height: 6),
              _SummRow('VAT (18%)', tax),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: _T.border),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: _T.ts(16,
                          weight: FontWeight.w700, color: _T.ink)),
                  Text(CurrencyFormatter.format(total),
                      style: _T.ts(18,
                          weight: FontWeight.w800, color: _T.primary)),
                ],
              ),
              const SizedBox(height: 14),
              BlocBuilder<SalesBloc, SalesState>(
                builder: (_, state) => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: state is SalesLoading
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            onCheckout();
                          },
                    icon: state is SalesLoading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.payment_rounded, size: 20),
                    label: Text(
                      state is SalesLoading ? 'Processing…' : 'Proceed to Checkout',
                      style: _T.ts(15,
                          weight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });
  final CartItem item;
  final VoidCallback onIncrease, onDecrease, onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        // Thumb
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _T.primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory_2_outlined,
              color: _T.primary, size: 20),
        ),
        const SizedBox(width: 10),

        // Name + price
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.product.name,
                  style: _T.ts(13, weight: FontWeight.w600, color: _T.ink),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(CurrencyFormatter.format(item.product.price),
                  style: _T.ts(12, color: _T.inkMid)),
            ],
          ),
        ),

        // Qty controls
        Row(children: [
          _QtyBtn(icon: Icons.remove_rounded, onTap: onDecrease),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('${item.quantity}',
                style: _T.ts(14, weight: FontWeight.w700, color: _T.ink)),
          ),
          _QtyBtn(icon: Icons.add_rounded, onTap: onIncrease),
        ]),
        const SizedBox(width: 8),

        // Subtotal
        SizedBox(
          width: 64,
          child: Text(
            CurrencyFormatter.format(item.product.price * item.quantity),
            style: _T.ts(13, weight: FontWeight.w700, color: _T.primary),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 6),

        // Remove
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _T.dangerSoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.close_rounded,
                color: _T.danger, size: 14),
          ),
        ),
      ]),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: _T.bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _T.border),
        ),
        child: Icon(icon, size: 16, color: _T.primary),
      ),
    );
  }
}

class _SummRow extends StatelessWidget {
  const _SummRow(this.label, this.amount);
  final String label;
  final double amount;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: _T.ts(13, color: _T.inkMid)),
        Text(CurrencyFormatter.format(amount),
            style: _T.ts(13, weight: FontWeight.w600, color: _T.ink)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ADD PRODUCT DIALOG  (inline popup — no external file)
// ════════════════════════════════════════════════════════════════════════════
class _AddProductDialog extends StatefulWidget {
  const _AddProductDialog({
    required this.products,
    required this.cartIds,
    required this.onAdd,
  });
  final List<ProductEntity> products;
  final Set<String>         cartIds;
  final void Function(ProductEntity) onAdd;

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  final _searchCtrl   = TextEditingController();
  final _barcodeCtrl  = TextEditingController();
  String _q = '';
  ProductEntity? _selected;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  List<ProductEntity> get _filtered {
    if (_q.isEmpty) return widget.products;
    return widget.products.where((p) {
      final name    = p.name.toLowerCase().contains(_q);
      final barcode = p.barcode?.toLowerCase().contains(_q) ?? false;
      return name || barcode;
    }).toList();
  }

  void _submit() {
    if (_selected == null) return;
    widget.onAdd(_selected!);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _T.floatShadow,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
            decoration: const BoxDecoration(
              color: _T.primary,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(children: [
              const Icon(Icons.add_shopping_cart_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text('Add Product to Cart',
                  style: _T.ts(16,
                      weight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ]),
          ),

          // ── Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (v) => setState(() => _q = v.toLowerCase()),
              style: _T.ts(14, color: _T.ink),
              decoration: InputDecoration(
                hintText: 'Search product name or barcode…',
                hintStyle: _T.ts(13, color: _T.inkMid),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: _T.inkMid, size: 20),
                filled: true,
                fillColor: _T.bg,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _T.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _T.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _T.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // ── Product List
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.38,
            ),
            child: _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.search_off_rounded,
                          color: _T.inkLight, size: 36),
                      const SizedBox(height: 8),
                      Text('No products found',
                          style: _T.ts(13, color: _T.inkMid)),
                    ]),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: _T.border),
                    itemBuilder: (_, i) {
                      final p = _filtered[i];
                      final isSelected = _selected?.id == p.id;
                      final inCart  = widget.cartIds.contains(p.id);
                      final outOfStock = p.stock == 0;
                      return GestureDetector(
                        onTap: outOfStock
                            ? null
                            : () => setState(() => _selected = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _T.primary.withOpacity(0.07)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(children: [
                            // Radio
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? _T.primary
                                      : outOfStock
                                          ? _T.inkLight
                                          : _T.inkMid,
                                  width: isSelected ? 6 : 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Thumb
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: _T.primary.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2_outlined,
                                  size: 18, color: _T.primary),
                            ),
                            const SizedBox(width: 10),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      style: _T.ts(13,
                                          weight: FontWeight.w600,
                                          color: outOfStock
                                              ? _T.inkMid
                                              : _T.ink),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.format(p.price),
                                    style: _T.ts(12,
                                        weight: FontWeight.w700,
                                        color: _T.primary),
                                  ),
                                ],
                              ),
                            ),

                            // Badges
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _StockBadge(stock: p.stock),
                                if (inCart) ...[
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: _T.accentSoft,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: Text('In cart',
                                        style: _T.ts(9,
                                            weight: FontWeight.w600,
                                            color: _T.accent)),
                                  ),
                                ],
                              ],
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
          ),

          // ── Selected preview
          if (_selected != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _T.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _T.primary.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: _T.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selected!.name,
                    style: _T.ts(13,
                        weight: FontWeight.w600, color: _T.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(_selected!.price),
                  style: _T.ts(13,
                      weight: FontWeight.w700, color: _T.primary),
                ),
              ]),
            ),

          // ── Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: _T.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Cancel',
                      style: _T.ts(14,
                          weight: FontWeight.w600, color: _T.inkMid)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _selected == null ? null : _submit,
                  icon: const Icon(Icons.add_shopping_cart_rounded,
                      size: 18),
                  label: Text(
                    _selected == null
                        ? 'Select a product'
                        : 'Add to Cart',
                    style: _T.ts(14,
                        weight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    backgroundColor:
                        _selected == null ? _T.inkLight : _T.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}