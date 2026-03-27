import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_event.dart';
import '../bloc/user_state.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'all';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    context.read<UserBloc>().add(const UsersFetchRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Management',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: Colors.white,
              ),
            ),
            BlocBuilder<UserBloc, UserState>(
              builder: (context, state) {
                if (state is UsersLoaded) {
                  return Text(
                    '${state.users.length} users total',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white54,
                      fontWeight: FontWeight.w400,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => _showUserDialog(context, null),
              icon: const Icon(Icons.person_add_outlined, size: 16),
              label: const Text('Add User',
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
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(state.message),
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
            context.read<UserBloc>().add(const UsersFetchRequested());
            _animController.reset();
            _animController.forward();
          } else if (state is UserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is UsersLoaded) {
            if (!_animController.isCompleted) _animController.forward();
          }
        },
        builder: (context, state) {
          if (state is UsersLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3B82F6),
                strokeWidth: 2.5,
              ),
            );
          }

          if (state is UserError) {
            return ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<UserBloc>().add(const UsersFetchRequested()),
            );
          }

          final users =
              state is UsersLoaded ? state.users : <dynamic>[];

          final filtered = _getFilteredUsers(users);

          return FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                // ── Toolbar ─────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Search
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) =>
                                    setState(() => _searchQuery = v),
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Search by name or email...',
                                  hintStyle: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.search_rounded,
                                      size: 18, color: Color(0xFF94A3B8)),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded,
                                              size: 16,
                                              color: Color(0xFF94A3B8)),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 14),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF3B82F6), width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Role filter tabs
                      Row(
                        children: [
                          _FilterTab(
                              label: 'All', value: 'all', current: _filter,
                              count: users.length,
                              onTap: (v) => setState(() => _filter = v)),
                          const SizedBox(width: 6),
                          _FilterTab(
                              label: 'Admin',
                              value: 'super_admin',
                              current: _filter,
                              count: users
                                  .where((u) => u.role == 'super_admin')
                                  .length,
                              color: const Color(0xFFDC2626),
                              onTap: (v) => setState(() => _filter = v)),
                          const SizedBox(width: 6),
                          _FilterTab(
                              label: 'Owner',
                              value: 'owner',
                              current: _filter,
                              count: users
                                  .where((u) => u.role == 'owner')
                                  .length,
                              color: const Color(0xFF059669),
                              onTap: (v) => setState(() => _filter = v)),
                          const SizedBox(width: 6),
                          _FilterTab(
                              label: 'Cashier',
                              value: 'cashier',
                              current: _filter,
                              count: users
                                  .where((u) => u.role == 'cashier')
                                  .length,
                              color: const Color(0xFF6366F1),
                              onTap: (v) => setState(() => _filter = v)),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // ── Table Area ───────────────────────────────────
                Expanded(
                  child: users.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline_rounded,
                                  size: 56, color: Color(0xFFCBD5E1)),
                              const SizedBox(height: 14),
                              const Text(
                                'No users yet',
                                style: TextStyle(
                                    fontSize: 16, color: Color(0xFF94A3B8)),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () =>
                                    _showUserDialog(context, null),
                                icon: const Icon(Icons.person_add_outlined,
                                    size: 16),
                                label: const Text('Add First User'),
                                style: FilledButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF0D1B2A)),
                              ),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No results for "$_searchQuery"',
                                style: const TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 14),
                              ),
                            )
                          : Container(
                              margin: const EdgeInsets.all(16),
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
                                  // Table header row
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 14, 16, 12),
                                    child: Row(
                                      children: [
                                        const Text(
                                          'Users',
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
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${filtered.length}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF3B82F6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                      height: 1, color: Color(0xFFF1F5F9)),
                                  // Scrollable table
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          headingRowHeight: 42,
                                          dataRowMinHeight: 58,
                                          dataRowMaxHeight: 68,
                                          headingRowColor:
                                              MaterialStateProperty.all(
                                                  const Color(0xFFF8FAFC)),
                                          dividerThickness: 1,
                                          columnSpacing: 20,
                                          horizontalMargin: 16,
                                          columns: const [
                                            DataColumn(
                                                label: _ColHeader(label: 'User')),
                                            DataColumn(
                                                label:
                                                    _ColHeader(label: 'Email')),
                                            DataColumn(
                                                label: _ColHeader(label: 'Role')),
                                            DataColumn(
                                                label:
                                                    _ColHeader(label: 'Joined')),
                                            DataColumn(
                                                label: _ColHeader(
                                                    label: 'Actions')),
                                          ],
                                          rows: filtered.map((user) {
                                            return DataRow(cells: [
                                              // User
                                              DataCell(
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    _Avatar(
                                                        name: user.name,
                                                        role: user.role),
                                                    const SizedBox(width: 10),
                                                    ConstrainedBox(
                                                      constraints:
                                                          const BoxConstraints(
                                                              maxWidth: 130),
                                                      child: Text(
                                                        user.name.isNotEmpty
                                                            ? user.name
                                                            : 'Unnamed',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Color(0xFF0D1B2A),
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Email
                                              DataCell(
                                                ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                          maxWidth: 200),
                                                  child: Text(
                                                    user.email.isNotEmpty
                                                        ? user.email
                                                        : '—',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              // Role
                                              DataCell(
                                                _RoleBadge(role: user.role),
                                              ),
                                              // Joined
                                              DataCell(
                                                Text(
                                                  user.createdAt != null
                                                      ? _fmtDate(
                                                          user.createdAt!)
                                                      : '—',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ),
                                              // Actions
                                              DataCell(
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    _ActionButton(
                                                      icon: Icons
                                                          .edit_outlined,
                                                      color: const Color(
                                                          0xFF059669),
                                                      tooltip: 'Edit',
                                                      onTap: () =>
                                                          _showUserDialog(
                                                              context, user),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    _ActionButton(
                                                      icon: Icons
                                                          .delete_outline_rounded,
                                                      color: const Color(
                                                          0xFFDC2626),
                                                      tooltip: 'Delete',
                                                      onTap: () =>
                                                          _showDeleteConfirm(
                                                              context,
                                                              user.id,
                                                              user.name),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ]);
                                          }).toList(),
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
          );
        },
      ),
    );
  }

  List<dynamic> _getFilteredUsers(List<dynamic> users) {
    return users.where((u) {
      final matchSearch = _searchQuery.isEmpty ||
          u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchFilter = _filter == 'all' || u.role == _filter;
      return matchSearch && matchFilter;
    }).toList();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _showUserDialog(BuildContext context, dynamic user) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    String selectedRole = user?.role ?? 'cashier';
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isEdit = user != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
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
                              isEdit
                                  ? Icons.edit_rounded
                                  : Icons.person_add_outlined,
                              color: const Color(0xFF3B82F6),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isEdit ? 'Edit User' : 'Add New User',
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
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _FormField(
                        controller: nameCtrl,
                        label: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _FormField(
                        controller: emailCtrl,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v?.trim().isEmpty ?? true) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(v!)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      // Role selector
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          labelStyle: const TextStyle(
                              fontSize: 13, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.badge_outlined,
                              size: 17, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0xFF3B82F6), width: 1.5),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'super_admin',
                              child: Text('Admin',
                                  style: TextStyle(fontSize: 14))),
                          DropdownMenuItem(
                              value: 'owner',
                              child: Text('Owner',
                                  style: TextStyle(fontSize: 14))),
                          DropdownMenuItem(
                              value: 'cashier',
                              child: Text('Cashier',
                                  style: TextStyle(fontSize: 14))),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() => selectedRole = v);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      _FormField(
                        controller: passwordCtrl,
                        label: isEdit
                            ? 'New Password (leave blank to keep)'
                            : 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                        validator: isEdit
                            ? null
                            : (v) {
                                if (v?.trim().isEmpty ?? true) {
                                  return 'Password is required';
                                }
                                if ((v?.length ?? 0) < 8) {
                                  return 'Minimum 8 characters';
                                }
                                return null;
                              },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                final data = {
                                  'name': nameCtrl.text.trim(),
                                  'email': emailCtrl.text.trim(),
                                  'role': selectedRole,
                                };
                                if (isEdit) {
                                  if (passwordCtrl.text.isNotEmpty) {
                                    data['password'] = passwordCtrl.text;
                                  }
                                  context.read<UserBloc>().add(
                                      UserUpdateRequested(user.id, data));
                                } else {
                                  data['password'] = passwordCtrl.text.trim();
                                  context
                                      .read<UserBloc>()
                                      .add(UserCreateRequested(data));
                                }
                                Navigator.pop(ctx);
                              }
                            },
                            icon: Icon(
                                isEdit
                                    ? Icons.save_rounded
                                    : Icons.person_add_outlined,
                                size: 16),
                            label: Text(isEdit ? 'Save Changes' : 'Add User'),
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
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "$name"? This action cannot be undone.',
          style:
              const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<UserBloc>().add(UserDeleteRequested(id));
              Navigator.pop(ctx);
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

class _Avatar extends StatelessWidget {
  final String name;
  final String role;
  const _Avatar({required this.name, required this.role});

  Color get _color {
    switch (role) {
      case 'super_admin':
        return const Color(0xFFDC2626);
      case 'owner':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _color,
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  Color get _color {
    switch (role) {
      case 'super_admin':
        return const Color(0xFFDC2626);
      case 'owner':
        return const Color(0xFF059669);
      case 'cashier':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF64748B);
    }
  }

  String get _label {
    switch (role) {
      case 'super_admin':
        return 'Admin';
      case 'owner':
        return 'Owner';
      case 'cashier':
        return 'Cashier';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final int count;
  final Color? color;
  final ValueChanged<String> onTap;

  const _FilterTab({
    required this.label,
    required this.value,
    required this.current,
    required this.count,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current == value;
    final activeColor = color ?? const Color(0xFF0D1B2A);
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? activeColor : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? activeColor : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  color: isActive
                      ? Colors.white70
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
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

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;

  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B2A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
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
          borderSide:
              const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
      ),
    );
  }
}