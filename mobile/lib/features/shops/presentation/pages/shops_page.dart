import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ShopsPageState extends State<ShopsPage> with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String _selectedTab = 'All';
  bool _isSearchVisible = false;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const _void       = Color(0xFF09090F);
  static const _surface    = Color(0xFF111118);
  static const _panel      = Color(0xFF16161F);
  static const _card       = Color(0xFF1C1C28);
  static const _border     = Color(0x18FFFFFF);
  static const _borderStrong = Color(0x28FFFFFF);
  static const _ink        = Color(0xFFF0F0FF);
  static const _inkMid     = Color(0xFF8B8BA8);
  static const _inkDim     = Color(0xFF4A4A62);
  static const _gold       = Color(0xFFF5C842);
  static const _goldSoft   = Color(0x20F5C842);
  static const _teal       = Color(0xFF00D9A3);
  static const _tealSoft   = Color(0x1A00D9A3);
  static const _coral      = Color(0xFFFF5F6D);
  static const _coralSoft  = Color(0x1AFF5F6D);
  static const _indigo     = Color(0xFF7B68EE);
  static const _indigoSoft = Color(0x1F7B68EE);
  static const _amber      = Color(0xFFFF9F43);
  static const _amberSoft  = Color(0x1FFF9F43);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    
    // Start fetching data immediately
    context.read<ShopBloc>().add(const ShopRequested());
    
    // Start entrance animation after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ShopEntity> _filterShops(List<ShopEntity> shops) {
    List<ShopEntity> filtered = shops;
    if (_selectedTab != 'All') {
      filtered = filtered
          .where((s) => s.status.toLowerCase() == _selectedTab.toLowerCase())
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((s) =>
              s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.address.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return filtered;
  }

  void _showToast(String message, String type) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              type == 'success'
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: type == 'success' ? _teal : _coral,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddShopDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShopFormSheet(
        onSave: (name, address, phone, email) {
          context.read<ShopBloc>().add(ShopCreateRequested(
              name: name, address: address, phone: phone, email: email));
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEditShopDialog(ShopEntity shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShopFormSheet(
        shop: shop,
        onSave: (name, address, phone, email) {
          context.read<ShopBloc>().add(ShopUpdateRequested(
              id: shop.id, name: name, address: address, phone: phone, email: email));
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showShopDetails(ShopEntity shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShopDetailsSheet(shop: shop),
    );
  }

  void _showDeleteConfirm(ShopEntity shop) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Shop',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
        ),
        content: Text(
          'Are you sure you want to delete "${shop.name}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: _inkMid, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: _inkMid)),
          ),
          FilledButton(
            onPressed: () {
              context
                  .read<ShopBloc>()
                  .add(ShopDeleteRequested(shop.id));
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: _coral,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _void,
      ),
      child: Scaffold(
        backgroundColor: _void,
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
              _showToast(msg, 'success');
              context.read<ShopBloc>().add(const ShopRequested());
              _animController.reset();
              _animController.forward();
            }
          },
          builder: (context, state) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── App Bar ──────────────────────────────────────────────
                SliverAppBar(
                  backgroundColor: _surface,
                  foregroundColor: _ink,
                  elevation: 0,
                  pinned: true,
                  floating: false,
                  expandedHeight: 120,
                  surfaceTintColor: Colors.transparent,
                  systemOverlayStyle: SystemUiOverlayStyle.light,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    title: _isSearchVisible
                        ? _SearchBar(
                            controller: _searchController,
                            onChanged: (v) =>
                                setState(() => _searchQuery = v),
                            onClose: () => setState(() {
                              _isSearchVisible = false;
                              _searchQuery = '';
                              _searchController.clear();
                            }),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Shops',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Manage your store network',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _inkDim,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                    background: Container(
                      decoration: const BoxDecoration(
                        color: _surface,
                        border: Border(
                          bottom: BorderSide(color: _border),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    if (!_isSearchVisible) ...[
                      _AppBarIconButton(
                        icon: Icons.search_rounded,
                        onTap: () => setState(() => _isSearchVisible = true),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: _showAddShopDialog,
                          child: Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14),
                            decoration: BoxDecoration(
                              color: _gold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded,
                                    size: 16, color: _void),
                                SizedBox(width: 5),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _void,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // ── Tab Filter Bar ────────────────────────────────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    selectedTab: _selectedTab,
                    onTabChanged: (tab) =>
                        setState(() => _selectedTab = tab),
                  ),
                ),

                // ── Content ───────────────────────────────────────────────
                if (state is ShopLoading)
                  const SliverFillRemaining(
                    child: _LoadingState(),
                  )
                else if (state is ShopError)
                  SliverFillRemaining(
                    child: _ErrorState(
                      message: state.message,
                      onRetry: () => context
                          .read<ShopBloc>()
                          .add(const ShopRequested()),
                    ),
                  )
                else if (state is ShopLoaded) ...[
                  // Stats
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: _StatsRow(
                          shops: state.shops,
                          controller: _animController,
                        ),
                      ),
                    ),
                  ),
                  // Section header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        children: [
                          const Text(
                            'Store List',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _indigoSoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _filterShops(state.shops).length.toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _indigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Shop list
                  () {
                    final filtered = _filterShops(state.shops);
                    if (filtered.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          message: _searchQuery.isNotEmpty
                              ? 'No results for "$_searchQuery"'
                              : 'No shops in this category',
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final shop = filtered[index];
                          return FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.08),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _animController,
                                curve: Interval(
                                  (index * 0.05).clamp(0.0, 0.6),
                                  1.0,
                                  curve: Curves.easeOutCubic,
                                ),
                              )),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  index == filtered.length - 1 ? 100 : 10,
                                ),
                                child: _ShopCard(
                                  shop: shop,
                                  onView: () => _showShopDetails(shop),
                                  onEdit: () => _showEditShopDialog(shop),
                                  onDelete: () => _showDeleteConfirm(shop),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _filterShops(state.shops).length,
                      ),
                    );
                  }(),
                ] else
                  const SliverFillRemaining(child: SizedBox()),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddShopDialog,
          backgroundColor: _gold,
          foregroundColor: _void,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, size: 22),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: true,
              style: const TextStyle(
                  fontSize: 14, color: _ShopsPageState._ink),
              decoration: InputDecoration(
                hintText: 'Search shops...',
                hintStyle:
                    const TextStyle(color: _ShopsPageState._inkDim),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 16, color: _ShopsPageState._inkDim),
                filled: true,
                fillColor: _ShopsPageState._panel,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _ShopsPageState._border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _ShopsPageState._border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: _ShopsPageState._gold, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _ShopsPageState._panel,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: _ShopsPageState._border),
            ),
            child: const Icon(Icons.close_rounded,
                size: 14, color: _ShopsPageState._inkMid),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar Icon Button
