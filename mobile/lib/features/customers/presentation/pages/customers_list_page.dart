import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../bloc/customers_bloc.dart';

class CustomersListPage extends StatefulWidget {
  const CustomersListPage({super.key});

  @override
  State<CustomersListPage> createState() => _CustomersListPageState();
}

class _CustomersListPageState extends State<CustomersListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CustomersBloc>().add(const CustomersFetchRequested());
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
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCustomerForm(context),
          ),
        ],
      ),
      body: BlocConsumer<CustomersBloc, CustomersState>(
        listener: (context, state) {
          if (state is CustomerActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            context
                .read<CustomersBloc>()
                .add(const CustomersFetchRequested());
          } else if (state is CustomersError) {
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
                  label: 'Search customers',
                  prefixIcon: const Icon(Icons.search),
                  onChanged: (v) => context
                      .read<CustomersBloc>()
                      .add(CustomersFetchRequested(search: v)),
                ),
              ),
              Expanded(
                child: switch (state) {
                  CustomersLoading() => const AppLoadingIndicator(),
                  CustomersError(message: final msg) => ErrorView(
                      message: msg,
                      onRetry: () => context
                          .read<CustomersBloc>()
                          .add(const CustomersFetchRequested()),
                    ),
                  CustomersLoaded(customers: final customers)
                      when customers.isEmpty =>
                    EmptyView(
                      message: 'No customers yet',
                      icon: Icons.people_outlined,
                      actionLabel: 'Add Customer',
                      onAction: () => _showCustomerForm(context),
                    ),
                  CustomersLoaded(customers: final customers) =>
                    RefreshIndicator(
                      onRefresh: () async => context
                          .read<CustomersBloc>()
                          .add(const CustomersFetchRequested()),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: customers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final c = customers[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withAlpha(25),
                                child: Text(
                                  c.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              title: Text(c.name),
                              subtitle:
                                  Text(c.phone ?? c.email ?? ''),
                              onLongPress: () => _showDeleteConfirm(
                                  context, c.id, c.name),
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

  void _showCustomerForm(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
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
              Text('Add Customer',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              AppTextField(
                controller: nameCtrl,
                label: 'Full Name',
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: phoneCtrl,
                label: 'Phone',
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: emailCtrl,
                label: 'Email (Optional)',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Save Customer',
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    context.read<CustomersBloc>().add(
                          CustomerCreateRequested({
                            'name': nameCtrl.text,
                            'phone': phoneCtrl.text,
                            if (emailCtrl.text.isNotEmpty)
                              'email': emailCtrl.text,
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
        title: const Text('Delete Customer'),
        content: Text('Delete "$name"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ctx
                  .read<CustomersBloc>()
                  .add(CustomerDeleteRequested(id));
              Navigator.pop(ctx);
            },
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
