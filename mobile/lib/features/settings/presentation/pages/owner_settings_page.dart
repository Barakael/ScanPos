import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/owner_settings_bloc.dart';
import '../bloc/owner_settings_event.dart';
import '../bloc/owner_settings_state.dart';
import '../../../shops/domain/entities/shop_entity.dart';

class OwnerSettingsPage extends StatefulWidget {
  const OwnerSettingsPage({super.key});

  @override
  State<OwnerSettingsPage> createState() => _OwnerSettingsPageState();
}

class _OwnerSettingsPageState extends State<OwnerSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Design tokens
  static const Color _bg = Color(0xFFF5F6FA);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _primary = Color(0xFF1E3A5F);
  static const Color _accent = Color(0xFF00C896);
  static const Color _danger = Color(0xFFFF4D4D);
  static const Color _warn = Color(0xFFFFA726);
  static const Color _ink = Color(0xFF1A2332);
  static const Color _inkMid = Color(0xFF64748B);
  static const Color _inkLight = Color(0xFFCBD5E1);
  static const Color _border = Color(0xFFE8EDF5);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) return const SizedBox.shrink();

        final user = state.user;

        if (user.roleName.toLowerCase() != 'owner') {
          return Scaffold(
            backgroundColor: _bg,
            appBar: AppBar(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text('Settings'),
            ),
            body: const Center(
              child: Text(
                'Owner settings not available for your role',
                style: TextStyle(color: _inkMid),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Owner Settings',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: -0.3,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: _accent,
              labelColor: _accent,
              unselectedLabelColor: _inkLight,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.store_rounded, size: 20),
                  text: 'Shop Info',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.account_tree_rounded, size: 20),
                  text: 'Branches',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.credit_card_rounded, size: 20),
                  text: 'Subscription',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              _ShopInfoTab(),
              _BranchesTab(),
              _SubscriptionTab(),
            ],
          ),
        );
      },
    );
  }
}

// ================== SHOP INFO TAB ==================

class _ShopInfoTab extends StatefulWidget {
  const _ShopInfoTab();

  @override
  State<_ShopInfoTab> createState() => _ShopInfoTabState();
}

