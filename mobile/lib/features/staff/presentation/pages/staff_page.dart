import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/staff_bloc.dart';
import '../bloc/staff_event.dart';
import '../bloc/staff_state.dart';
import '../../domain/entities/staff_entity.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isSearchVisible = false;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const _void       = Color(0xFF09090F);
  static const _surface    = Color(0xFF111118);
  static const _panel      = Color(0xFF16161F);
  static const _card       = Color(0xFF1C1C28);
  static const _border     = Color(0x18FFFFFF);
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

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    context.read<StaffBloc>().add(const StaffRequested());
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
                child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: error ? _coral : _teal,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddStaffSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StaffFormSheet(
        onSave: (name, email, password, branchId) {
          context.read<StaffBloc>().add(StaffCreateRequested(
                name: name,
                email: email,
                password: password,
                branchId: branchId,
              ));
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEditStaffSheet(StaffEntity staff) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StaffFormSheet(
        staff: staff,
        onSave: (name, email, password, branchId) {
          context.read<StaffBloc>().add(StaffUpdateRequested(
                id: staff.id,
                name: name,
                email: email,
                password: password,
                branchId: branchId,
              ));
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showDeleteConfirm(StaffEntity staff) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Staff Member',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
        ),
        content: Text(
          'Are you sure you want to remove ${staff.firstName} ${staff.lastName}? This action cannot be undone.',
          style: const TextStyle(
              fontSize: 13, color: _inkMid, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: _inkMid)),
          ),
          FilledButton(
            onPressed: () {
              context
                  .read<StaffBloc>()
                  .add(StaffDeleteRequested(staff.id));
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: _coral,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  List<StaffEntity> _filterStaff(List<StaffEntity> staff) {
    if (_searchQuery.isEmpty) return staff;
    return staff.where((s) {
      final q = _searchQuery.toLowerCase();
      return '${s.firstName} ${s.lastName}'.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q) ||
          (s.phone.toLowerCase().contains(q));
    }).toList();
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
        body: BlocConsumer<StaffBloc, StaffState>(
          listener: (context, state) {
            if (state is StaffCreated) {
              _showToast('Staff member added');
              context.read<StaffBloc>().add(const StaffRequested());
              _animController.reset();
              _animController.forward();
            } else if (state is StaffUpdated) {
              _showToast('Staff member updated');
              context.read<StaffBloc>().add(const StaffRequested());
            } else if (state is StaffDeleted) {
              _showToast('Staff member removed');
              context.read<StaffBloc>().add(const StaffRequested());
            } else if (state is StaffError) {
              _showToast(state.message, error: true);
            }
          },
          builder: (context, state) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── App Bar ───────────────────────────────────────────
                SliverAppBar(
                  backgroundColor: _surface,
                  foregroundColor: _ink,
                  elevation: 0,
                  pinned: true,
                  expandedHeight: 110,
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
                        : const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Staff',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Manage your team',
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
                            bottom: BorderSide(color: _border)),
                      ),
                    ),
                  ),
                  actions: [
                    if (!_isSearchVisible) ...[
                      _IconBtn(
                        icon: Icons.search_rounded,
                        onTap: () =>
                            setState(() => _isSearchVisible = true),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: _showAddStaffSheet,
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
                                  'Add Cashier',
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

                // ── Content ───────────────────────────────────────────
                if (state is StaffLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                          color: _gold, strokeWidth: 2),
                    ),
                  )
                else if (state is StaffError)
                  SliverFillRemaining(
                    child: _EmptyStaffState(
                      message: state.message.toLowerCase().contains('no staff') || 
                               state.message.toLowerCase().contains('not found') ||
                               state.message.toLowerCase().contains('empty')
                          ? 'No staff members found'
                          : 'Unable to load staff',
                      onRetry: () => context
                          .read<StaffBloc>()
                          .add(const StaffRequested()),
                    ),
                  )
                else if (state is StaffLoaded) ...[
                  // Stats bar
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: _StaffStats(staff: state.staff),
                      ),
                    ),
                  ),
                  // List header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          const Text(
                            'Team Members',
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
                              _filterStaff(state.staff).length.toString(),
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
                  // Staff list
                  () {
                    final filtered = _filterStaff(state.staff);
                    if (filtered.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          message: _searchQuery.isNotEmpty
                              ? 'No results for "$_searchQuery"'
                              : 'No staff members yet',
                          onAdd: _showAddStaffSheet,
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final staff = filtered[index];
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
                                child: _StaffCard(
                                  staff: staff,
                                  onEdit: () =>
                                      _showEditStaffSheet(staff),
                                  onDelete: () =>
                                      _showDeleteConfirm(staff),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _filterStaff(state.staff).length,
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
          onPressed: _showAddStaffSheet,
          backgroundColor: _gold,
          foregroundColor: _void,
          elevation: 4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.person_add_rounded, size: 20),
        ),
      ),
    );
  }
}

