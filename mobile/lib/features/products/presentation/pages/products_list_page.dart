import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../bloc/products_bloc.dart';

class ProductsListPage extends StatefulWidget {
  const ProductsListPage({super.key});

  @override
  State<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'all';

  static const _navy = Color(0xFF1E3A5F);
  static const _navyLight = Color(0xFF2D5282);
  static const _slate = Color(0xFF64748B);
  static const _slateLight = Color(0xFFE2E8F0);
  static const _bg = Color(0xFFF8FAFC);
  static const _success = Color(0xFF059669);
  static const _danger = Color(0xFFDC2626);
  static const _amber = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    context.read<ProductsBloc>().add(const ProductsFetchRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: BlocConsumer<ProductsBloc, ProductsState>(
        listener: _handleStateChanges,
        builder: (context, state) => Column(
          children: [
            _buildSearchAndFilter(),
            Expanded(child: _buildBody(context, state)),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: _navy,
      foregroundColor: Colors.white,
      title: BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) {
          final subtitle = state is ProductsLoaded
              ? '${state.products.length} products · ${state.products.fold<int>(0, (s, p) => s + (p.stock ?? 0))} units'
              : 'Loading inventory...';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inventory',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton.icon(
            onPressed: () => _showProductDialog(context, null),
            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
            label: const Text(
              'Add Product',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.18),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Search
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _slateLight),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14, color: _navy),
              decoration: const InputDecoration(
                hintText: 'Search name, barcode, category…',
                hintStyle: TextStyle(fontSize: 13, color: _slate),
                prefixIcon: Icon(Icons.search_rounded, color: _slate, size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                context.read<ProductsBloc>().add(ProductsFetchRequested(search: value));
              },
            ),
          ),
          const SizedBox(height: 10),
          // Filter Pills
          Row(
            children: [
              _filterChip('all', 'All Products', Icons.grid_view_rounded),
              const SizedBox(width: 8),
              _filterChip('low', 'Low Stock', Icons.warning_amber_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label, IconData icon) {
    final active = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 36,
          decoration: BoxDecoration(
            color: active ? _navy : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? _navy : _slateLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: active
                    ? Colors.white
                    : (value == 'low' ? _amber : _slate),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : _slate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProductsState state) {
    return switch (state) {
      ProductsLoading() => const Center(child: AppLoadingIndicator()),
      ProductsError(message: final msg) => ErrorView(
          message: msg,
          onRetry: () => context.read<ProductsBloc>().add(const ProductsFetchRequested()),
        ),
      ProductsLoaded(products: final products) when products.isEmpty => _buildEmptyState(),
      ProductsLoaded(products: final products) => _buildTable(context, products),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _navy.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 40, color: _navy),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isEmpty ? 'No products yet' : 'No results for "$_searchQuery"',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _navy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add your first product to get started',
              style: TextStyle(fontSize: 13, color: _slate),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Add New Product',
              onPressed: () => _showProductDialog(context, null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<dynamic> allProducts) {
    final products = _getFilteredProducts(allProducts);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _slateLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 32,
            ),
            child: DataTable(
              headingRowHeight: 44,
              dataRowMinHeight: 60,
              dataRowMaxHeight: 60,
              horizontalMargin: 20,
              columnSpacing: 20,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              dividerThickness: 1,
              columns: const [
                DataColumn(label: _TableHeader('Product')),
                DataColumn(label: _TableHeader('Barcode')),
                DataColumn(label: _TableHeader('Category')),
                DataColumn(label: _TableHeader('Price'), numeric: true),
                DataColumn(label: _TableHeader('Stock'), numeric: true),
                DataColumn(label: _TableHeader('Actions')),
              ],
              rows: products.map((product) => _buildRow(context, product)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, dynamic product) {
    final isLowStock = product.isLowStock ?? false;

    return DataRow(
      cells: [
        // Product Name
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _navy.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: _navy, size: 17),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Barcode
        DataCell(
          Text(
            product.barcode ?? '—',
            style: const TextStyle(
              fontSize: 12,
              color: _slate,
              fontFamily: 'monospace',
            ),
          ),
        ),
        // Category
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _navy.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              product.category ?? 'General',
              style: const TextStyle(
                fontSize: 11,
                color: _navyLight,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        // Price
        DataCell(
          Text(
            CurrencyFormatter.format(product.price),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _navy,
            ),
          ),
        ),
        // Stock
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isLowStock ? _danger : _success).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLowStock) ...[
                  const Icon(Icons.warning_amber_rounded, size: 12, color: _danger),
                  const SizedBox(width: 4),
                ],
                Text(
                  '${product.stock}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isLowStock ? _danger : _success,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Actions
        DataCell(
          Row(
            children: [
              _ActionButton(
                icon: Icons.edit_rounded,
                color: _navyLight,
                tooltip: 'Edit',
                onTap: () => _showProductDialog(context, product),
              ),
              const SizedBox(width: 4),
              _ActionButton(
                icon: Icons.delete_outline_rounded,
                color: _danger,
                tooltip: 'Delete',
                onTap: () => _showDeleteConfirm(context, product.id, product.name),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<dynamic> _getFilteredProducts(List<dynamic> products) {
    return products.where((product) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          product.name.toLowerCase().contains(q) ||
          (product.barcode?.contains(q) ?? false) ||
          (product.category?.toLowerCase().contains(q) ?? false);
      final matchesFilter = _filter == 'all' || (product.isLowStock ?? false);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _handleStateChanges(BuildContext context, ProductsState state) {
    if (state is ProductActionSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(state.message),
            ],
          ),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.read<ProductsBloc>().add(const ProductsFetchRequested());
    } else if (state is ProductsError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showProductDialog(BuildContext context, dynamic product) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    final priceCtrl = TextEditingController(text: product?.price?.toString() ?? '');
    final stockCtrl = TextEditingController(text: product?.stock?.toString() ?? '10');
    final categoryCtrl = TextEditingController(text: product?.category ?? 'General');
    final thresholdCtrl = TextEditingController(
        text: product?.lowStockThreshold?.toString() ?? '10');
    final formKey = GlobalKey<FormState>();
    final isEditing = product != null;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        // FIX: Use intrinsic sizing to avoid BoxConstraints non-normalized height
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                decoration: const BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_rounded : Icons.add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Product' : 'Add New Product',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
              // Form — scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FormRow(children: [
                          _FormField(
                            label: 'Product Name',
                            controller: nameCtrl,
                            hint: 'e.g. Coca Cola 500ml',
                            validator: (v) =>
                                (v?.trim().isEmpty ?? true) ? 'Required' : null,
                          ),
                          _FormField(
                            label: 'Barcode',
                            controller: barcodeCtrl,
                            hint: 'e.g. 5449000000996',
                            monospace: true,
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _FormRow(children: [
                          _FormField(
                            label: 'Category',
                            controller: categoryCtrl,
                            hint: 'e.g. Beverages',
                          ),
                          _FormField(
                            label: 'Price (TZS)',
                            controller: priceCtrl,
                            hint: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _FormRow(children: [
                          _FormField(
                            label: 'Stock Quantity',
                            controller: stockCtrl,
                            hint: '0',
                            keyboardType: TextInputType.number,
                          ),
                          _FormField(
                            label: 'Low Stock Alert At',
                            controller: thresholdCtrl,
                            hint: '10',
                            keyboardType: TextInputType.number,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                  border: Border(top: BorderSide(color: _slateLight)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _slate,
                        side: const BorderSide(color: _slateLight),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final data = {
                            'name': nameCtrl.text.trim(),
                            'barcode': barcodeCtrl.text.trim(),
                            'price': double.tryParse(priceCtrl.text) ?? 0.0,
                            'stock': int.tryParse(stockCtrl.text) ?? 0,
                            'category': categoryCtrl.text.trim(),
                            'lowStockThreshold':
                                int.tryParse(thresholdCtrl.text) ?? 10,
                          };
                          if (isEditing) {
                            context.read<ProductsBloc>().add(
                                  ProductUpdateRequested(product.id, data),
                                );
                          } else {
                            context.read<ProductsBloc>().add(
                                  ProductCreateRequested(data),
                                );
                          }
                          Navigator.pop(ctx);
                        }
                      },
                      icon: Icon(
                        isEditing ? Icons.save_rounded : Icons.add_rounded,
                        size: 16,
                      ),
                      label: Text(
                        isEditing ? 'Save Changes' : 'Add Product',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: _danger, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Delete Product',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: _slate, height: 1.5),
                  children: [
                    const TextSpan(text: 'Are you sure you want to delete '),
                    TextSpan(
                      text: '"$name"',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: _navy),
                    ),
                    const TextSpan(text: '? This action cannot be undone.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _slate,
                      side: const BorderSide(color: _slateLight),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<ProductsBloc>()
                          .add(ProductDeleteRequested(id));
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.delete_rounded, size: 16),
                    label: const Text('Delete',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.6,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  final List<Widget> children;
  const _FormRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .expand((w) => [Expanded(child: w), const SizedBox(width: 14)])
          .toList()
        ..removeLast(),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool monospace;
  final String? Function(String?)? validator;

  const _FormField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.monospace = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A5F),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF1E3A5F),
            fontFamily: monospace ? 'monospace' : null,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
      ],
    );
  }
}