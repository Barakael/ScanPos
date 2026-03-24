import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../bloc/sales_bloc.dart';
import '../bloc/sales_event.dart';
import '../bloc/sales_state.dart';

class CreateSalePage extends StatefulWidget {
  const CreateSalePage({super.key});

  @override
  State<CreateSalePage> createState() => _CreateSalePageState();
}

class _CreateSalePageState extends State<CreateSalePage> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();

  String _paymentMethod = 'CASH';
  String _taxType = 'STANDARD';
  String _vatType = 'INCLUSIVE';

  final List<_SaleItemEntry> _items = [];

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() => _items.add(_SaleItemEntry()));
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add at least one item'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final saleData = {
        'paymentMethod': _paymentMethod,
        'taxType': _taxType,
        'vatType': _vatType,
        if (_customerNameController.text.isNotEmpty)
          'customerName': _customerNameController.text,
        if (_customerPhoneController.text.isNotEmpty)
          'customerPhone': _customerPhoneController.text,
        'items': _items
            .map((item) => {
                  'productId': item.productId,
                  'quantity': int.tryParse(item.quantityController.text) ?? 1,
                  'unitPrice':
                      double.tryParse(item.priceController.text) ?? 0.0,
                })
            .toList(),
      };

      context.read<SalesBloc>().add(SaleCreateRequested(saleData));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: BlocListener<SalesBloc, SalesState>(
        listener: (context, state) {
          if (state is SaleCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sale created successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            context.go(RouteNames.sales);
          } else if (state is SalesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer info
                Text('Customer (Optional)',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _customerNameController,
                  label: 'Customer Name',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _customerPhoneController,
                  label: 'Customer Phone',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),

                // Tax & Payment
                Text('Tax & Payment',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildDropdownRow(
                  label: 'Tax Type',
                  value: _taxType,
                  items: const [
                    'STANDARD',
                    'ZERO_RATED',
                    'SPECIAL_RELIEF',
                    'EXEMPT'
                  ],
                  onChanged: (v) => setState(() => _taxType = v!),
                ),
                const SizedBox(height: 12),
                _buildDropdownRow(
                  label: 'VAT Type',
                  value: _vatType,
                  items: const ['INCLUSIVE', 'EXCLUSIVE'],
                  onChanged: (v) => setState(() => _vatType = v!),
                ),
                const SizedBox(height: 12),
                _buildDropdownRow(
                  label: 'Payment Method',
                  value: _paymentMethod,
                  items: const [
                    'CASH',
                    'E_MONEY',
                    'BANK_TRANSFER',
                    'CREDIT_CARD',
                    'CHEQUE'
                  ],
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                const SizedBox(height: 24),

                // Items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Items',
                        style: Theme.of(context).textTheme.titleMedium),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._items.asMap().entries.map(
                      (entry) => _SaleItemRow(
                        item: entry.value,
                        onRemove: () => _removeItem(entry.key),
                      ),
                    ),
                if (_items.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.grey200,
                          style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'No items added yet',
                        style: TextStyle(color: AppColors.grey400),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),
                BlocBuilder<SalesBloc, SalesState>(
                  builder: (context, state) => AppButton(
                    label: 'Create Sale',
                    isLoading: state is SalesLoading,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _SaleItemEntry {
  final productIdController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final priceController = TextEditingController();

  String get productId => productIdController.text;

  void dispose() {
    productIdController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}

class _SaleItemRow extends StatelessWidget {
  final _SaleItemEntry item;
  final VoidCallback onRemove;

  const _SaleItemRow({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            AppTextField(
              controller: item.productIdController,
              label: 'Product ID',
              validator: (v) => Validators.required(v, 'Product'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: item.quantityController,
                    label: 'Qty',
                    keyboardType: TextInputType.number,
                    validator: (v) => Validators.positiveNumber(v, 'Qty'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    controller: item.priceController,
                    label: 'Unit Price',
                    keyboardType: TextInputType.number,
                    validator: (v) => Validators.positiveNumber(v, 'Price'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: onRemove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
