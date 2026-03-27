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
// Note: Ensure these custom widgets exist or replace with standard ones
// import '../widgets/cart_sheet.dart'; 
// import '../widgets/add_product_dialog.dart';

class _T {
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

  static TextStyle ts(double size, {FontWeight weight = FontWeight.w400, Color color = ink}) =>
      TextStyle(fontSize: size, fontWeight: weight, color: color);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(color: const Color(0xFF1E3A5F).withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
      ];

  static List<BoxShadow> get floatShadow => [
        BoxShadow(color: const Color(0xFF1E3A5F).withOpacity(0.14), blurRadius: 24, offset: const Offset(0, 8)),
      ];
}

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

  late final AnimationController _cartBadgeCtrl;
  late final Animation<double>   _cartBadgeAnim;

  @override
  void initState() {
    super.initState();
    context.read<ProductsBloc>().add(const ProductsFetchRequested());
    _cartBadgeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
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

  // --- Logic Helpers ---
  double get _subtotal => _cart.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  double get _total => _subtotal; 
  int get _itemCount => _cart.fold(0, (sum, item) => sum + item.quantity);

  void _addToCart(ProductEntity product) {
    HapticFeedback.lightImpact();
    setState(() {
      final idx = _cart.indexWhere((i) => i.product.id == product.id);
      if (idx != -1) {
        if (_cart[idx].quantity < product.stock) {
          _cart[idx] = CartItem(product: product, quantity: _cart[idx].quantity + 1);
          _cartBadgeCtrl.forward(from: 0);
        } else {
          _toast('Max stock reached', isError: true);
        }
      } else {
        if (product.stock > 0) {
          _cart.add(CartItem(product: product, quantity: 1));
          _cartBadgeCtrl.forward(from: 0);
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
      }
    });
  }

  void _removeFromCart(String id) => setState(() => _cart.removeWhere((i) => i.product.id == id));
  void _clearCart() => setState(() => _cart.clear());

  void _processSale(String paymentMethod) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    context.read<SalesBloc>().add(SaleCreateRequested({
      'items': _cart.map((i) => {
        'product_id': i.product.id,
        'quantity':   i.quantity,
        'price':      i.product.price,
      }).toList(),
      'subtotal':       _subtotal,
      'total':          _total,
      'payment_method': paymentMethod,
      'cashier_id':     authState.user.id,
    }));
  }

  void _showPaymentDialog() {
    if (_cart.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => PaymentMethodDialog(
        total: _total,
        onPaymentMethodSelected: (method) {
          Navigator.pop(context);
          _processSale(method);
        },
      ),
    );
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? _T.danger : _T.accent),
    );
  }

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
            } catch (_) { _toast('Not found', isError: true); }
          }
        },
        onClose: () => setState(() => _showScanner = false),
      );
    }

    return BlocListener<SalesBloc, SalesState>(
      listener: (context, state) {
        if (state is SaleCreated) {
          _clearCart();
          showDialog(context: context, builder: (_) => ReceiptDialog(sale: state.sale));
        }
      },
      child: Scaffold(
        backgroundColor: _T.bg,
        body: SafeArea(
          child: Column(children: [
            _TopBar(
              onHistoryTap: () => context.push(RouteNames.sales),
              onScanTap: () => setState(() => _showScanner = true),
              onAddTap: () {}, // Implement logic to open add product dialog
            ),
            _SearchRow(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
            Expanded(
              child: _ProductsBody(
                searchQuery: _searchQuery,
                onAddToCart: _addToCart,
                cart: _cart,
              ),
            ),
          ]),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _itemCount > 0 ? _CartFAB(
          itemCount: _itemCount,
          total: _total,
          badgeAnim: _cartBadgeAnim,
          onTap: () {
            // Implement BottomSheet or navigation to Cart logic here
          },
        ) : null,
      ),
    );
  }
}

// --- Sub-Widgets ---

class _TopBar extends StatelessWidget {
  final VoidCallback onHistoryTap, onScanTap, onAddTap;
  const _TopBar({required this.onHistoryTap, required this.onScanTap, required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _T.primary,
      child: Row(children: [
        const Text('Point of Sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(icon: const Icon(Icons.history, color: Colors.white), onPressed: onHistoryTap),
        IconButton(icon: const Icon(Icons.qr_code_scanner, color: Colors.white), onPressed: onScanTap),
      ]),
    );
  }
}

class _SearchRow extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchRow({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _ProductsBody extends StatelessWidget {
  final String searchQuery;
  final Function(ProductEntity) onAddToCart;
  final List<CartItem> cart;
  const _ProductsBody({required this.searchQuery, required this.onAddToCart, required this.cart});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, state) {
        if (state is ProductsLoaded) {
          final products = state.products.where((p) => p.name.toLowerCase().contains(searchQuery)).toList();
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.8),
            itemCount: products.length,
            itemBuilder: (context, i) => _ProductCard(
              product: products[i],
              cartQty: cart.where((c) => c.product.id == products[i].id).fold(0, (s, item) => s + item.quantity),
              onTap: () => onAddToCart(products[i]),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductEntity product;
  final int cartQty;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.cartQty, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(child: Icon(Icons.inventory, size: 40, color: _T.primary.withOpacity(0.5))),
            Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(CurrencyFormatter.format(product.price)),
            if (cartQty > 0) CircleAvatar(radius: 10, child: Text('$cartQty', style: const TextStyle(fontSize: 10))),
          ],
        ),
      ),
    );
  }
}

class _CartFAB extends StatelessWidget {
  final int itemCount;
  final double total;
  final Animation<double> badgeAnim;
  final VoidCallback onTap;
  const _CartFAB({required this.itemCount, required this.total, required this.badgeAnim, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: _T.primary,
      label: Text('View Cart ($itemCount) - ${CurrencyFormatter.format(total)}'),
      icon: const Icon(Icons.shopping_cart),
    );
  }
}