import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../sales/presentation/bloc/sales_bloc.dart';
import '../../../sales/presentation/bloc/sales_event.dart';
import '../../../sales/presentation/bloc/sales_state.dart';
import '../widgets/stats_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    // Load sales data for dashboard with delay to prevent blocking
    Future.microtask(() {
      context.read<SalesBloc>().add(const SalesFetchRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Show different dashboard based on user role
        if (authState is AuthAuthenticated) {
          final role = authState.user.roleName.toLowerCase();
          if (role == 'owner' ||
              role == 'business owner' ||
              role == 'super_admin') {
            return _buildOwnerDashboard(context);
          } else if (role == 'cashier') {
            return _buildCashierDashboard(context);
          } else {
            return _buildDefaultDashboard(context);
          }
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildOwnerDashboard(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final name = state is AuthAuthenticated
                ? 'Welcome, ${state.user.firstName}'
                : 'Owner Dashboard';
            return Text(name);
          },
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withAlpha(150),
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics_outlined)),
          ],
        ),
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final role = state is AuthAuthenticated
                  ? state.user.roleName.toLowerCase()
                  : '';
              if (role != 'owner' && role != 'business owner') {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon:
                    const Icon(Icons.settings_outlined, color: AppColors.white),
                onPressed: () => context.push(RouteNames.settings),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: TabBarView(
        children: [
          _buildOverviewTab(context),
          _buildAnalyticsTab(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.createSale),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildCashierDashboard(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final name = state is AuthAuthenticated
                ? 'Welcome, ${state.user.firstName}'
                : 'POS Dashboard';
            return Text(name);
          },
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.point_of_sale,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'POS Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quick access to Point of Sale',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push(RouteNames.pos),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Go to POS'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.pos),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.point_of_sale, color: AppColors.white),
      ),
    );
  }

  Widget _buildDefaultDashboard(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final name = state is AuthAuthenticated
                ? 'Welcome, ${state.user.firstName}'
                : 'Dashboard';
            return Text(name);
          },
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.dashboard,
              size: 64,
              color: AppColors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your role from the login screen',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                if (authState is AuthAuthenticated) {
                  final hour = DateTime.now().hour;
                  final greeting = hour < 12 ? 'Good morning' : 'Good afternoon';
                  final firstName = authState.user.firstName.split(' ')[0];
                  
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, $firstName!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Here's your business overview",
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            
            const SizedBox(height: 24),
            
            // Stats Grid (matching frontend) - Simplified for performance
            _buildQuickStats(),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, salesState) {
        int todaySales = 0;
        double todayTotal = 0;
        
        if (salesState is SalesLoaded) {
          final today = DateTime.now();
          todaySales = salesState.sales
              .where((s) => _isSameDay(s.createdAt, today))
              .length;
          todayTotal = salesState.sales
              .where((s) => _isSameDay(s.createdAt, today))
              .fold(0.0, (sum, s) => sum + s.total);
        }
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              context,
              title: "Today's Sales",
              value: CurrencyFormatter.format(todayTotal),
              change: '+12.5%',
              isPositive: true,
              icon: Icons.attach_money,
              color: AppColors.warning,
            ),
            _buildStatCard(
              context,
              title: 'Transactions',
              value: todaySales.toString(),
              change: '+8.2%',
              isPositive: true,
              icon: Icons.receipt_long,
              color: AppColors.info,
            ),
            _buildStatCard(
              context,
              title: 'Products',
              value: '0',
              subtitle: '0 units',
              change: null,
              isPositive: true,
              icon: Icons.inventory_2,
              color: AppColors.primary,
            ),
            _buildStatCard(
              context,
              title: 'Low Stock',
              value: '0',
              change: 'Needs attention',
              isPositive: false,
              icon: Icons.warning,
              color: AppColors.error,
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _QuickActionCard(
              icon: Icons.point_of_sale,
              title: 'New Sale',
              color: AppColors.success,
              onTap: () => context.push(RouteNames.createSale),
            ),
            _QuickActionCard(
              icon: Icons.inventory,
              title: 'Inventory',
              color: AppColors.primary,
              onTap: () => context.push(RouteNames.inventory),
            ),
            _QuickActionCard(
              icon: Icons.assessment_outlined,
              title: 'Reports',
              color: AppColors.warning,
              onTap: () => context.push(RouteNames.reports),
            ),
            _QuickActionCard(
              icon: Icons.receipt_long,
              title: 'Sales',
              color: AppColors.accent,
              onTap: () => context.push(RouteNames.sales),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    String? change,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: color.withAlpha(180),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (change != null) ...[
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPositive ? AppColors.success : AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isPositive ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(List<dynamic> sales) {
    // Simple chart implementation matching frontend style
    return Container(
      height: 200,
      child: const Center(
        child: Text(
          '📊 Sales Chart\n(Coming Soon)',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.grey500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Stats - Simplified
            BlocBuilder<SalesBloc, SalesState>(
              builder: (context, state) {
                if (state is SalesLoaded && state.sales.isNotEmpty) {
                  final totalRevenue = state.sales.fold(0.0, (sum, s) => sum + s.total);
                  final avgOrderValue = totalRevenue / state.sales.length;
                  
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        context,
                        title: 'Total Revenue',
                        value: CurrencyFormatter.format(totalRevenue),
                        change: null,
                        isPositive: true,
                        icon: Icons.attach_money,
                        color: AppColors.success,
                      ),
                      _buildStatCard(
                        context,
                        title: 'Total Sales',
                        value: state.sales.length.toString(),
                        change: null,
                        isPositive: true,
                        icon: Icons.receipt,
                        color: AppColors.primary,
                      ),
                      _buildStatCard(
                        context,
                        title: 'Products',
                        value: '0',
                        subtitle: '0 units',
                        change: null,
                        isPositive: true,
                        icon: Icons.inventory_2,
                        color: AppColors.accent,
                      ),
                      _buildStatCard(
                        context,
                        title: 'Avg Order Value',
                        value: CurrencyFormatter.format(avgOrderValue),
                        change: null,
                        isPositive: true,
                        icon: Icons.trending_up,
                        color: AppColors.warning,
                      ),
                    ],
                  );
                } else if (state is SalesLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return const Center(child: Text('No sales data'));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