// ─────────────────────────────────────────────────────────────────────────────
class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _ShopsPageState._panel,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _ShopsPageState._border),
        ),
        child: Icon(icon, size: 16, color: _ShopsPageState._inkMid),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Bar Delegate (pinned)
// ─────────────────────────────────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final String selectedTab;
  final ValueChanged<String> onTabChanged;

  const _TabBarDelegate({
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  bool shouldRebuild(_TabBarDelegate old) =>
      old.selectedTab != selectedTab;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _ShopsPageState._void,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: ['All', 'Active', 'Inactive', 'Pending']
                  .map((tab) {
                final isSelected = selectedTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onTabChanged(tab),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _ShopsPageState._gold
                            : _ShopsPageState._panel,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? _ShopsPageState._gold
                              : _ShopsPageState._border,
                        ),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? _ShopsPageState._void
                              : _ShopsPageState._inkMid,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Container(height: 1, color: _ShopsPageState._border),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final List<ShopEntity> shops;
  final AnimationController controller;

  const _StatsRow({required this.shops, required this.controller});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData('Total', shops.length, Icons.store_rounded,
          _ShopsPageState._indigo, _ShopsPageState._indigoSoft),
      _StatData(
          'Active',
          shops.where((s) => s.status.toLowerCase() == 'active').length,
          Icons.check_circle_rounded,
          _ShopsPageState._teal,
          _ShopsPageState._tealSoft),
      _StatData(
          'Inactive',
          shops.where((s) => s.status.toLowerCase() == 'inactive').length,
          Icons.pause_circle_rounded,
          _ShopsPageState._amber,
          _ShopsPageState._amberSoft),
      _StatData(
          'Pending',
          shops.where((s) => s.status.toLowerCase() == 'pending').length,
          Icons.hourglass_empty_rounded,
          _ShopsPageState._coral,
          _ShopsPageState._coralSoft),
    ];

    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          return AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final anim = CurvedAnimation(
                parent: controller,
                curve: Interval(
                  i * 0.1,
                  1.0,
                  curve: Curves.easeOutCubic,
                ),
              );
              return Opacity(
                opacity: anim.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1 - anim.value) * 15),
                  child: _MiniStatCard(data: stats[i]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatData(
      this.label, this.value, this.icon, this.color, this.bgColor);
}

class _MiniStatCard extends StatelessWidget {
  final _StatData data;
  const _MiniStatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ShopsPageState._card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ShopsPageState._border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: data.bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: data.color, size: 14),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _ShopsPageState._ink,
                  height: 1.1,
                ),
              ),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 10,
                  color: _ShopsPageState._inkDim,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shop Card (mobile list item)