// ─── Staff Stats Bar ──────────────────────────────────────────────────────────
class _StaffStats extends StatelessWidget {
  final List<StaffEntity> staff;
  const _StaffStats({required this.staff});

  @override
  Widget build(BuildContext context) {
    final roles = {
      'owner': staff.where((s) => s.roleName?.toLowerCase() == 'owner').length,
      'cashier':
          staff.where((s) => s.roleName?.toLowerCase() == 'cashier').length,
    };

    return SizedBox(
      height: 82,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _MiniStat(
              label: 'Total',
              value: staff.length,
              color: const Color(0xFF7B68EE),
              bg: const Color(0x1F7B68EE),
              icon: Icons.people_alt_rounded),
          const SizedBox(width: 10),
          _MiniStat(
              label: 'Owners',
              value: roles['owner'] ?? 0,
              color: const Color(0xFF00D9A3),
              bg: const Color(0x1A00D9A3),
              icon: Icons.manage_accounts_rounded),
          const SizedBox(width: 10),
          _MiniStat(
              label: 'Cashiers',
              value: roles['cashier'] ?? 0,
              color: const Color(0xFFFF9F43),
              bg: const Color(0x1FFF9F43),
              icon: Icons.point_of_sale_rounded),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color bg;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF0F0FF),
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF4A4A62),
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

// ─── Staff Card ───────────────────────────────────────────────────────────────
class _StaffCard extends StatelessWidget {
  final StaffEntity staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffCard({
    required this.staff,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _roleColor {
    switch (staff.roleName?.toLowerCase()) {
      case 'owner':
        return const Color(0xFF00D9A3);
      case 'cashier':
        return const Color(0xFFFF9F43);
      default:
        return const Color(0xFF7B68EE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials =
        '${staff.firstName.isNotEmpty ? staff.firstName[0] : '?'}${staff.lastName.isNotEmpty ? staff.lastName[0] : ''}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _roleColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _roleColor.withOpacity(0.2)),
                ),
                child: Center(
                  child: Text(
                    initials.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _roleColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${staff.firstName} ${staff.lastName}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF0F0FF),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      staff.email,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4A4A62),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (staff.roleName != null)
                _RoleBadge(role: staff.roleName!),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0x18FFFFFF)),
          const SizedBox(height: 12),
          // Info
          Row(
            children: [
              const Icon(Icons.phone_outlined,
                  size: 13, color: Color(0xFF4A4A62)),
              const SizedBox(width: 6),
              Text(
                staff.phone,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF8B8BA8)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Actions
          Row(
            children: [
              Expanded(
                child: _CardBtn(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF00D9A3),
                  bg: const Color(0x1A00D9A3),
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CardBtn(
                  label: 'Remove',
                  icon: Icons.person_remove_outlined,
                  color: const Color(0xFFFF5F6D),
                  bg: const Color(0x1AFF5F6D),
                  onTap: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    switch (role.toLowerCase()) {
      case 'owner':
        color = const Color(0xFF00D9A3);
        bg = const Color(0x1A00D9A3);
        break;
      case 'cashier':
        color = const Color(0xFFFF9F43);
        bg = const Color(0x1FFF9F43);
        break;
      default:
        color = const Color(0xFF7B68EE);
        bg = const Color(0x1F7B68EE);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        role[0].toUpperCase() + role.substring(1),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _CardBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _CardBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

// ─── States ───────────────────────────────────────────────────────────────────
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
                  color: Color(0x1AFF5F6D), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded,
                  size: 36, color: Color(0xFFFF5F6D)),
            ),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF8B8BA8)),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1C1C28),
                foregroundColor: const Color(0xFFF0F0FF),
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

class _EmptyStaffState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _EmptyStaffState({required this.message, required this.onRetry});

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
              decoration: BoxDecoration(
                  color: const Color(0x1F7B68EE), shape: BoxShape.circle),
              child: const Icon(Icons.people_outline_rounded,
                  size: 36, color: Color(0xFF7B68EE)),
            ),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF8B8BA8)),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Add your first team member to get started',
              style: TextStyle(
                  fontSize: 11, color: Color(0xFF4A4A62)),
              textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF5C842),
                foregroundColor: const Color(0xFF09090F),
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
  final VoidCallback onAdd;
  const _EmptyState({required this.message, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 52,
                color: const Color(0xFF4A4A62).withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF4A4A62)),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5C842),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Add Staff Member',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF09090F),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchBar(
      {required this.controller,
      required this.onChanged,
      required this.onClose});

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
                  fontSize: 14, color: Color(0xFFF0F0FF)),
              decoration: InputDecoration(
                hintText: 'Search staff...',
                hintStyle:
                    const TextStyle(color: Color(0xFF4A4A62)),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 16, color: Color(0xFF4A4A62)),
                filled: true,
                fillColor: const Color(0xFF16161F),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0x18FFFFFF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0x18FFFFFF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFFF5C842), width: 1.5),
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
              color: const Color(0xFF16161F),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x18FFFFFF)),
            ),
            child: const Icon(Icons.close_rounded,
                size: 14, color: Color(0xFF8B8BA8)),
          ),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF16161F),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0x18FFFFFF)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF8B8BA8)),
      ),
    );
  }
}