class _ShopInfoTabState extends State<_ShopInfoTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _currencyController = TextEditingController(text: 'TZS');
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Load shop data when tab is initialized
    context.read<OwnerSettingsBloc>().add(LoadShopData());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() => _hasChanges = true);
  }

  Future<void> _saveShopInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      context.read<OwnerSettingsBloc>().add(UpdateShopInfo(
        name: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        currency: _currencyController.text,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Failed to update shop information'),
              ],
            ),
            backgroundColor: Color(0xFFFF4D4D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _currencyController = TextEditingController(text: 'TZS');
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Load shop data when tab is initialized
    context.read<OwnerSettingsBloc>().add(LoadShopData());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() => _hasChanges = true);
  }

  Future<void> _saveShopInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      context.read<OwnerSettingsBloc>().add(UpdateShopInfo(
        name: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        currency: _currencyController.text,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Failed to update shop information'),
              ],
            ),
            backgroundColor: Color(0xFFFF4D4D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _currencyController = TextEditingController(text: 'TZS');

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    context.read<OwnerSettingsBloc>().add(LoadShopData());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  void _saveShopInfo() {
    if (!_formKey.currentState!.validate()) return;

    context.read<OwnerSettingsBloc>().add(
          UpdateShopInfo(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            currency: _currencyController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OwnerSettingsBloc, OwnerSettingsState>(
      listener: (context, state) {
        if (state is ShopDataLoaded) {
          final shop = state.shop;
          _nameController.text = shop.name;
          _addressController.text = shop.address ?? '';
          _phoneController.text = shop.phone ?? '';
          _emailController.text = shop.email ?? '';
          _currencyController.text = 'TZS';
          setState(() => _hasChanges = false);
        }

        if (state is OwnerSettingsSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shop information updated successfully'),
              backgroundColor: Color(0xFF00C896),
            ),
          );
          setState(() => _hasChanges = false);
        }

        if (state is OwnerSettingsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFFF4D4D),
            ),
          );
        }
      },
      child: BlocBuilder<OwnerSettingsBloc, OwnerSettingsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state is ShopDataLoaded) ...[
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.account_tree_rounded,
                          iconColor: _accent,
                          title: '3',
                          subtitle: 'Branches',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.people_rounded,
                          iconColor: _warn,
                          title: '12',
                          subtitle: 'Staff',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Shop Details Form
                  Container(
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.02),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.store_rounded,
                                  color: _primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Shop Details',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Update your shop's public information",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _inkMid,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FormInput(
                                  controller: _nameController,
                                  label: 'Shop Name *',
                                  icon: Icons.store_rounded,
                                  validator: (value) =>
                                      value?.trim().isEmpty == true
                                          ? 'Shop name is required'
                                          : null,
                                  onChanged: _onFieldChanged,
                                ),
                                const SizedBox(height: 16),
                                _FormInput(
                                  controller: _addressController,
                                  label: 'Address',
                                  icon: Icons.location_on_rounded,
                                  onChanged: _onFieldChanged,
                                ),
                                const SizedBox(height: 16),
                                _FormInput(
                                  controller: _phoneController,
                                  label: 'Phone',
                                  icon: Icons.phone_rounded,
                                  keyboardType: TextInputType.phone,
                                  onChanged: _onFieldChanged,
                                ),
                                const SizedBox(height: 16),
                                _FormInput(
                                  controller: _emailController,
                                  label: 'Email',
                                  icon: Icons.email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) =>
                                      value?.trim().isEmpty == true
                                          ? 'Email is required'
                                          : null,
                                  onChanged: _onFieldChanged,
                                ),
                                const SizedBox(height: 16),
                                _FormInput(
                                  controller: _currencyController,
                                  label: 'Currency',
                                  icon: Icons.attach_money_rounded,
                                  enabled: false,
                                ),
                                const SizedBox(height: 24),

                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _hasChanges &&
                                            state is! OwnerSettingsLoading
                                        ? _saveShopInfo
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: state is OwnerSettingsLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Save Changes',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (state is OwnerSettingsError) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _danger),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, color: _danger, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load shop data',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: TextStyle(fontSize: 14, color: _inkMid),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context
                              .read<OwnerSettingsBloc>()
                              .add(LoadShopData()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ================== BRANCHES TAB ==================

class _BranchesTab extends StatelessWidget {
  const _BranchesTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Branches',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _OwnerSettingsPageState._ink,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddBranchDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Branch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _OwnerSettingsPageState._primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            3,
            (index) => _BranchCard(
              name: index == 0 ? 'Main Branch' : 'Branch ${index + 1}',
              address: '123 Main St, Dar es Salaam',
              phone: '+255 712 345 67${index}',
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBranchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _AddBranchDialog(),
    );
  }
}

// ================== SUBSCRIPTION TAB ==================

class _SubscriptionTab extends StatelessWidget {
  const _SubscriptionTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _SubscriptionPlanCard(
                  planName: 'Professional',
                  price: 29.99,
                  status: 'active',
                  nextDueDate: '2026-05-08',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NextPaymentCard(
                  dueDate: '2026-05-08',
                  daysLeft: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Payment History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _OwnerSettingsPageState._ink,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            3,
            (index) => _PaymentHistoryItem(
              date: '2026-0${4 - index}-08',
              amount: 29.99,
              status: 'success',
            ),
          ),
        ],
      ),
    );
  }
}

