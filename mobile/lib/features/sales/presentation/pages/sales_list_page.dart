import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../bloc/sales_bloc.dart';
import '../bloc/sales_event.dart';
import '../bloc/sales_state.dart';

class SalesListPage extends StatefulWidget {
  const SalesListPage({super.key});

  @override
  State<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends State<SalesListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<SalesBloc>().add(const SalesFetchRequested());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(RouteNames.createSale),
          ),
        ],
      ),
      body: BlocBuilder<SalesBloc, SalesState>(
        builder: (context, state) {
          if (state is SalesLoading) {
            return const AppLoadingIndicator();
          }
          if (state is SalesError) {
            return ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<SalesBloc>().add(const SalesFetchRequested()),
            );
          }
          if (state is SalesLoaded) {
            if (state.sales.isEmpty) {
              return EmptyView(
                message: 'No sales yet',
                icon: Icons.receipt_outlined,
                actionLabel: 'Create Sale',
                onAction: () => context.push(RouteNames.createSale),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => context
                  .read<SalesBloc>()
                  .add(const SalesFetchRequested()),
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: state.sales.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final sale = state.sales[index];
                  return Card(
                    child: ListTile(
                      onTap: () => context.push(
                        RouteNames.saleDetail(sale.id),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            sale.invoiceNo,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          StatusBadge(status: sale.status),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          if (sale.customerName != null)
                            Text(sale.customerName!),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormatter.formatDateTime(sale.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey500,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(sale.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.createSale),
        icon: const Icon(Icons.add),
        label: const Text('New Sale'),
      ),
    );
  }
}
