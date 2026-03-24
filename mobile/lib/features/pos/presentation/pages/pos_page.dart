import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../products/presentation/bloc/products_bloc.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../sales/presentation/bloc/sales_bloc.dart';
import '../../../sales/presentation/bloc/sales_event.dart';
import '../../../sales/presentation/bloc/sales_state.dart';
import '../widgets/cart_item_widget.dart';
import '../widgets/product_grid_widget.dart';
import '../widgets/payment_method_dialog.dart';
import '../widgets/receipt_dialog.dart';
import '../widgets/barcode_scanner_widget.dart';
import '../../domain/models/cart_item.dart';

class POSPage extends StatefulWidget {
  const POSPage({super.key});

  @override
  State<POSPage> createState() => _POSPageState();
}

class _POSPageState extends State<POSPage> {
  final List<CartItem> _cart = [];
  final _searchController = TextEditingController();
  final _barcodeController = TextEditingController();
  String _searchQuery = '';
  bool _showScanner = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductsBloc>().add(const ProductsFetchRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  // FIX: accept ProductEntity (not the old Product type from cart_item.dart)
  void _addToCart(ProductEntity product) {
    setState(() {
      final existingIndex =
          _cart.indexWhere((item) => item.product.id == product.id);
      if (existingIndex != -1) {
        if (_cart[existingIndex].quantity < product.stock) {
          _cart[existingIndex] = CartItem(
            product: product,
            quantity: _cart[existingIndex].quantity + 1,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Insufficient stock'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } else {
        if (product.stock > 0) {
          _cart.add(CartItem(product: product, quantity: 1));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product out of stock'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    });
  }

  void _updateQuantity(String productId, int quantity) {
    setState(() {
      final index =
          _cart.indexWhere((item) => item.product.id == productId);
      if (index != -1) {
        if (quantity <= 0) {
          _cart.removeAt(index);
        } else if (quantity <= _cart[index].product.stock) {
          _cart[index] = CartItem(
            product: _cart[index].product,
            quantity: quantity,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Insufficient stock'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      _cart.removeWhere((item) => item.product.id == productId);
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  double get _subtotal =>
      _cart.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  double get _tax => _subtotal * 0.18;
  double get _total => _subtotal + _tax;

  void _handleBarcodeSubmit() {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;

    final productsState = context.read<ProductsBloc>().state;
    if (productsState is ProductsLoaded) {
      try {
        final product = productsState.products.firstWhere(
          // FIX: null-safe barcode comparison
          (p) => p.barcode == barcode,
        );
        _addToCart(product);
        _barcodeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added: ${product.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barcode not found'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onBarcodeScanned(String barcode) {
    setState(() => _showScanner = false);

    final productsState = context.read<ProductsBloc>().state;
    if (productsState is ProductsLoaded) {
      try {
        final product = productsState.products.firstWhere(
          (p) => p.barcode == barcode,
        );
        _addToCart(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added: ${product.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barcode not found'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showPaymentDialog() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => PaymentMethodDialog(
        total: _total,
        onPaymentMethodSelected: (method) {
          Navigator.of(context).pop();
          _processSale(method);
        },
      ),
    );
  }

  void _processSale(String paymentMethod) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final saleData = {
      'items': _cart
          .map((item) => {
                'product_id': item.product.id,
                'quantity': item.quantity,
                'price': item.product.price,
              })
          .toList(),
      'subtotal': _subtotal,
      'tax': _tax,
      'total': _total,
      'payment_method': paymentMethod,
      'cashier_id': authState.user.id,
    };

    context.read<SalesBloc>().add(SaleCreateRequested(saleData));
  }

  @override
  Widget build(BuildContext context) {
    if (_showScanner) {
      return BarcodeScannerWidget(
        onBarcodeDetected: _onBarcodeScanned,
        onClose: () => setState(() => _showScanner = false),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.white),
            onPressed: () => context.push(RouteNames.sales),
          ),
        ],
      ),
      body: BlocListener<SalesBloc, SalesState>(
        listener: (context, state) {
          if (state is SaleCreated) {
            showDialog(
              context: context,
              builder: (context) => ReceiptDialog(
                sale: state.sale,
                onClose: () {
                  Navigator.of(context).pop();
                  _clearCart();
                },
              ),
            );
          } else if (state is SalesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Barcode Input
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primary.withAlpha(20),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _barcodeController,
                      label: 'Scan or enter barcode',
                      prefixIcon: const Icon(Icons.qr_code_scanner),
                      onSubmitted: (_) => _handleBarcodeSubmit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: 'Add',
                    onPressed: _handleBarcodeSubmit,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () => setState(() => _showScanner = true),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppTextField(
                controller: _searchController,
                label: 'Search products',
                prefixIcon: const Icon(Icons.search),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
            ),

            // Main Content
            Expanded(
              child: Row(
                children: [
                  // Products Grid
                  Expanded(
                    flex: 2,
                    child: BlocBuilder<ProductsBloc, ProductsState>(
                      builder: (context, state) {
                        if (state is ProductsLoading) {
                          return const AppLoadingIndicator();
                        } else if (state is ProductsError) {
                          return Center(
                            child: Text(
                              'Error loading products',
                              style: TextStyle(color: AppColors.error),
                            ),
                          );
                        } else if (state is ProductsLoaded) {
                          final filteredProducts =
                              state.products.where((product) {
                            final nameMatch = product.name
                                .toLowerCase()
                                .contains(_searchQuery);
                            // FIX: null-safe barcode search
                            final barcodeMatch =
                                product.barcode?.contains(_searchQuery) ??
                                    false;
                            return nameMatch || barcodeMatch;
                          }).toList();

                          return ProductGridWidget(
                            products: filteredProducts,
                            onProductTap: _addToCart,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),

                  // Cart
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(10),
                        border: Border(
                            left: BorderSide(
                                color: Colors.grey.withAlpha(30))),
                      ),
                      child: Column(
                        children: [
                          // Cart Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(10),
                              border: Border(
                                  bottom: BorderSide(
                                      color: Colors.grey.withAlpha(30))),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Cart',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_cart.isNotEmpty)
                                  TextButton(
                                    onPressed: _clearCart,
                                    child: const Text('Clear'),
                                  ),
                              ],
                            ),
                          ),

                          // Cart Items
                          Expanded(
                            child: _cart.isEmpty
                                ? const Center(
                                    child: Text('No items in cart'))
                                : ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _cart.length,
                                    itemBuilder: (context, index) {
                                      final item = _cart[index];
                                      return CartItemWidget(
                                        item: item,
                                        onQuantityChanged: (quantity) =>
                                            _updateQuantity(
                                                item.product.id, quantity),
                                        onRemove: () => _removeFromCart(
                                            item.product.id),
                                      );
                                    },
                                  ),
                          ),

                          // Cart Summary
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              border: Border(
                                  top: BorderSide(
                                      color: Colors.grey.withAlpha(30))),
                            ),
                            child: Column(
                              children: [
                                _buildSummaryRow('Subtotal:', _subtotal),
                                _buildSummaryRow('Tax (18%):', _tax),
                                const Divider(),
                                _buildSummaryRow('Total:', _total,
                                    isTotal: true),
                                const SizedBox(height: 16),
                                BlocBuilder<SalesBloc, SalesState>(
                                  builder: (context, state) {
                                    return AppButton(
                                      label: 'Checkout',
                                      onPressed: _showPaymentDialog,
                                      isLoading: state is SalesLoading,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIX: this is a class method, not a local function — correctly placed at class level
  Widget _buildSummaryRow(String label, double amount,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}