// ─────────────────────────────────────────────────────────────────────────────
class _ShopCard extends StatelessWidget {
  final ShopEntity shop;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ShopCard({
    required this.shop,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(16),
        splashColor: _ShopsPageState._gold.withOpacity(0.05),
        highlightColor: _ShopsPageState._gold.withOpacity(0.03),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _ShopsPageState._card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _ShopsPageState._border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _ShopsPageState._indigoSoft,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                          color: _ShopsPageState._indigo
                              .withOpacity(0.15)),
                    ),
                    child: const Icon(Icons.store_rounded,
                        size: 18, color: _ShopsPageState._indigo),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _ShopsPageState._ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '#${shop.id}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: _ShopsPageState._inkDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: shop.status),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: _ShopsPageState._border),
              const SizedBox(height: 12),
              // Info rows
              _InfoRow(Icons.location_on_outlined, shop.address),
              const SizedBox(height: 6),
              _InfoRow(Icons.phone_outlined, shop.phone),
              const SizedBox(height: 6),
              _InfoRow(Icons.email_outlined, shop.email),
              if (shop.manager != null) ...[
                const SizedBox(height: 6),
                _InfoRow(Icons.person_outline_rounded, shop.manager!),
              ],
              const SizedBox(height: 14),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _CardButton(
                      label: 'View',
                      icon: Icons.visibility_outlined,
                      color: _ShopsPageState._indigo,
                      bgColor: _ShopsPageState._indigoSoft,
                      onTap: onView,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CardButton(
                      label: 'Edit',
                      icon: Icons.edit_outlined,
                      color: _ShopsPageState._teal,
                      bgColor: _ShopsPageState._tealSoft,
                      onTap: onEdit,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CardButton(
                      label: 'Delete',
                      icon: Icons.delete_outline_rounded,
                      color: _ShopsPageState._coral,
                      bgColor: _ShopsPageState._coralSoft,
                      onTap: onDelete,
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _ShopsPageState._inkDim),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 12, color: _ShopsPageState._inkMid),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CardButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _CardButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color, bgColor;
    switch (status.toLowerCase()) {
      case 'active':
        color = _ShopsPageState._teal;
        bgColor = _ShopsPageState._tealSoft;
        break;
      case 'inactive':
        color = _ShopsPageState._amber;
        bgColor = _ShopsPageState._amberSoft;
        break;
      case 'pending':
        color = _ShopsPageState._coral;
        bgColor = _ShopsPageState._coralSoft;
        break;
      default:
        color = _ShopsPageState._inkMid;
        bgColor = _ShopsPageState._inkDim.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// States: Loading / Error / Empty
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: _ShopsPageState._gold,
        strokeWidth: 2,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: _ShopsPageState._coralSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 36, color: _ShopsPageState._coral),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                  fontSize: 13, color: _ShopsPageState._inkMid),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: _ShopsPageState._card,
                foregroundColor: _ShopsPageState._ink,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_outlined,
                size: 52,
                color: _ShopsPageState._inkDim.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                  fontSize: 13, color: _ShopsPageState._inkDim),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shop Details Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ShopDetailsSheet extends StatelessWidget {
  final ShopEntity shop;
  const _ShopDetailsSheet({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _ShopsPageState._card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _ShopsPageState._inkDim,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _ShopsPageState._indigoSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.store_rounded,
                          color: _ShopsPageState._indigo, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _ShopsPageState._ink,
                            ),
                          ),
                          Text(
                            'ID: ${shop.id}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: _ShopsPageState._inkDim),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: shop.status),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _ShopsPageState._panel,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _ShopsPageState._border),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                          Icons.location_on_outlined, 'Address', shop.address),
                      const _Divider(),
                      _DetailRow(
                          Icons.phone_outlined, 'Phone', shop.phone),
                      const _Divider(),
                      _DetailRow(
                          Icons.email_outlined, 'Email', shop.email),
                      if (shop.manager != null) ...[
                        const _Divider(),
                        _DetailRow(Icons.person_outline_rounded,
                            'Manager', shop.manager!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: _ShopsPageState._panel,
                      foregroundColor: _ShopsPageState._inkMid,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Close'),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: _ShopsPageState._inkDim),
          const SizedBox(width: 10),
          SizedBox(
            width: 68,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: _ShopsPageState._inkDim)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _ShopsPageState._ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: _ShopsPageState._border);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Shop Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ShopFormSheet extends StatefulWidget {
  final ShopEntity? shop;
  final Function(String name, String address, String phone, String email)
      onSave;

  const _ShopFormSheet({this.shop, required this.onSave});

  @override
  State<_ShopFormSheet> createState() => _ShopFormSheetState();
}

class _ShopFormSheetState extends State<_ShopFormSheet> {
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _ShopsPageState._card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _ShopsPageState._inkDim,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _ShopsPageState._goldSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      isEdit
                          ? Icons.edit_rounded
                          : Icons.add_business_rounded,
                      color: _ShopsPageState._gold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Shop' : 'New Shop',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _ShopsPageState._ink,
                        ),
                      ),
                      const Text(
                        'Fill in the details below',
                        style: TextStyle(
                          fontSize: 11,
                          color: _ShopsPageState._inkDim,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _FormInput(
                controller: _nameCtrl,
                label: 'Shop Name',
                icon: Icons.store_rounded,
                validator: (v) =>
                    (v?.isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _FormInput(
                controller: _addressCtrl,
                label: 'Address',
                icon: Icons.location_on_rounded,
                validator: (v) =>
                    (v?.isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _FormInput(
                controller: _phoneCtrl,
                label: 'Phone',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v?.isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _FormInput(
                controller: _emailCtrl,
                label: 'Email',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  if (!v!.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                            color: _ShopsPageState._border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              color: _ShopsPageState._inkMid)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          widget.onSave(
                            _nameCtrl.text,
                            _addressCtrl.text,
                            _phoneCtrl.text,
                            _emailCtrl.text,
                          );
                        }
                      },
                      icon: Icon(
                          isEdit
                              ? Icons.save_rounded
                              : Icons.add_rounded,
                          size: 15),
                      label: Text(isEdit ? 'Save Changes' : 'Add Shop'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _ShopsPageState._gold,
                        foregroundColor: _ShopsPageState._void,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Form Input
// ─────────────────────────────────────────────────────────────────────────────
class _FormInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const _FormInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _ShopsPageState._inkDim,
            letterSpacing: 0.08,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
              fontSize: 14, color: _ShopsPageState._ink),
          decoration: InputDecoration(
            prefixIcon:
                Icon(icon, size: 15, color: _ShopsPageState._inkDim),
            filled: true,
            fillColor: _ShopsPageState._panel,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide:
                  const BorderSide(color: _ShopsPageState._border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide:
                  const BorderSide(color: _ShopsPageState._border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                  color: _ShopsPageState._gold, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                  color: _ShopsPageState._coral, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                  color: _ShopsPageState._coral, width: 1.5),
            ),
            errorStyle: const TextStyle(
                fontSize: 11, color: _ShopsPageState._coral),
          ),
        ),
      ],
    );
  }
}