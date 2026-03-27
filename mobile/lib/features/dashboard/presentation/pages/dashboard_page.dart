import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../sales/presentation/bloc/sales_bloc.dart';
import '../../../sales/presentation/bloc/sales_event.dart';
import '../../../sales/presentation/bloc/sales_state.dart';
import '../widgets/stats_card.dart';

// ════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ════════════════════════════════════════════════════════════════════════════
class _D {
  static const bg         = Color(0xFFF5F6FA);
  static const white      = Color(0xFFFFFFFF);
  static const primary    = Color(0xFF1E3A5F);
  static const primaryLt  = Color(0xFF2B527A);
  static const accent     = Color(0xFF00C896);
  static const accentSoft = Color(0x1A00C896);
  static const warn       = Color(0xFFFFA726);
  static const warnSoft   = Color(0x1AFFA726);
  static const danger     = Color(0xFFFF4D4D);
  static const dangerSoft = Color(0x1AFF4D4D);
  static const info       = Color(0xFF3B82F6);
  static const infoSoft   = Color(0x1A3B82F6);
  static const ink        = Color(0xFF1A2332);
  static const inkMid     = Color(0xFF64748B);
  static const inkLight   = Color(0xFFCBD5E1);
  static const border     = Color(0xFFE8EDF5);

  static TextStyle ts(double size, {
    FontWeight weight = FontWeight.w400,
    Color color = ink,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF1E3A5F).withOpacity(0.07),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];
}