// ─── Staff Form Bottom Sheet ──────────────────────────────────────────────────
class _StaffFormSheet extends StatefulWidget {
  final StaffEntity? staff;
  final Function(String name, String email, String password, int branchId) onSave;

  const _StaffFormSheet({this.staff, required this.onSave});

  @override
  State<_StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends State<_StaffFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  int _selectedBranchId = 0;
  bool _obscure = true;
  List<Map<String, dynamic>> _branches = [];

  static const _card    = Color(0xFF1C1C28);
  static const _panel   = Color(0xFF16161F);
  static const _border  = Color(0x18FFFFFF);
  static const _ink     = Color(0xFFF0F0FF);
  static const _inkDim  = Color(0xFF4A4A62);
  static const _inkMid  = Color(0xFF8B8BA8);
  static const _gold    = Color(0xFFF5C842);
  static const _goldSoft = Color(0x20F5C842);
  static const _void    = Color(0xFF09090F);
  static const _coral   = Color(0xFFFF5F6D);

  @override
  void initState() {
    super.initState();
    if (widget.staff != null) {
      _nameCtrl.text = widget.staff!.firstName + ' ' + widget.staff!.lastName;
      _emailCtrl.text = widget.staff!.email;
      _selectedBranchId = widget.staff!.branchId ?? 0;
    }
    _loadBranches();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    // TODO: Load branches from API when branches are available
    setState(() {
      _branches = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.staff != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _card,
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
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _inkDim,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _goldSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      isEdit
                          ? Icons.edit_rounded
                          : Icons.person_add_rounded,
                      color: _gold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Cashier' : 'Add Cashier',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const Text('Fill in the details',
                          style: TextStyle(
                              fontSize: 11, color: _inkDim)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _Input(
                controller: _nameCtrl,
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                validator: (v) =>
                    (v?.isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _Input(
                controller: _emailCtrl,
                label: 'Email',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  if (!(v!.contains('@'))) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              // Branch picker
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BRANCH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _inkDim,
                      letterSpacing: 0.08,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: _border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedBranchId,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _inkMid),
                        style: const TextStyle(color: _ink, fontSize: 14),
                        items: _branches.map((branch) {
                          return DropdownMenuItem<int>(
                            value: branch['id'] as int,
                            child: Text(
                              branch['name'] as String,
                              style: const TextStyle(color: _ink),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedBranchId = value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              if (!isEdit) ...[
                const SizedBox(height: 14),
                _Input(
                  controller: _passwordCtrl,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscure,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 16,
                      color: _inkMid,
                    ),
                  ),
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    if ((v?.length ?? 0) < 8) {
                      return 'At least 8 characters';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(color: _inkMid)),
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
                            _emailCtrl.text,
                            isEdit ? '' : _passwordCtrl.text,
                            _selectedBranchId,
                          );
                        }
                      },
                      icon: Icon(
                          isEdit
                              ? Icons.save_rounded
                              : Icons.person_add_rounded,
                          size: 15),
                      label:
                          Text(isEdit ? 'Save Changes' : 'Add Cashier'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: _void,
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

// ─── Form Input ───────────────────────────────────────────────────────────────
class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  static const _panel  = Color(0xFF16161F);
  static const _border = Color(0x18FFFFFF);
  static const _ink    = Color(0xFFF0F0FF);
  static const _inkDim = Color(0xFF4A4A62);
  static const _inkMid = Color(0xFF8B8BA8);
  static const _gold   = Color(0xFFF5C842);
  static const _coral  = Color(0xFFFF5F6D);

  const _Input({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
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
            color: _inkDim,
            letterSpacing: 0.08,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: _ink),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 15, color: _inkMid),
            suffixIcon: suffix,
            filled: true,
            fillColor: _panel,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _gold, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _coral, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _coral, width: 1.5),
            ),
            errorStyle:
                const TextStyle(fontSize: 11, color: _coral),
          ),
        ),
      ],
    );
  }
}