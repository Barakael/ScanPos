import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/shop_bloc.dart';
import '../bloc/shop_event.dart';
import '../bloc/shop_state.dart';
import '../../domain/entities/shop_entity.dart';

class ShopsPage extends StatefulWidget {
  const ShopsPage({super.key});

  @override
  State<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends State<ShopsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    context.read<ShopBloc>().add(const ShopRequested());
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          'Shop Management',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => _showAddShopDialog(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Shop',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<ShopBloc, ShopState>(
        listener: (context, state) {
          final msg = state is ShopCreated
              ? 'Shop added successfully'
              : state is ShopUpdated
                  ? 'Shop updated successfully'
                  : state is ShopDeleted
                      ? 'Shop deleted successfully'
                      : null;
          if (msg != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(msg),
                  ],
                ),
                backgroundColor: const Color(0xFF059669),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            );
            context.read<ShopBloc>().add(const ShopRequested());
            _animController.reset();
            _animController.forward();
          }
        },
        builder: (context, state) {
          if (state is ShopLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3B82F6),
                strokeWidth: 2.5,
              ),
            );
          }

          if (state is ShopError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline_rounded,
                        size: 40, color: Color(0xFFDC2626)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () =>
                        context.read<ShopBloc>().add(const ShopRequested()),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D1B2A),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is ShopLoaded) {
            final shops = state.shops;
            final filteredShops = shops.where((s) {
              return _searchQuery.isEmpty ||
                  s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  s.address.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();

            if (!_animController.isAnimating && !_animController.isCompleted) {
              _animController.forward();
            }

            return FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stats Row ─────────────────────────────────
                    Row(
                      children: [
                        _StatTile(
                          label: 'Total',
                          value: shops.length.toString(),
                          color: const Color(0xFF3B82F6),
                          icon: Icons.store_rounded,
                        ),
                        const SizedBox(width: 10),
                        _StatTile(
                          label: 'Active',
                          value: shops
                              .where((s) => s.status == 'active')
                              .length
                              .toString(),
                          color: const Color(0xFF059669),
                          icon: Icons.check_circle_outline_rounded,
                        ),
                        const SizedBox(width: 10),
                        _StatTile(
                          label: 'Inactive',
                          value: shops
                              .where((s) => s.status == 'inactive')
                              .length
                              .toString(),
                          color: const Color(0xFFF59E0B),
                          icon: Icons.pause_circle_outline_rounded,
                        ),
                        const SizedBox(width: 10),
                        _StatTile(
                          label: 'Pending',
                          value: shops
                              .where((s) => s.status == 'pending')
                              .length
                              .toString(),
                          color: const Color(0xFF64748B),
                          icon: Icons.hourglass_empty_rounded,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ── Table Card ────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Table toolbar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                            child: Row(
                              children: [
                                const Text(
                                  'All Shops',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0D1B2A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${shops.length}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Search
                                SizedBox(
                                  width: 200,
                                  height: 36,
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (v) =>
                                        setState(() => _searchQuery = v),
                                    style: const TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: 'Search shops...',
                                      hintStyle: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF94A3B8)),
                                      prefixIcon: const Icon(Icons.search,
                                          size: 16, color: Color(0xFF94A3B8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 0, horizontal: 12),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE2E8F0)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE2E8F0)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF3B82F6)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 1, color: Color(0xFFF1F5F9)),

                          // Table
                          if (filteredShops.isEmpty)
                            _EmptyState(
                              icon: Icons.store_outlined,
                              message: _searchQuery.isEmpty
                                  ? 'No shops found'
                                  : 'No results for "$_searchQuery"',
                            )
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowHeight: 42,
                                dataRowMinHeight: 56,
                                dataRowMaxHeight: 64,
                                headingRowColor: MaterialStateProperty.all(
                                    const Color(0xFFF8FAFC)),
                                dividerThickness: 1,
                                columnSpacing: 20,
                                horizontalMargin: 16,
                                columns: const [
                                  DataColumn(
                                      label: _ColHeader(label: 'Shop Name')),
                                  DataColumn(
                                      label: _ColHeader(label: 'Address')),
                                  DataColumn(label: _ColHeader(label: 'Phone')),
                                  DataColumn(label: _ColHeader(label: 'Email')),
                                  DataColumn(label: _ColHeader(label: 'Manager')),
                                  DataColumn(
                                      label: _ColHeader(label: 'Status')),
                                  DataColumn(
                                      label: _ColHeader(label: 'Actions')),
                                ],
                                rows: filteredShops.map((shop) {
                                  return DataRow(cells: [
                                    // Name
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3B82F6)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.store_rounded,
                                              size: 15,
                                              color: Color(0xFF3B82F6),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                maxWidth: 130),
                                            child: Text(
                                              shop.name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF0D1B2A),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Address
                                    DataCell(
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                            maxWidth: 150),
                                        child: Text(
                                          shop.address,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    // Phone
                                    DataCell(
                                      Text(
                                        shop.phone,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                    // Email
                                    DataCell(
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                            maxWidth: 160),
                                        child: Text(
                                          shop.email,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF334155),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    // Manager
                                    DataCell(
                                      Text(
                                        shop.manager ?? '—',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: shop.manager != null
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                    ),
                                    // Status
                                    DataCell(
                                      _StatusChip(status: shop.status),
                                    ),
                                    // Actions
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _ActionButton(
                                            icon: Icons.visibility_outlined,
                                            color: const Color(0xFF3B82F6),
                                            tooltip: 'View',
                                            onTap: () =>
                                                _showShopDetails(context, shop),
                                          ),
                                          const SizedBox(width: 4),
                                          _ActionButton(
                                            icon: Icons.edit_outlined,
                                            color: const Color(0xFF059669),
                                            tooltip: 'Edit',
                                            onTap: () =>
                                                _showEditShopDialog(context, shop),
                                          ),
                                          const SizedBox(width: 4),
                                          _ActionButton(
                                            icon: Icons.delete_outline_rounded,
                                            color: const Color(0xFFDC2626),
                                            tooltip: 'Delete',
                                            onTap: () =>
                                                _showDeleteConfirm(context, shop),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]);
                                }).toList(),
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
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showAddShopDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ShopFormDialog(
        onSave: (name, address, phone, email) {
          context.read<ShopBloc>().add(ShopCreateRequested(
              name: name, address: address, phone: phone, email: email));
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEditShopDialog(BuildContext context, ShopEntity shop) {
    showDialog(
      context: context,
      builder: (_) => _ShopFormDialog(
        shop: shop,
        onSave: (name, address, phone, email) {
          context.read<ShopBloc>().add(ShopUpdateRequested(
              id: shop.id, name: name, address: address, phone: phone, email: email));
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showShopDetails(BuildContext context, ShopEntity shop) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
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
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.store_rounded,
                        color: Color(0xFF3B82F6), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      shop.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1B2A),
                      ),
                    ),
                  ),
                  _StatusChip(status: shop.status),
                ],
              ),
              const SizedBox(height: 20),
              _DetailItem(Icons.location_on_outlined, 'Address', shop.address),
              _DetailItem(Icons.phone_outlined, 'Phone', shop.phone),
              _DetailItem(Icons.email_outlined, 'Email', shop.email),
              if (shop.manager != null)
                _DetailItem(Icons.person_outlined, 'Manager', shop.manager!),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, ShopEntity shop) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Shop',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "${shop.name}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ShopBloc>().add(ShopDeleteRequested(shop.id));
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting Widgets ────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String label;
  const _ColHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.6,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = const Color(0xFF059669);
        break;
      case 'inactive':
        color = const Color(0xFFF59E0B);
        break;
      default:
        color = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
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
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0D1B2A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopFormDialog extends StatefulWidget {
  final ShopEntity? shop;
  final Function(String name, String address, String phone, String email)
      onSave;

  const _ShopFormDialog({this.shop, required this.onSave});

  @override
  State<_ShopFormDialog> createState() => _ShopFormDialogState();
}

class _ShopFormDialogState extends State<_ShopFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.shop != null) {
      _nameCtrl.text = widget.shop!.name;
      _addressCtrl.text = widget.shop!.address;
      _phoneCtrl.text = widget.shop!.phone;
      _emailCtrl.text = widget.shop!.email;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.shop != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit_rounded : Icons.add_business_rounded,
                          color: const Color(0xFF3B82F6),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEdit ? 'Edit Shop' : 'Add New Shop',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D1B2A),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF94A3B8), size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _FormField(
                      controller: _nameCtrl,
                      label: 'Shop Name',
                      icon: Icons.store_outlined,
                      validator: (v) => (v?.isEmpty ?? true)
                          ? 'Shop name is required'
                          : null),
                  const SizedBox(height: 14),
                  _FormField(
                      controller: _addressCtrl,
                      label: 'Address',
                      icon: Icons.location_on_outlined,
                      validator: (v) =>
                          (v?.isEmpty ?? true) ? 'Address is required' : null),
                  const SizedBox(height: 14),
                  _FormField(
                      controller: _phoneCtrl,
                      label: 'Phone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          (v?.isEmpty ?? true) ? 'Phone is required' : null),
                  const SizedBox(height: 14),
                  _FormField(
                      controller: _emailCtrl,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Email is required';
                        if (!v!.contains('@')) return 'Enter a valid email';
                        return null;
                      }),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            widget.onSave(_nameCtrl.text, _addressCtrl.text,
                                _phoneCtrl.text, _emailCtrl.text);
                          }
                        },
                        icon: Icon(
                            isEdit ? Icons.save_rounded : Icons.add_rounded,
                            size: 16),
                        label: Text(isEdit ? 'Save Changes' : 'Add Shop'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0D1B2A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B2A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, size: 17, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
      ),
    );
  }
}