// ════════════════════════════════════════════════════════════════════════════
// DASHBOARD PAGE
// ════════════════════════════════════════════════════════════════════════════
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load sales data
    Future.microtask(() {
      context.read<SalesBloc>().add(const SalesFetchRequested());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() => context.read<SalesBloc>().add(const SalesFetchRequested());

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const _LoginRequiredScreen();
        }

        final user = authState.user;
        final role = user.roleName.toLowerCase().trim();

        if (role == 'owner' || role == 'business owner' || role == 'super_admin') {
          return _OwnerDashboardView(
            user: user,
            tabController: _tabController,
            onReload: _reload,
          );
        } else if (role == 'cashier') {
          return _CashierDashboardView(user: user);
        } else {
          return _DefaultDashboardView(user: user);
        }
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ROLE-BASED DASHBOARDS
// ════════════════════════════════════════════════════════════════════════════

class _OwnerDashboardView extends StatelessWidget {
  const _OwnerDashboardView({
    required this.user,
    required this.tabController,
    required this.onReload,
  });

  final dynamic user;
  final TabController tabController;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final role = user.roleName.toLowerCase().trim();
    final isOwner = role == 'owner' || role == 'business owner';

    return Scaffold(
      backgroundColor: _D.bg,
      body: SafeArea(
        child: Column(
          children: [
            _DashHeader(
              firstName: user.firstName ?? 'User',
              subtitle: 'Owner Dashboard',
              actions: [
                if (isOwner)
                  _HeaderAction(
                    icon: Icons.settings_outlined,
                    onTap: () => context.push(RouteNames.settings),
                  ),
                _HeaderAction(
                  icon: Icons.logout_rounded,
                  onTap: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
                ),
              ],
            ),
            Container(
              color: _D.white,
              child: TabBar(
                controller: tabController,
                labelColor: _D.primary,
                unselectedLabelColor: _D.inkMid,
                indicatorColor: _D.primary,
                indicatorWeight: 3,
                labelStyle: _D.ts(13, weight: FontWeight.w700),
                unselectedLabelStyle: _D.ts(13, weight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined, size: 18)),
                  Tab(text: 'Analytics', icon: Icon(Icons.bar_chart_rounded, size: 18)),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  _OverviewTab(onReload: onReload),
                  _AnalyticsTab(onReload: onReload),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _PrimaryFAB(
        icon: Icons.add_rounded,
        label: 'New Sale',
        onTap: () => context.push(RouteNames.pos),
      ),
    );
  }
}

class _CashierDashboardView extends StatelessWidget {
  const _CashierDashboardView({required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _D.bg,
      body: SafeArea(
        child: Column(
          children: [
            _DashHeader(
              firstName: user.firstName ?? 'User',
              subtitle: 'Cashier Dashboard',
              actions: [
                _HeaderAction(
                  icon: Icons.logout_rounded,
                  onTap: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _HeroCard(
                      icon: Icons.point_of_sale_rounded,
                      title: 'Point of Sale',
                      subtitle: 'Start ringing up customers',
                      color: _D.primary,
                      onTap: () => context.push(RouteNames.pos),
                    ),
                    const SizedBox(height: 16),
                    _HeroCard(
                      icon: Icons.history_rounded,
                      title: 'Sales History',
                      subtitle: 'View your recent transactions',
                      color: _D.accent,
                      onTap: () => context.push(RouteNames.sales),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _PrimaryFAB(
        icon: Icons.point_of_sale_rounded,
        label: 'Open POS',
        onTap: () => context.push(RouteNames.pos),
      ),
    );
  }
}

class _DefaultDashboardView extends StatelessWidget {
  const _DefaultDashboardView({required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _D.bg,
      body: SafeArea(
        child: Column(
          children: [
            _DashHeader(
              firstName: user.firstName ?? 'User',
              subtitle: 'Dashboard',
              actions: [
                _HeaderAction(
                  icon: Icons.logout_rounded,
                  onTap: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _D.infoSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.dashboard_rounded,
                            color: _D.info, size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text('Welcome, ${user.firstName ?? "User"}',
                          style: _D.ts(20, weight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Contact your admin to assign a role',
                          style: _D.ts(14, color: _D.inkMid),
                          textAlign: TextAlign.center),
                    ],
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

// ════════════════════════════════════════════════════════════════════════════
// FIXED LOGIN REQUIRED SCREEN
// ════════════════════════════════════════════════════════════════════════════
class _LoginRequiredScreen extends StatelessWidget {
  const _LoginRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _D.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _D.infoSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: _D.info, size: 36),
              ),
              const SizedBox(height: 20),
              Text('Authentication Required',
                  style: _D.ts(20, weight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Please log in to access the dashboard',
                  style: _D.ts(14, color: _D.inkMid),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    print('Navigating to: ${RouteNames.login}');
                    final secureStorage = SecureStorage();
                    final token = await secureStorage.getToken();
                    print('Current token: $token');
                    
                    // Clear the token and navigate to login
                    await secureStorage.deleteToken();
                    await secureStorage.deleteUser();
                    print('Token cleared, navigating to login');
                    GoRouter.of(context).go(RouteNames.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _D.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),      
                    elevation: 0,
                  ),
                  child: const Text(
                    'Go to Login',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHARED COMPONENTS
// ════════════════════════════════════════════════════════════════════════════

class _DashHeader extends StatelessWidget {
  const _DashHeader({
    required this.firstName,
    required this.subtitle,
    required this.actions,
  });

  final String firstName;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: _D.primary,
        boxShadow: [
          BoxShadow(
            color: _D.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _D.accent.withOpacity(0.25),
            child: Text(
              firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
              style: _D.ts(16, weight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hi, $firstName 👋',
                    style: _D.ts(15, weight: FontWeight.w700, color: Colors.white)),
                Text(subtitle,
                    style: _D.ts(11, color: Colors.white60)),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _GreetingBanner extends StatelessWidget {
  const _GreetingBanner({
    required this.salesCount,
    required this.todayCount,
  });

  final int salesCount;
  final int todayCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_D.primary, _D.primaryLt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _D.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Business Overview',
                    style: _D.ts(16, weight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text('$todayCount sales today · $salesCount total',
                    style: _D.ts(12, color: Colors.white70)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _D.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _D.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: _D.ts(16, weight: FontWeight.w800, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(title,
                  style: _D.ts(11, color: _D.inkMid),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _D.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _D.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: _D.ts(11, weight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({required this.sale, required this.onTap});

  final dynamic sale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    String dateStr = '';
    try {
      dateStr = DateTime.parse(sale.createdAt)
          .toString()
          .substring(0, 16)
          .replaceAll('T', '  ');
    } catch (_) {}

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _D.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _D.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _D.accentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_rounded,
                  color: _D.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sale #${sale.id}',
                      style: _D.ts(13, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(dateStr, style: _D.ts(11, color: _D.inkMid)),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format((sale.total as num).toDouble()),
              style: _D.ts(14, weight: FontWeight.w800, color: _D.primary),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: _D.inkLight, size: 18),
          ],
        ),
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.sales});

  final List<dynamic> sales;

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) return const SizedBox.shrink();

    final values = sales.map<double>((s) => (s.total as num).toDouble()).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _D.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _D.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(values.length, (i) {
          final ratio = maxVal > 0 ? values[i] / maxVal : 0.0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                CurrencyFormatter.format(values[i])
                    .replaceAll(RegExp(r'[^\d]'), '')
                    .substring(0, 3) + '…',
                style: _D.ts(8, color: _D.inkMid),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: Duration(milliseconds: 400 + i * 80),
                width: 28,
                height: (80 * ratio).clamp(4.0, 80.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_D.primaryLt, _D.accent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text('#${sales[i].id}', style: _D.ts(9, color: _D.inkMid)),
            ],
          );
        }),
      ),
    );
  }
}

class _PaymentBreakdown extends StatelessWidget {
  const _PaymentBreakdown({required this.sales});

  final List<dynamic> sales;

  @override
  Widget build(BuildContext context) {
    final Map<String, double> breakdown = {};
    for (final s in sales) {
      final method = (s.paymentMethod as String? ?? 'unknown').toLowerCase();
      breakdown[method] = (breakdown[method] ?? 0) + (s.total as num);
    }

    final total = breakdown.values.fold(0.0, (a, b) => a + b);
    final colors = [_D.primary, _D.accent, _D.warn, _D.info, _D.danger];
    final entries = breakdown.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _D.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _D.cardShadow,
      ),
      child: Column(
        children: List.generate(entries.length, (i) {
          final pct = total > 0 ? entries[i].value / total : 0.0;
          final color = colors[i % colors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entries[i].key[0].toUpperCase() + entries[i].key.substring(1),
                          style: _D.ts(13, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      '${(pct * 100).toStringAsFixed(1)}%',
                      style: _D.ts(13, weight: FontWeight.w700, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _D.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _D.cardShadow,
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _D.ts(16, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: _D.ts(13, color: _D.inkMid)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _D.inkLight, size: 48),
            const SizedBox(height: 12),
            Text(message, style: _D.ts(14, color: _D.inkMid)),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _D.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: _D.danger, size: 28),
            ),
            const SizedBox(height: 12),
            Text('Something went wrong',
                style: _D.ts(15, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message,
                style: _D.ts(13, color: _D.inkMid),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _D.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryFAB extends StatelessWidget {
  const _PrimaryFAB({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: _D.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: Icon(icon, size: 20),
      label: Text(label,
          style: _D.ts(14, weight: FontWeight.w700, color: Colors.white)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TABS
// ════════════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.onReload});

  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onReload(),
      color: _D.primary,
      child: BlocBuilder<SalesBloc, SalesState>(
        builder: (context, state) {
          if (state is SalesLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _D.primary, strokeWidth: 2),
            );
          }

          if (state is SalesError) {
            return _ErrorBody(message: state.message, onRetry: onReload);
          }

          final sales = state is SalesLoaded ? state.sales : <dynamic>[];
          final now = DateTime.now();
          final today = sales.where((s) {
            try {
              return _isSameDay(DateTime.parse(s.createdAt), now);
            } catch (_) {
              return false;
            }
          }).toList();

          final totalRev = sales.fold(0.0, (s, i) => s + (i.total as num));
          final todayRev = today.fold(0.0, (s, i) => s + (i.total as num));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _GreetingBanner(salesCount: sales.length, todayCount: today.length),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _StatCard(title: "Today's Sales", value: today.length.toString(), icon: Icons.today_rounded, color: _D.primary),
                  _StatCard(title: "Today's Revenue", value: CurrencyFormatter.format(todayRev), icon: Icons.payments_rounded, color: _D.accent),
                  _StatCard(title: 'Total Sales', value: sales.length.toString(), icon: Icons.receipt_long_rounded, color: _D.info),
                  _StatCard(title: 'Total Revenue', value: CurrencyFormatter.format(totalRev), icon: Icons.account_balance_wallet_rounded, color: _D.warn),
                ],
              ),
              const SizedBox(height: 20),
              Text('Quick Actions', style: _D.ts(15, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _QuickAction(icon: Icons.point_of_sale_rounded, label: 'POS', color: _D.primary, onTap: () => context.push(RouteNames.pos))),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickAction(icon: Icons.history_rounded, label: 'Sales', color: _D.accent, onTap: () => context.push(RouteNames.sales))),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickAction(icon: Icons.inventory_2_outlined, label: 'Products', color: _D.info, onTap: () => context.push(RouteNames.sales))),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickAction(icon: Icons.people_outline_rounded, label: 'Users', color: _D.warn, onTap: () => context.push(RouteNames.settings))),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Sales', style: _D.ts(15, weight: FontWeight.w700)),
                  GestureDetector(
                    onTap: () => context.push(RouteNames.sales),
                    child: Text('See all', style: _D.ts(13, weight: FontWeight.w600, color: _D.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (sales.isEmpty)
                const _EmptyState(icon: Icons.receipt_outlined, message: 'No sales recorded yet')
              else
                ...sales.take(5).map((s) => _SaleRow(
                      sale: s,
                      onTap: () => context.push('${RouteNames.sales}/${s.id}'),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab({required this.onReload});

  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onReload(),
      color: _D.primary,
      child: BlocBuilder<SalesBloc, SalesState>(
        builder: (context, state) {
          if (state is SalesLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _D.primary, strokeWidth: 2),
            );
          }
          if (state is SalesError) {
            return _ErrorBody(message: state.message, onRetry: onReload);
          }

          final sales = state is SalesLoaded ? state.sales : <dynamic>[];
          if (sales.isEmpty) {
            return const _EmptyState(icon: Icons.bar_chart_rounded, message: 'No analytics data yet');
          }

          final totalRev = sales.fold(0.0, (s, i) => s + (i.total as num));
          final avgOrder = sales.isEmpty ? 0.0 : totalRev / sales.length;
          final maxSale = sales.map<double>((s) => (s.total as num).toDouble()).reduce((a, b) => a > b ? a : b);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _StatCard(title: 'Total Revenue', value: CurrencyFormatter.format(totalRev), icon: Icons.attach_money_rounded, color: _D.accent),
                  _StatCard(title: 'Total Transactions', value: sales.length.toString(), icon: Icons.receipt_rounded, color: _D.primary),
                  _StatCard(title: 'Avg Order Value', value: CurrencyFormatter.format(avgOrder), icon: Icons.trending_up_rounded, color: _D.warn),
                  _StatCard(title: 'Largest Sale', value: CurrencyFormatter.format(maxSale), icon: Icons.star_outline_rounded, color: _D.info),
                ],
              ),
              const SizedBox(height: 20),
              Text('Revenue — Last ${sales.length > 7 ? 7 : sales.length} Sales',
                  style: _D.ts(15, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              _MiniBarChart(sales: sales.take(7).toList().reversed.toList()),
              const SizedBox(height: 20),
              Text('Payment Methods', style: _D.ts(15, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              _PaymentBreakdown(sales: sales),
            ],
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HELPER
// ════════════════════════════════════════════════════════════════════════════
bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;