// ================== SHARED WIDGETS ==================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _OwnerSettingsPageState._white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _OwnerSettingsPageState._border),
        boxShadow: [
          BoxShadow(
            color: _OwnerSettingsPageState._primary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _OwnerSettingsPageState._ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: _OwnerSettingsPageState._inkMid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final VoidCallback? onChanged;
  final TextInputType? keyboardType;
  final bool enabled;

  const _FormInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (value) => onChanged?.call(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _OwnerSettingsPageState._inkMid, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _OwnerSettingsPageState._border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _OwnerSettingsPageState._border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: _OwnerSettingsPageState._primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: _OwnerSettingsPageState._danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: _OwnerSettingsPageState._danger, width: 1.5),
        ),
        labelStyle: TextStyle(color: _OwnerSettingsPageState._inkMid),
        floatingLabelStyle: TextStyle(color: _OwnerSettingsPageState._primary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: const TextStyle(fontSize: 14, color: _OwnerSettingsPageState._ink),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final String name;
  final String address;
  final String phone;

  const _BranchCard({
    required this.name,
    required this.address,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _OwnerSettingsPageState._white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _OwnerSettingsPageState._border),
        boxShadow: [
          BoxShadow(
            color: _OwnerSettingsPageState._primary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _OwnerSettingsPageState._accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.account_tree_rounded,
              color: _OwnerSettingsPageState._accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _OwnerSettingsPageState._ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 12,
                    color: _OwnerSettingsPageState._inkMid,
                  ),
                ),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 12,
                    color: _OwnerSettingsPageState._inkMid,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit_rounded, size: 18),
                color: _OwnerSettingsPageState._inkMid,
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.delete_rounded, size: 18),
                color: _OwnerSettingsPageState._danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubscriptionPlanCard extends StatelessWidget {
  final String planName;
  final double price;
  final String status;
  final String nextDueDate;

  const _SubscriptionPlanCard({
    required this.planName,
    required this.price,
    required this.status,
    required this.nextDueDate,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';

    return Container(
      decoration: BoxDecoration(
        color: _OwnerSettingsPageState._white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _OwnerSettingsPageState._border),
        boxShadow: [
          BoxShadow(
            color: _OwnerSettingsPageState._primary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Plan',
            style: TextStyle(fontSize: 12, color: _OwnerSettingsPageState._inkMid),
          ),
          const SizedBox(height: 4),
          Text(
            planName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _OwnerSettingsPageState._ink,
            ),
          ),
          Text(
            '\$${price.toStringAsFixed(2)} / month',
            style: TextStyle(fontSize: 14, color: _OwnerSettingsPageState._inkMid),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? _OwnerSettingsPageState._accent.withOpacity(0.1)
                  : _OwnerSettingsPageState._danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? _OwnerSettingsPageState._accent
                    : _OwnerSettingsPageState._danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextPaymentCard extends StatelessWidget {
  final String dueDate;
  final int daysLeft;

  const _NextPaymentCard({
    required this.dueDate,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = daysLeft < 0;
    final isDueSoon = daysLeft <= 7;

    Color statusColor = _OwnerSettingsPageState._inkMid;
    if (isOverdue) statusColor = _OwnerSettingsPageState._danger;
    else if (isDueSoon) statusColor = _OwnerSettingsPageState._warn;

    return Container(
      decoration: BoxDecoration(
        color: _OwnerSettingsPageState._white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _OwnerSettingsPageState._border),
        boxShadow: [
          BoxShadow(
            color: _OwnerSettingsPageState._primary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next Payment Due',
            style: TextStyle(
              fontSize: 12,
              color: _OwnerSettingsPageState._inkMid,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dueDate,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _OwnerSettingsPageState._ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOverdue
                ? '${daysLeft.abs()} days overdue'
                : daysLeft == 0
                    ? 'Due today'
                    : '$daysLeft days left',
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentHistoryItem extends StatelessWidget {
  final String date;
  final double amount;
  final String status;

  const _PaymentHistoryItem({
    required this.date,
    required this.amount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = status == 'success';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _OwnerSettingsPageState._white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _OwnerSettingsPageState._border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSuccess
                ? _OwnerSettingsPageState._accent.withOpacity(0.1)
                : _OwnerSettingsPageState._danger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
            color: isSuccess
                ? _OwnerSettingsPageState._accent
                : _OwnerSettingsPageState._danger,
            size: 20,
          ),
        ),
        title: Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _OwnerSettingsPageState._ink,
          ),
        ),
        subtitle: Text(
          date,
          style: const TextStyle(
            fontSize: 12,
            color: _OwnerSettingsPageState._inkMid,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSuccess
                ? _OwnerSettingsPageState._accent.withOpacity(0.1)
                : _OwnerSettingsPageState._danger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSuccess
                  ? _OwnerSettingsPageState._accent
                  : _OwnerSettingsPageState._danger,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddBranchDialog extends StatefulWidget {
  const _AddBranchDialog();

  @override
  State<_AddBranchDialog> createState() => _AddBranchDialogState();
}

class _AddBranchDialogState extends State<_AddBranchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _OwnerSettingsPageState._accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_tree_rounded,
                    color: _OwnerSettingsPageState._accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add New Branch',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _OwnerSettingsPageState._ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: _OwnerSettingsPageState._inkMid,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Branch Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.trim().isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Branch added successfully'),
                                  backgroundColor: Color(0xFF00C896),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _OwnerSettingsPageState._primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Add Branch'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
