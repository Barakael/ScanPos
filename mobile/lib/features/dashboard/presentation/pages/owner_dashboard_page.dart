import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/stats_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../analytics/presentation/bloc/analytics_bloc.dart';
import '../../../products/presentation/bloc/products_bloc.dart';
import '../../../sales/presentation/bloc/sales_bloc.dart';
import '../../../sales/presentation/bloc/sales_event.dart';
import '../../../sales/presentation/bloc/sales_state.dart';
import '../widgets/recent_sales_widget.dart';
import '../widgets/low_stock_alert_widget.dart';
import '../widgets/sales_chart_widget.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage>
    with SingleTickerProviderStateMixin {
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

  // FIX: must return Future<void> for RefreshIndicator.onRefresh
  Future<void> _loadData() async {
    context.read<AnalyticsBloc>().add(const AnalyticsFetchRequested());
    context.read<ProductsBloc>().add(const ProductsFetchRequested());
    // FIX: removed const — SalesFetchRequested has non-const params
    context.read<SalesBloc>().add(const SalesFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.white),
            onPressed: () => context.push(RouteNames.settings),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAnalyticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.createSale),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildStatsSection(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildSalesChart(),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: LowStockAlertWidget(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const RecentSalesWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is AnalyticsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is AnalyticsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading analytics',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // FIX: use label instead of text, remove variant param
                AppButton(
                  label: 'Retry',
                  onPressed: _loadData,
                ),
              ],
            ),
          );
        } else if (state is AnalyticsLoaded) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildRevenueChart(state.analytics),
                const SizedBox(height: 24),
                _buildCategorySalesChart(state.analytics),
                const SizedBox(height: 24),
                _buildTopProductsSection(state.analytics),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      (Icons.point_of_sale, 'New Sale', RouteNames.createSale, AppColors.primary),
      (Icons.inventory_2_outlined, 'Inventory', RouteNames.inventory, AppColors.accent),
      (Icons.receipt_long_outlined, 'Sales History', RouteNames.sales, AppColors.warning),
      (Icons.assessment_outlined, 'Reports', RouteNames.reports, AppColors.info),
      (Icons.badge_outlined, 'Staff', RouteNames.staff, AppColors.success),
      (Icons.store_outlined, 'Store Settings', RouteNames.settings, AppColors.grey400),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: actions
              .map((action) => _QuickActionCard(
                    icon: action.$1,
                    label: action.$2,
                    color: action.$4,
                    onTap: () => context.push(action.$3),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return MultiBlocListener(
      listeners: [
        BlocListener<AnalyticsBloc, AnalyticsState>(listener: (context, state) {}),
        BlocListener<ProductsBloc, ProductsState>(listener: (context, state) {}),
        BlocListener<SalesBloc, SalesState>(listener: (context, state) {}),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              BlocBuilder<AnalyticsBloc, AnalyticsState>(
                builder: (context, state) {
                  final todaySales =
                      state is AnalyticsLoaded ? state.analytics.todaySales ?? 0 : 0;
                  final todayRevenue =
                      state is AnalyticsLoaded ? state.analytics.todayRevenue ?? 0 : 0;
                  return StatsCard(
                    title: 'Today\'s Sales',
                    value: todaySales.toString(),
                    subtitle: CurrencyFormatter.format(todayRevenue),
                    icon: Icons.receipt_outlined,
                    color: AppColors.primary,
                  );
                },
              ),
              BlocBuilder<ProductsBloc, ProductsState>(
                builder: (context, state) {
                  final totalProducts =
                      state is ProductsLoaded ? state.products.length : 0;
                  // FIX: null-safe comparison with ?? 10
                  final lowStockCount = state is ProductsLoaded
                      ? state.products
                          .where((p) => p.stock <= (p.lowStockThreshold ?? 10))
                          .length
                      : 0;
                  return StatsCard(
                    title: 'Products',
                    value: totalProducts.toString(),
                    subtitle: '$lowStockCount low stock',
                    icon: Icons.inventory_2_outlined,
                    color: lowStockCount > 0 ? AppColors.warning : AppColors.success,
                  );
                },
              ),
              BlocBuilder<SalesBloc, SalesState>(
                builder: (context, state) {
                  final transactions =
                      state is SalesLoaded ? state.sales.length : 0;
                  return StatsCard(
                    title: 'Transactions',
                    value: transactions.toString(),
                    icon: Icons.swap_horiz_outlined,
                    color: AppColors.accent,
                  );
                },
              ),
              StatsCard(
                title: 'Revenue',
                value: CurrencyFormatter.format(0),
                icon: Icons.attach_money,
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Sales',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: SalesChartWidget()),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(dynamic analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Trend',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getRevenueSpots(analytics),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySalesChart(dynamic analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales by Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(sections: _getCategorySections(analytics)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsSection(dynamic analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Products',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Top products will be displayed here'),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getRevenueSpots(dynamic analytics) {
    return [
      const FlSpot(0, 1000),
      const FlSpot(1, 1500),
      const FlSpot(2, 1200),
      const FlSpot(3, 1800),
      const FlSpot(4, 2000),
      const FlSpot(5, 1700),
      const FlSpot(6, 2200),
    ];
  }

  List<PieChartSectionData> _getCategorySections(dynamic analytics) {
    return [
      PieChartSectionData(value: 30, color: AppColors.primary, title: '30%'),
      PieChartSectionData(value: 25, color: AppColors.accent, title: '25%'),
      PieChartSectionData(value: 20, color: AppColors.success, title: '20%'),
      PieChartSectionData(value: 15, color: AppColors.warning, title: '15%'),
      PieChartSectionData(value: 10, color: AppColors.info, title: '10%'),
    ];
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
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
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}