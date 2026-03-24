import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../bloc/sales_bloc.dart';
import '../bloc/sales_event.dart';
import '../bloc/sales_state.dart';

class SaleDetailPage extends StatefulWidget {
  final String saleId;
  const SaleDetailPage({super.key, required this.saleId});

  @override
  State<SaleDetailPage> createState() => _SaleDetailPageState();
}

class _SaleDetailPageState extends State<SaleDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<SalesBloc>().add(SaleDetailRequested(widget.saleId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
      ),
      body: BlocConsumer<SalesBloc, SalesState>(
        listener: (context, state) {
          if (state is SalesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SalesLoading) return const AppLoadingIndicator();
          if (state is SalesError) {
            return ErrorView(
              message: state.message,
              onRetry: () => context
                  .read<SalesBloc>()
                  .add(SaleDetailRequested(widget.saleId)),
            );
          }
          if (state is SaleDetailLoaded) {
            final s = state.sale;
            final vatLabel =
                s.taxType.isEmpty ? 'Tax' : 'VAT (${s.taxType})';
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                s.invoiceNo,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              StatusBadge(status: s.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormatter.formatDateTime(s.createdAt),
                            style: const TextStyle(color: AppColors.grey500),
                          ),
                          if (s.customerName != null) ...[
                            const SizedBox(height: 8),
                            Text('Customer: ${s.customerName}'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Items',
                              style: Theme.of(context).textTheme.titleMedium),
                          const Divider(),
                          ...s.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(child: Text(item.productName)),
                                  Text('${item.quantity}x'),
                                  const SizedBox(width: 12),
                                  Text(CurrencyFormatter.format(item.subtotal)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _TotalRow(
                              label: 'Subtotal',
                              value: CurrencyFormatter.format(s.subtotal)),
                          _TotalRow(
                            label: vatLabel,
                            value: CurrencyFormatter.format(s.totalVat)),
                          if (s.discount > 0)
                            _TotalRow(
                                label: 'Discount',
                                value:
                                    '-${CurrencyFormatter.format(s.discount)}'),
                          const Divider(),
                          _TotalRow(
                            label: 'Total',
                            value: CurrencyFormatter.format(s.total),
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment Method'),
                          Text(
                            s.paymentMethod,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
