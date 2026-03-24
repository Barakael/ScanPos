import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../products/domain/entities/product_entity.dart';

class ProductGridWidget extends StatelessWidget {
  final List<ProductEntity> products;
  final Function(ProductEntity) onProductTap;

  const ProductGridWidget({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.grey400),
            SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.grey400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _ProductCard(
            product: product,
            onTap: () => onProductTap(product),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // FIX: null-safe lowStockThreshold comparison
    final isLowStock = product.stock <= (product.lowStockThreshold ?? 10);
    final isOutOfStock = product.stock == 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOutOfStock
              ? AppColors.error
              : isLowStock
                  ? AppColors.warning
                  : Colors.transparent,
          width: isOutOfStock || isLowStock ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: isOutOfStock ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 32,
                    // FIX: use AppColors.grey400 instead of AppColors.grey
                    color: isOutOfStock ? AppColors.grey400 : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        // FIX: use AppColors.grey400 instead of AppColors.grey
                        color: isOutOfStock ? AppColors.grey400 : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // FIX: null-safe barcode — use ?? ''
                    Text(
                      product.barcode ?? '',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      CurrencyFormatter.format(product.price),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        // FIX: use AppColors.grey400 instead of AppColors.grey
                        color: isOutOfStock ? AppColors.grey400 : AppColors.primary,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? AppColors.error
                            : isLowStock
                                ? AppColors.warning
                                : AppColors.success.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isOutOfStock ? 'Out of Stock' : '${product.stock} left',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isOutOfStock || isLowStock
                              ? AppColors.white
                              : AppColors.success,
                        ),
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
}