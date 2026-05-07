import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/staff_bloc.dart';
import '../bloc/staff_event.dart';
import '../bloc/staff_state.dart';
import '../../domain/entities/staff_entity.dart';

// ════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS — matches Reports page _T exactly
// ════════════════════════════════════════════════════════════════════════════
class _T {
  static const bg         = Color(0xFFF5F6FA);
  static const white      = Color(0xFFFFFFFF);
  static const card       = Color(0xFFFFFFFF);
  static const primary    = Color(0xFF1E3A5F);
  static const primaryLt  = Color(0xFF2B527A);
  static const accent     = Color(0xFF00C896);
  static const accentSoft = Color(0x1A00C896);
  static const danger     = Color(0xFFFF4D4D);
  static const dangerSoft = Color(0x1AFF4D4D);
  static const warn       = Color(0xFFFFA726);
  static const warnSoft   = Color(0x1AFFA726);
  static const ink        = Color(0xFF1A2332);
  static const inkMid     = Color(0xFF64748B);
  static const inkLight   = Color(0xFFCBD5E1);
  static const border     = Color(0xFFE8EDF5);

  static TextStyle ts(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = ink,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primary.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get floatShadow => [
        BoxShadow(
          color: primary.withOpacity(0.14),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static Color primaryOpacity(double o) => primary.withOpacity(o);
  static Color whiteOpacity(double o)   => white.withOpacity(o);
  static Color accentOpacity(double o)  => accent.withOpacity(o);
}

// ════════════════════════════════════════════════════════════════════════════
// STAFF PAGE
// ════════════════════════════════════════════════════════════════════════════
class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double>   _fadeAnim;

  String _searchQuery      = '';
  final _searchController  = TextEditingController();
  bool   _isSearchVisible  = false;

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
    // Fetch staff safely — guarded against unmounted calls via BlocListener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StaffBloc>().add(const StaffRequested());
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

  // ── Toast ─────────────────────────────────────────────────────────────────
  void _showToast(String message, {bool error = false}) {
    if (!mounted) return;
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
              child: Text(message,
                  style: _T.ts(13,
                      weight: FontWeight.w500, color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: error ? _T.danger : _T.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Sheets / dialogs ──────────────────────────────────────────────────────
  void _showAddStaffSheet() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StaffFormSheet(
        onSave: (name, email, password, branchId) {
          context.read<StaffBloc>().add(StaffCreateRequested(
                name:     name,
                email:    email,
                password: password,
                branchId: branchId,
              ));
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEditStaffSheet(StaffEntity staff) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StaffFormSheet(
        staff: staff,
        onSave: (name, email, password, branchId) {
          context.read<StaffBloc>().add(StaffUpdateRequested(
                id:       staff.id,
                name:     name,
                email:    email,
                password: password,
                branchId: branchId,
              ));
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showDeleteConfirm(StaffEntity staff) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _T.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Staff Member',
            style: _T.ts(16, weight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to remove '
          '${staff.firstName} ${staff.lastName}? '
          'This action cannot be undone.',
          style: _T.ts(13, color: _T.inkMid, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: _T.ts(14, color: _T.inkMid)),
          ),
          FilledButton(
            onPressed: () {
              context
                  .read<StaffBloc>()
                  .add(StaffDeleteRequested(staff.id));
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: _T.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // ── Filter helper ─────────────────────────────────────────────────────────
  List<StaffEntity> _filterStaff(List<StaffEntity> staff) {
    if (_searchQuery.isEmpty) return staff;
    final q = _searchQuery.toLowerCase();
    return staff.where((s) {
      final fullName = '${s.firstName} ${s.lastName}'.toLowerCase();
      final email    = (s.email).toLowerCase();
      // Guard against null phone — use '' fallback
      final phone    = (s.phone ?? '').toLowerCase();
      return fullName.contains(q) ||
          email.contains(q) ||
          phone.contains(q);
    }).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _T.bg,
      ),
      child: Scaffold(
        backgroundColor: _T.bg,
        body: BlocConsumer<StaffBloc, StaffState>(
          listener: (context, state) {
            if (!mounted) return;
            if (state is StaffCreated) {
              _showToast('Staff member added');
              context.read<StaffBloc>().add(const StaffRequested());
              _animController
                ..reset()
                ..forward();
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
                // ── App Bar ────────────────────────────────────────────
                SliverAppBar(
                  backgroundColor: _T.primary,
                  foregroundColor: Colors.white,
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
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Staff',
                                  style: _T.ts(20,
                                      weight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3)),
                              const SizedBox(height: 2),
                              Text('Manage your team',
                                  style:
                                      _T.ts(11, color: Colors.white60)),
                            ],
                          ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_T.primary, _T.primaryLt],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    if (!_isSearchVisible) ...[
                      _IconBtn(
                        icon:  Icons.search_rounded,
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
                              color: _T.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded,
                                    size: 16, color: Colors.white),
                                const SizedBox(width: 5),
                                Text('Add Cashier',
                                    style: _T.ts(13,
                                        weight: FontWeight.w700,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // ── Loading ────────────────────────────────────────────
                if (state is StaffLoading)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                              color: _T.primary, strokeWidth: 2),
                          const SizedBox(height: 14),
                          Text('Loading staff…',
                              style: _T.ts(13, color: _T.inkMid)),
                        ],
                      ),
                    ),
                  )

                // ── Error ──────────────────────────────────────────────
                else if (state is StaffError)
                  SliverFillRemaining(
                    child: _ErrorState(
                      message: state.message,
                      onRetry: () => context
                          .read<StaffBloc>()
                          .add(const StaffRequested()),
                    ),
                  )

                // ── Loaded ─────────────────────────────────────────────
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

                  // Section header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          Text('Team Members',
                              style: _T.ts(15,
                                  weight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: _T.primaryOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _filterStaff(state.staff)
                                  .length
                                  .toString(),
                              style: _T.ts(11,
                                  weight: FontWeight.w600,
                                  color: _T.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Staff list
                  Builder(builder: (context) {
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
                          if (index >= filtered.length) {
                            return const SizedBox.shrink();
                          }
                          final staff = filtered[index];
                          final isLast = index == filtered.length - 1;

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
                                  isLast ? 100 : 10,
                                ),
                                child: _StaffCard(
                                  staff:    staff,
                                  onEdit:   () =>
                                      _showEditStaffSheet(staff),
                                  onDelete: () =>
                                      _showDeleteConfirm(staff),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    );
                  }),
                ]

                // ── Initial / unknown state ────────────────────────────
                else
                  const SliverFillRemaining(child: SizedBox()),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddStaffSheet,
          backgroundColor: _T.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.person_add_rounded, size: 20),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// STAFF STATS BAR
// ════════════════════════════════════════════════════════════════════════════
class _StaffStats extends StatelessWidget {
  final List<StaffEntity> staff;
  const _StaffStats({required this.staff});

  @override
  Widget build(BuildContext context) {
    // Guard: safe role comparison with null check
    final owners = staff
        .where((s) =>
            (s.roleName?.toLowerCase() ?? '') == 'owner')
        .length;
    final cashiers = staff
        .where((s) =>
            (s.roleName?.toLowerCase() ?? '') == 'cashier')
        .length;

    return SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _MiniStat(
            label: 'Total',
            value: staff.length,
            color: _T.primary,
            bg:    _T.primaryOpacity(0.1),
            icon:  Icons.people_alt_rounded,
          ),
          const SizedBox(width: 10),
          _MiniStat(
            label: 'Owners',
            value: owners,
            color: _T.accent,
            bg:    _T.accentSoft,
            icon:  Icons.manage_accounts_rounded,
          ),
          const SizedBox(width: 10),
          _MiniStat(
            label: 'Cashiers',
            value: cashiers,
            color: _T.warn,
            bg:    _T.warnSoft,
            icon:  Icons.point_of_sale_rounded,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String   label;
  final int      value;
  final Color    color;
  final Color    bg;
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
      width: 104,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.border),
        boxShadow: _T.cardShadow,
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
                style: _T.ts(20,
                    weight: FontWeight.w800, height: 1.1),
              ),
              Text(label,
                  style: _T.ts(10,
                      color: _T.inkMid, weight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// STAFF CARD
// ════════════════════════════════════════════════════════════════════════════
class _StaffCard extends StatelessWidget {
  final StaffEntity  staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffCard({
    required this.staff,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _roleColor {
    switch (staff.roleName?.toLowerCase()) {
      case 'owner':   return _T.accent;
      case 'cashier': return _T.warn;
      default:        return _T.primary;
    }
  }

  Color get _roleBg {
    switch (staff.roleName?.toLowerCase()) {
      case 'owner':   return _T.accentSoft;
      case 'cashier': return _T.warnSoft;
      default:        return _T.primaryOpacity(0.1);
    }
  }

  /// Safe initials — guards against empty strings
  String get _initials {
    final first = staff.firstName.isNotEmpty
        ? staff.firstName[0].toUpperCase()
        : '?';
    final last = staff.lastName.isNotEmpty
        ? staff.lastName[0].toUpperCase()
        : '';
    return '$first$last';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border),
        boxShadow: _T.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _roleBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _roleColor.withOpacity(0.2)),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: _T.ts(14,
                        weight: FontWeight.w800, color: _roleColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${staff.firstName} ${staff.lastName}'.trim(),
                      style: _T.ts(14, weight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      staff.email,
                      style: _T.ts(11, color: _T.inkMid),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (staff.roleName != null && staff.roleName!.isNotEmpty)
                _RoleBadge(
                  role:  staff.roleName!,
                  color: _roleColor,
                  bg:    _roleBg,
                ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: _T.border),
          const SizedBox(height: 12),

          // ── Phone row — guarded against null/empty
          if ((staff.phone ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.phone_outlined,
                      size: 13, color: _T.inkMid),
                  const SizedBox(width: 6),
                  Text(staff.phone!,
                      style: _T.ts(12, color: _T.inkMid)),
                ],
              ),
            ),

          // ── Action buttons
          Row(
            children: [
              Expanded(
                child: _CardBtn(
                  label: 'Edit',
                  icon:  Icons.edit_outlined,
                  color: _T.primary,
                  bg:    _T.primaryOpacity(0.08),
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CardBtn(
                  label: 'Remove',
                  icon:  Icons.person_remove_outlined,
                  color: _T.danger,
                  bg:    _T.dangerSoft,
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
  final Color  color;
  final Color  bg;

  const _RoleBadge({
    required this.role,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    // Safe capitalisation guard
    final display = role.isNotEmpty
        ? role[0].toUpperCase() + role.substring(1)
        : role;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(display,
          style:
              _T.ts(11, weight: FontWeight.w600, color: color)),
    );
  }
}

class _CardBtn extends StatelessWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final Color    bg;
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
        padding: const EdgeInsets.symmetric(vertical: 9),
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
                style: _T.ts(12,
                    weight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ERROR STATE
// ════════════════════════════════════════════════════════════════════════════
class _ErrorState extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  /// Determine if this is a "no data" error vs a real network/server error
  bool get _isEmptyResult {
    final m = message.toLowerCase();
    return m.contains('no staff') ||
        m.contains('not found') ||
        m.contains('empty');
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _isEmptyResult
                    ? _T.primaryOpacity(0.08)
                    : _T.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isEmptyResult
                    ? Icons.people_outline_rounded
                    : Icons.wifi_off_rounded,
                size: 32,
                color: _isEmptyResult ? _T.primary : _T.danger,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEmptyResult
                  ? 'No staff members found'
                  : 'Unable to load staff',
              style:
                  _T.ts(16, weight: FontWeight.w700, color: _T.ink),
            ),
            const SizedBox(height: 6),
            Text(
              _isEmptyResult
                  ? 'Add your first team member to get started.'
                  : 'Check your connection and try again.',
              style: _T.ts(13, color: _T.inkMid),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: _T.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text('Retry',
                        style: _T.ts(13,
                            weight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EMPTY STATE (no results / no data)
// ════════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final String       message;
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _T.bg,
                shape: BoxShape.circle,
                border: Border.all(color: _T.border, width: 2),
              ),
              child: const Icon(Icons.people_outline_rounded,
                  size: 32, color: _T.inkLight),
            ),
            const SizedBox(height: 14),
            Text(message,
                style: _T.ts(15,
                    weight: FontWeight.w600, color: _T.inkMid),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Tap the button below to add someone.',
                style: _T.ts(12, color: _T.inkLight),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _T.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text('Add Staff Member',
                        style: _T.ts(13,
                            weight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SEARCH BAR
// ════════════════════════════════════════════════════════════════════════════
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>  onChanged;
  final VoidCallback          onClose;

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
              onChanged:  onChanged,
              autofocus:  true,
              style: _T.ts(14),
              decoration: InputDecoration(
                hintText: 'Search staff…',
                hintStyle: _T.ts(13, color: _T.inkMid),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 16, color: _T.inkMid),
                filled: true,
                fillColor: _T.bg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _T.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _T.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _T.primary, width: 1.5),
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
              color: _T.whiteOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.close_rounded,
                size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData     icon;
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
          color: _T.whiteOpacity(0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// STAFF FORM BOTTOM SHEET
// ════════════════════════════════════════════════════════════════════════════
class _StaffFormSheet extends StatefulWidget {
  final StaffEntity? staff;
  final void Function(
    String name,
    String email,
    String password,
    int branchId,
  ) onSave;

  const _StaffFormSheet({this.staff, required this.onSave});

  @override
  State<_StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends State<_StaffFormSheet> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  int  _selectedBranchId = 0;
  bool _obscure          = true;
  List<Map<String, dynamic>> _branches = [];

  @override
  void initState() {
    super.initState();
    if (widget.staff != null) {
      final s = widget.staff!;
      _nameCtrl.text      = '${s.firstName} ${s.lastName}'.trim();
      _emailCtrl.text     = s.email;
      _selectedBranchId   = s.branchId ?? 0;
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
    // Replace with real branch fetch; keeps list empty for now
    if (mounted) setState(() => _branches = []);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.staff != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _T.white,
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
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _T.inkLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _T.primaryOpacity(0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      isEdit
                          ? Icons.edit_rounded
                          : Icons.person_add_rounded,
                      color: _T.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Cashier' : 'Add Cashier',
                        style: _T.ts(17, weight: FontWeight.w800),
                      ),
                      Text('Fill in the details below',
                          style: _T.ts(11, color: _T.inkMid)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Full name
              _FormField(
                controller:   _nameCtrl,
                label:        'Full Name',
                icon:         Icons.person_outline_rounded,
                validator:    (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Email
              _FormField(
                controller:   _emailCtrl,
                label:        'Email',
                icon:         Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Branch picker
              _FieldLabel(text: 'Branch'),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: _T.bg,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: _T.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _branches.any((b) =>
                            b['id'] == _selectedBranchId)
                        ? _selectedBranchId
                        : null,
                    hint: Text('Select branch',
                        style: _T.ts(14, color: _T.inkMid)),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _T.inkMid),
                    style: _T.ts(14),
                    items: _branches.map((branch) {
                      return DropdownMenuItem<int>(
                        value: branch['id'] as int,
                        child: Text(branch['name'] as String),
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

              // Password — add only
              if (!isEdit) ...[
                const SizedBox(height: 14),
                _FormField(
                  controller:  _passwordCtrl,
                  label:       'Password',
                  icon:        Icons.lock_outline_rounded,
                  obscureText: _obscure,
                  suffix: GestureDetector(
                    onTap: () =>
                        setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 16,
                      color: _T.inkMid,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 8) return 'At least 8 characters';
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Action row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        side: const BorderSide(color: _T.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel',
                          style: _T.ts(14, color: _T.inkMid)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          widget.onSave(
                            _nameCtrl.text.trim(),
                            _emailCtrl.text.trim(),
                            isEdit ? '' : _passwordCtrl.text,
                            _selectedBranchId,
                          );
                        }
                      },
                      icon: Icon(
                        isEdit
                            ? Icons.save_rounded
                            : Icons.person_add_rounded,
                        size: 15,
                      ),
                      label: Text(
                          isEdit ? 'Save Changes' : 'Add Cashier'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _T.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
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

// ════════════════════════════════════════════════════════════════════════════
// FORM HELPERS
// ════════════════════════════════════════════════════════════════════════════

/// Uppercase label above each field — consistent with the Reports filter style
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: _T.ts(10,
          weight: FontWeight.w700,
          color: _T.inkMid,
          letterSpacing: 0.6),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController      controller;
  final String                     label;
  final IconData                   icon;
  final String? Function(String?)? validator;
  final TextInputType?              keyboardType;
  final bool                       obscureText;
  final Widget?                    suffix;

  const _FormField({
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
        _FieldLabel(text: label),
        const SizedBox(height: 6),
        TextFormField(
          controller:   controller,
          keyboardType: keyboardType,
          obscureText:  obscureText,
          validator:    validator,
          style: _T.ts(14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16, color: _T.inkMid),
            suffixIcon: suffix,
            filled: true,
            fillColor: _T.bg,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _T.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: _T.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide:
                  const BorderSide(color: _T.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide:
                  const BorderSide(color: _T.danger, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide:
                  const BorderSide(color: _T.danger, width: 1.5),
            ),
            errorStyle: _T.ts(11, color: _T.danger),
          ),
        ),
      ],
    );
  }
}