import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../analytics/presentation/bloc/analytics_bloc.dart';
import '../../../analytics/domain/entities/analytics_entity.dart';
import '../../../sales/presentation/bloc/sales_bloc.dart';
import '../../../sales/presentation/bloc/sales_event.dart';
import '../../../sales/presentation/bloc/sales_state.dart';

// ════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS — mirrors POS page _T class exactly
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

  static Color primaryOpacity(double o) => primary.withOpacity(o);
  static Color whiteOpacity(double o)   => white.withOpacity(o);
  static Color accentOpacity(double o)  => accent.withOpacity(o);
}

// ════════════════════════════════════════════════════════════════════════════
// REPORTS PAGE
// ════════════════════════════════════════════════════════════════════════════
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  String _selectedPeriod = 'Today';
  String _selectedReport = 'Sales';

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
    _animController.forward();
    _fetchDataForPeriod();
  }

  void _fetchDataForPeriod() {
    String? dateFilter;
    switch (_selectedPeriod) {
      case 'Today':
        final now = DateTime.now();
        dateFilter =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        break;
      case 'Yesterday':
        final y = DateTime.now().subtract(const Duration(days: 1));
        dateFilter =
            '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
        break;
      default:
        dateFilter = null;
    }
    context.read<AnalyticsBloc>().add(const AnalyticsFetchRequested());
    context.read<SalesBloc>().add(SalesFetchRequested(date: dateFilter));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  String _formatTime(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM dd').format(dt);
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
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: _T.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              expandedHeight: 110,
              surfaceTintColor: Colors.transparent,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reports',
                        style: _T.ts(20,
                            weight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 2),
                    Text('Analytics & insights',
                        style: _T.ts(11, color: Colors.white60)),
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
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => _showExportSheet(context),
                    child: Container(
                      height: 34,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: _T.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.download_rounded,
                              size: 15, color: Colors.white),
                          const SizedBox(width: 5),
                          Text('Export',
                              style: _T.ts(13,
                                  weight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Filter Strip ───────────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterBarDelegate(
                selectedPeriod: _selectedPeriod,
                selectedReport: _selectedReport,
                onPeriodChanged: (v) {
                  setState(() => _selectedPeriod = v);
                  _fetchDataForPeriod();
                },
                onReportChanged: (v) =>
                    setState(() => _selectedReport = v),
              ),
            ),

            // ── Body ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Summary Stats ─────────────────────────────
                      _SectionLabel(label: 'Summary'),
                      const SizedBox(height: 12),
                      BlocBuilder<AnalyticsBloc, AnalyticsState>(
                        builder: (context, state) {
                          if (state is AnalyticsLoading) {
                            return const _CardShimmer(height: 180);
                          }
                          if (state is AnalyticsError) {
                            return const _EmptyAnalyticsCard();
                          }
                          if (state is AnalyticsLoaded) {
                            return _StatsGrid(analytics: state.analytics);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── Revenue Trend Chart ───────────────────────
                      _SectionLabel(label: 'Revenue Trend'),
                      const SizedBox(height: 12),
                      BlocBuilder<AnalyticsBloc, AnalyticsState>(
                        builder: (context, state) {
                          if (state is AnalyticsLoading) {
                            return const _CardShimmer(height: 220);
                          }
                          if (state is AnalyticsError) {
                            return const _EmptyChartCard(
                                label: 'No revenue data');
                          }
                          if (state is AnalyticsLoaded) {
                            return _LineChartCard(
                              dailySales: state.analytics.dailySales,
                              animController: _animController,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── Sales Volume Bar Chart ────────────────────
                      _SectionLabel(label: 'Sales Volume'),
                      const SizedBox(height: 12),
                      BlocBuilder<AnalyticsBloc, AnalyticsState>(
                        builder: (context, state) {
                          if (state is AnalyticsLoading) {
                            return const _CardShimmer(height: 200);
                          }
                          if (state is AnalyticsError) {
                            return const _EmptyChartCard(
                                label: 'No sales volume data');
                          }
                          if (state is AnalyticsLoaded) {
                            return _BarChartCard(
                              dailySales: state.analytics.dailySales,
                              animController: _animController,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── Key Metrics Row ───────────────────────────
                      BlocBuilder<AnalyticsBloc, AnalyticsState>(
                        builder: (context, state) {
                          if (state is AnalyticsLoaded) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionLabel(label: 'Performance'),
                                const SizedBox(height: 12),
                                _MetricsRow(analytics: state.analytics),
                                const SizedBox(height: 24),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // ── Recent Transactions ───────────────────────
                      Row(
                        children: [
                          const _SectionLabel(label: 'Recent Transactions'),
                          const Spacer(),
                          Text('View all',
                              style: _T.ts(12,
                                  color: _T.primary,
                                  weight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<SalesBloc, SalesState>(
                        builder: (context, state) {
                          if (state is SalesLoading) {
                            return const _CardShimmer(height: 200);
                          }
                          if (state is SalesError) {
                            return _EmptyCard(
                                message: 'Unable to load transactions');
                          }
                          if (state is SalesLoaded) {
                            final sales = state.sales.take(5).toList();
                            if (sales.isEmpty) {
                              return const _EmptyCard(
                                  message: 'No transactions found');
                            }
                            return _TransactionCard(sales: sales);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 100),
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

  void _showExportSheet(BuildContext context) {
    String selected = 'PDF';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: BoxDecoration(
            color: _T.card,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
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
                    color: _T.inkLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _T.accentSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(Icons.download_rounded,
                        color: _T.accent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Export Report',
                          style: _T.ts(17, weight: FontWeight.w800)),
                      Text('Choose a format',
                          style: _T.ts(11, color: _T.inkMid)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...['PDF', 'Excel', 'CSV'].map((fmt) {
                final isSelected = selected == fmt;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => setSheet(() => selected = fmt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _T.primaryOpacity(0.07)
                            : _T.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _T.primary : _T.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            fmt == 'PDF'
                                ? Icons.picture_as_pdf_rounded
                                : fmt == 'Excel'
                                    ? Icons.table_chart_rounded
                                    : Icons.code_rounded,
                            color: isSelected ? _T.primary : _T.inkMid,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            fmt,
                            style: _T.ts(14,
                                weight: FontWeight.w600,
                                color: isSelected
                                    ? _T.primary
                                    : _T.inkMid),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: _T.primary, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.white,
                                size: 16),
                            const SizedBox(width: 8),
                            const Text('Report exported successfully'),
                          ],
                        ),
                        backgroundColor: _T.accent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Export Now'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _T.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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

// ─── Filter Bar Delegate ──────────────────────────────────────────────────────
class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final String selectedPeriod;
  final String selectedReport;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<String> onReportChanged;

  const _FilterBarDelegate({
    required this.selectedPeriod,
    required this.selectedReport,
    required this.onPeriodChanged,
    required this.onReportChanged,
  });

  @override
  double get minExtent => 96;
  @override
  double get maxExtent => 96;
  @override
  bool shouldRebuild(_FilterBarDelegate old) =>
      old.selectedPeriod != selectedPeriod ||
      old.selectedReport != selectedReport;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _T.bg,
      child: Column(
        children: [
          // Period row
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              children: [
                'Today',
                'Yesterday',
                'This Week',
                'This Month',
                'This Year',
              ].map((p) {
                final isSelected = selectedPeriod == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onPeriodChanged(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? _T.primary : _T.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? _T.primary : _T.border,
                        ),
                      ),
                      child: Text(
                        p,
                        style: _T.ts(12,
                            weight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : _T.inkMid),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Report type row
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              children: [
                'Sales',
                'Products',
                'Staff',
                'Shops',
                'Customers',
              ].map((r) {
                final isSelected = selectedReport == r;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onReportChanged(r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _T.accentSoft
                            : _T.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? _T.accent : _T.border,
                        ),
                      ),
                      child: Text(
                        r,
                        style: _T.ts(12,
                            weight: FontWeight.w600,
                            color: isSelected ? _T.accent : _T.inkMid),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: _T.ts(15, weight: FontWeight.w700));
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final AnalyticsEntity analytics;
  const _StatsGrid({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                title: 'Revenue',
                value: '\$${analytics.totalRevenue.toStringAsFixed(0)}',
                icon: Icons.attach_money_rounded,
                color: _T.accent,
                bg: _T.accentSoft,
                change: '+12.5%',
                positive: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                title: 'Sales',
                value: analytics.totalSales.toString(),
                icon: Icons.shopping_bag_rounded,
                color: _T.primary,
                bg: _T.primaryOpacity(0.1),
                change: '+8.2%',
                positive: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                title: 'Avg Order',
                value:
                    '\$${analytics.averageOrderValue.toStringAsFixed(0)}',
                icon: Icons.receipt_long_rounded,
                color: _T.warn,
                bg: _T.warnSoft,
                change: '-2.1%',
                positive: false,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                title: 'Customers',
                value: analytics.totalCustomers.toString(),
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF7B68EE),
                bg: const Color(0x1F7B68EE),
                change: '+15.3%',
                positive: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  final String change;
  final bool positive;

  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
    required this.change,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.border),
        boxShadow: _T.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: positive ? _T.accentSoft : _T.dangerSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  change,
                  style: _T.ts(10,
                      weight: FontWeight.w600,
                      color: positive ? _T.accent : _T.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: _T.ts(22, weight: FontWeight.w800, height: 1.1)),
          const SizedBox(height: 2),
          Text(title, style: _T.ts(11, color: _T.inkMid, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Line Chart Card ──────────────────────────────────────────────────────────
class _LineChartCard extends StatelessWidget {
  final List<DailySalesEntity> dailySales;
  final AnimationController animController;

  const _LineChartCard({
    required this.dailySales,
    required this.animController,
  });

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
          Row(
            children: [
              Text('Last 7 Days',
                  style: _T.ts(13, weight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: _T.accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Revenue',
                    style: _T.ts(10,
                        color: _T.accent, weight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Y-axis labels + chart
          SizedBox(
            height: 180,
            child: Row(
              children: [
                // Y-axis
                SizedBox(
                  width: 44,
                  child: AnimatedBuilder(
                    animation: animController,
                    builder: (_, __) => _YAxisLabels(
                      dailySales: dailySales,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: AnimatedBuilder(
                    animation: animController,
                    builder: (_, __) => CustomPaint(
                      painter: _LineChartPainter(
                        dailySales: dailySales,
                        progress: animController.value,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // X-axis labels
          _XAxisLabels(dailySales: dailySales),
        ],
      ),
    );
  }
}

class _YAxisLabels extends StatelessWidget {
  final List<DailySalesEntity> dailySales;
  const _YAxisLabels({required this.dailySales});

  @override
  Widget build(BuildContext context) {
    if (dailySales.isEmpty) return const SizedBox.shrink();
    final maxRevenue = dailySales
        .map((d) => d.revenue)
        .reduce((a, b) => a > b ? a : b);
    if (maxRevenue == 0) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(_formatY(maxRevenue),
            style: TextStyle(fontSize: 9, color: _T.inkMid)),
        Text(_formatY(maxRevenue * 0.75),
            style: TextStyle(fontSize: 9, color: _T.inkMid)),
        Text(_formatY(maxRevenue * 0.5),
            style: TextStyle(fontSize: 9, color: _T.inkMid)),
        Text(_formatY(maxRevenue * 0.25),
            style: TextStyle(fontSize: 9, color: _T.inkMid)),
        Text('0', style: TextStyle(fontSize: 9, color: _T.inkMid)),
      ],
    );
  }

  String _formatY(double v) {
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
    return '\$${v.toStringAsFixed(0)}';
  }
}

class _XAxisLabels extends StatelessWidget {
  final List<DailySalesEntity> dailySales;
  const _XAxisLabels({required this.dailySales});

  @override
  Widget build(BuildContext context) {
    if (dailySales.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: dailySales.map((d) {
          String label = '';
          if (d.date != null) {
            try {
              final dt = d.date is DateTime
                  ? d.date as DateTime
                  : DateTime.tryParse(d.date.toString());
              if (dt != null) label = DateFormat('E').format(dt);
            } catch (_) {}
          }
          return Text(label,
              style: TextStyle(fontSize: 9, color: _T.inkMid));
        }).toList(),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<DailySalesEntity> dailySales;
  final double progress;

  _LineChartPainter({required this.dailySales, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (dailySales.isEmpty) return;

    final maxRevenue = dailySales
        .map((d) => d.revenue)
        .reduce((a, b) => a > b ? a : b);
    if (maxRevenue == 0) return;

    // Grid lines
    final gridPaint = Paint()
      ..color = _T.border
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height - (i / 4) * size.height * 0.9;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final count = dailySales.length;
    final points = <Offset>[];
    for (int i = 0; i < count; i++) {
      final x = count > 1
          ? (i / (count - 1)) * size.width
          : size.width / 2;
      final y = size.height -
          (dailySales[i].revenue / maxRevenue) * size.height * 0.9;
      points.add(Offset(x, y));
    }

    final visibleCount =
        (points.length * progress).ceil().clamp(1, points.length);
    final visible = points.sublist(0, visibleCount);

    // Fill gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _T.accent.withOpacity(0.18),
          _T.accent.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final fillPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(visible.first.dx, visible.first.dy);
    for (int i = 1; i < visible.length; i++) {
      // smooth curve
      final prev = visible[i - 1];
      final curr = visible[i];
      final cp1 = Offset((prev.dx + curr.dx) / 2, prev.dy);
      final cp2 = Offset((prev.dx + curr.dx) / 2, curr.dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
    }
    fillPath.lineTo(visible.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = _T.accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()
      ..moveTo(visible.first.dx, visible.first.dy);
    for (int i = 1; i < visible.length; i++) {
      final prev = visible[i - 1];
      final curr = visible[i];
      final cp1 = Offset((prev.dx + curr.dx) / 2, prev.dy);
      final cp2 = Offset((prev.dx + curr.dx) / 2, curr.dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    for (final p in visible) {
      canvas.drawCircle(
          p, 5, Paint()..color = _T.white..style = PaintingStyle.fill);
      canvas.drawCircle(
          p,
          5,
          Paint()
            ..color = _T.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.progress != progress;
}

// ─── Bar Chart Card ───────────────────────────────────────────────────────────
class _BarChartCard extends StatelessWidget {
  final List<DailySalesEntity> dailySales;
  final AnimationController animController;

  const _BarChartCard({
    required this.dailySales,
    required this.animController,
  });

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
          Row(
            children: [
              Text('Daily Orders',
                  style: _T.ts(13, weight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: _T.primaryOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Count',
                    style: _T.ts(10,
                        color: _T.primary, weight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y-axis
                SizedBox(
                  width: 28,
                  child: _BarYAxis(dailySales: dailySales),
                ),
                const SizedBox(width: 8),
                // Bars
                Expanded(
                  child: AnimatedBuilder(
                    animation: animController,
                    builder: (_, __) => _BarChartBars(
                      dailySales: dailySales,
                      progress: animController.value,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _XAxisLabels(dailySales: dailySales),
        ],
      ),
    );
  }
}

class _BarYAxis extends StatelessWidget {
  final List<DailySalesEntity> dailySales;
  const _BarYAxis({required this.dailySales});

  @override
  Widget build(BuildContext context) {
    if (dailySales.isEmpty) return const SizedBox.shrink();
    final maxSales = dailySales
        .map((d) => d.count)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    if (maxSales == 0) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(maxSales.toInt().toString(),
            style: TextStyle(fontSize: 9, color: _T.inkMid)),
        Text((maxSales * 0.5).toInt().toString(),
            style: TextStyle(fontSize: 9, color: _T.inkMid)),
        const Text('0', style: TextStyle(fontSize: 9, color: _T.inkMid)),
      ],
    );
  }
}

class _BarChartBars extends StatelessWidget {
  final List<DailySalesEntity> dailySales;
  final double progress;
  const _BarChartBars(
      {required this.dailySales, required this.progress});

  @override
  Widget build(BuildContext context) {
    if (dailySales.isEmpty) return const SizedBox.shrink();
    final maxSales = dailySales
        .map((d) => d.count)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    if (maxSales == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (_, constraints) {
        final barW =
            (constraints.maxWidth - (dailySales.length - 1) * 6) /
                dailySales.length;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: dailySales.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            final ratio =
                (d.count / maxSales * progress).clamp(0.0, 1.0);
            final barH = constraints.maxHeight * ratio;
            final isLast = i == dailySales.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: barW,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: barH > 0 ? barH : 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              _T.primary,
                              _T.primaryLt,
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const SizedBox(width: 6),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Metrics Row ──────────────────────────────────────────────────────────────
class _MetricsRow extends StatelessWidget {
  final AnalyticsEntity analytics;
  const _MetricsRow({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'Conversion',
            value: '68%',
            icon: Icons.trending_up_rounded,
            color: _T.accent,
            bg: _T.accentSoft,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            label: 'Return Rate',
            value: '3.2%',
            icon: Icons.undo_rounded,
            color: _T.danger,
            bg: _T.dangerSoft,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            label: 'Growth',
            value: '+14%',
            icon: Icons.rocket_launch_rounded,
            color: _T.warn,
            bg: _T.warnSoft,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.border),
        boxShadow: _T.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 8),
          Text(value,
              style: _T.ts(16, weight: FontWeight.w800, height: 1.1)),
          const SizedBox(height: 2),
          Text(label,
              style: _T.ts(10,
                  color: _T.inkMid, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Transaction Card ─────────────────────────────────────────────────────────
class _TransactionCard extends StatelessWidget {
  final List<dynamic> sales;
  const _TransactionCard({required this.sales});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border),
        boxShadow: _T.cardShadow,
      ),
      child: Column(
        children: sales.asMap().entries.map((entry) {
          final i = entry.key;
          final sale = entry.value;
          final isLast = i == sales.length - 1;
          return Column(
            children: [
              _TxRow(sale: sale, index: i),
              if (!isLast) Divider(height: 1, color: _T.border),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final dynamic sale;
  final int index;
  const _TxRow({required this.sale, required this.index});

  @override
  Widget build(BuildContext context) {
    final status = (sale.status ?? 'completed') as String;
    Color statusColor;
    Color statusBg;
    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = _T.accent;
        statusBg = _T.accentSoft;
        break;
      case 'pending':
        statusColor = _T.warn;
        statusBg = _T.warnSoft;
        break;
      default:
        statusColor = _T.danger;
        statusBg = _T.dangerSoft;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _T.primaryOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '#${index + 1}',
                style: _T.ts(11,
                    weight: FontWeight.w700, color: _T.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.customerName ?? 'Unknown Customer',
                  style: _T.ts(13, weight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text('#TRX${sale.id ?? index + 1}',
                    style: _T.ts(10, color: _T.inkMid)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${(sale.total ?? 0.0).toStringAsFixed(2)}',
                style: _T.ts(13, weight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: _T.ts(10,
                      weight: FontWeight.w600, color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Utility Widgets ──────────────────────────────────────────────────────────
class _CardShimmer extends StatelessWidget {
  final double height;
  const _CardShimmer({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border),
        boxShadow: _T.cardShadow,
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: _T.primary, strokeWidth: 2),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border),
        boxShadow: _T.cardShadow,
      ),
      child: Center(
        child: Text(message,
            style: _T.ts(13, color: _T.inkMid)),
      ),
    );
  }
}

class _EmptyAnalyticsCard extends StatelessWidget {
  const _EmptyAnalyticsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border),
        boxShadow: _T.cardShadow,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: _T.inkLight),
            const SizedBox(height: 12),
            Text('No analytics data available',
                style: _T.ts(13, color: _T.inkMid),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Start making sales to see your analytics',
                style: _T.ts(11, color: _T.inkLight),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _EmptyChartCard extends StatelessWidget {
  final String label;
  const _EmptyChartCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border),
        boxShadow: _T.cardShadow,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_chart_outlined, size: 48, color: _T.inkLight),
            const SizedBox(height: 12),
            Text(label,
                style: _T.ts(13, color: _T.inkMid),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Sales trends will appear here once you have data',
                style: _T.ts(11, color: _T.inkLight),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}