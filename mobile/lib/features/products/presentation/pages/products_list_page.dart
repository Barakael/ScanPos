import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
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
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showProductForm(context),
          ),
        ],
      ),
      body: BlocConsumer<ProductsBloc, ProductsState>(
        listener: (context, state) {
          if (state is ProductActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<ProductsBloc>().add(const ProductsFetchRequested());
          } else if (state is ProductsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: AppTextField(
                  controller: _searchController,
                  label: 'Search products',
                  prefixIcon: const Icon(Icons.search),
                  onChanged: (v) => context
                      .read<ProductsBloc>()
                      .add(ProductsFetchRequested(search: v)),
                ),
              ),
              Expanded(
                child: switch (state) {
                  ProductsLoading() => const AppLoadingIndicator(),
                  ProductsError(message: final msg) => ErrorView(
                      message: msg,
                      onRetry: () => context
                          .read<ProductsBloc>()
                          .add(const ProductsFetchRequested()),
                    ),
                  ProductsLoaded(products: final products) when
                      products.isEmpty =>
                    EmptyView(
                      message: 'No products found',
                      icon: Icons.inventory_2_outlined,
                      actionLabel: 'Add Product',
                      onAction: () => _showProductForm(context),
                    ),
                  ProductsLoaded(products: final products) =>
                    RefreshIndicator(
                      onRefresh: () async => context
                          .read<ProductsBloc>()
                          .add(const ProductsFetchRequested()),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: products.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final p = products[i];
                          return Card(
                            child: ListTile(
                              title: Text(p.name),
                              subtitle: Text(
                                '${p.category ?? ''} · Stock: ${p.stock}',
                              ),
                              trailing: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(p.price),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  if (p.isLowStock)
                                    const Text(
                                      'Low stock',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                ],
                              ),
                              onLongPress: () =>
                                  _showDeleteConfirm(context, p.id, p.name),
                            ),
                          );
                        },
                      ),
                    ),
                  _ => const SizedBox.shrink(),
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showProductForm(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Product',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              AppTextField(
                controller: nameCtrl,
                label: 'Product Name',
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: priceCtrl,
                      label: 'Price (TZS)',
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: stockCtrl,
                      label: 'Stock',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Save Product',
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final ts = DateTime.now().millisecondsSinceEpoch;
                    context.read<ProductsBloc>().add(
                          ProductCreateRequested({
                            'name': nameCtrl.text.trim(),
                            'barcode': 'B$ts',
                            'price': double.parse(priceCtrl.text),
                            'stock': int.tryParse(stockCtrl.text) ?? 0,
                            'category': 'General',
                          }),
                        );
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext ctx, String id, String name) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ctx.read<ProductsBloc>().add(ProductDeleteRequested(id));
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
