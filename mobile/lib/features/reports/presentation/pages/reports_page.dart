import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../analytics/presentation/bloc/analytics_bloc.dart';
import '../../../analytics/domain/entities/analytics_entity.dart';
import '../../../sales/presentation/bloc/sales_bloc.dart';
import '../../../sales/presentation/bloc/sales_event.dart';
import '../../../sales/presentation/bloc/sales_state.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  String _selectedPeriod = 'Today';
  String _selectedReport = 'Sales';

  // ── Palette (shared design system) ──────────────────────────────────────
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
  static const _amberSoft  = Color(0x1FFF9F43);

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
    context.read<AnalyticsBloc>().add(const AnalyticsFetchRequested());
    context.read<SalesBloc>().add(const SalesFetchRequested());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: _surface,
              foregroundColor: _ink,
              elevation: 0,
              pinned: true,
              expandedHeight: 110,
              surfaceTintColor: Colors.transparent,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                title: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Analytics & insights',
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
                    border: Border(bottom: BorderSide(color: _border)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: _teal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download_rounded, size: 15, color: _void),
                          SizedBox(width: 5),
                          Text(
                            'Export',
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
            ),

            // ── Filter Strip ───────────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterBarDelegate(
                selectedPeriod: _selectedPeriod,
                selectedReport: _selectedReport,
                onPeriodChanged: (v) => setState(() => _selectedPeriod = v),
                onReportChanged: (v) => setState(() => _selectedReport = v),
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
                      // Summary Stats
                      _SectionLabel(label: 'Summary'),
                      const SizedBox(height: 12),
                      BlocBuilder<AnalyticsBloc, AnalyticsState>(
                        builder: (context, state) {
                          if (state is AnalyticsLoading) {
                            return const _CardShimmer(height: 180);
                          }
                          if (state is AnalyticsError) {
                            return _InlineError(message: state.message);
                          }
                          if (state is AnalyticsLoaded) {
                            final a = state.analytics;
                            return _StatsGrid(analytics: a);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 24),

                      // Chart
                      _SectionLabel(label: 'Sales Trend'),
                      const SizedBox(height: 12),
                      BlocBuilder<AnalyticsBloc, AnalyticsState>(
                        builder: (context, state) {
                          if (state is AnalyticsLoading) {
                            return const _CardShimmer(height: 200);
                          }
                          if (state is AnalyticsError) {
                            return _InlineError(message: state.message);
                          }
                          if (state is AnalyticsLoaded) {
                            return _ChartCard(
                              dailySales: state.analytics.dailySales,
                              animController: _animController,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 24),

                      // Transactions
                      Row(
                        children: [
                          const _SectionLabel(label: 'Recent Transactions'),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              'View all',
                              style: TextStyle(
                                fontSize: 12,
                                color: _indigo,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<SalesBloc, SalesState>(
                        builder: (context, state) {
                          if (state is SalesLoading) {
                            return const _CardShimmer(height: 200);
                          }
                          if (state is SalesError) {
                            return _InlineError(message: state.message);
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
          decoration: const BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: _tealSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.download_rounded,
                        color: _teal, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Export Report',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          )),
                      Text('Choose a format',
                          style: TextStyle(fontSize: 11, color: _inkDim)),
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
                        color: isSelected ? _goldSoft : _panel,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _gold : _border,
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
                            color: isSelected ? _gold : _inkMid,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            fmt,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? _gold : _inkMid,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded,
                                color: _gold, size: 18),
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
                          children: const [
                            Icon(Icons.check_circle_outline_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text('Report exported successfully'),
                          ],
                        ),
                        backgroundColor: _teal,
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
                    backgroundColor: _gold,
                    foregroundColor: _void,
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

  String _formatTime(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM dd').format(dt);
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

  static const _void    = Color(0xFF09090F);
  static const _panel   = Color(0xFF16161F);
  static const _border  = Color(0x18FFFFFF);
  static const _gold    = Color(0xFFF5C842);
  static const _ink     = Color(0xFFF0F0FF);
  static const _inkMid  = Color(0xFF8B8BA8);

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
      color: _void,
      child: Column(
        children: [
          // Period row
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children:
                  ['Today', 'Yesterday', 'This Week', 'This Month', 'This Year']
                      .map((p) {
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
                        color: isSelected ? _gold : _panel,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSelected ? _gold : _border),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? _void : _inkMid,
                        ),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: ['Sales', 'Products', 'Staff', 'Shops', 'Customers']
                  .map((r) {
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
                            ? const Color(0x1F7B68EE)
                            : _panel,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF7B68EE)
                              : _border,
                        ),
                      ),
                      child: Text(
                        r,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF7B68EE)
                              : _inkMid,
                        ),
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
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFFF0F0FF),
      ),
    );
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
                value:
                    '\$${analytics.totalRevenue.toStringAsFixed(0)}',
                icon: Icons.attach_money_rounded,
                color: const Color(0xFF00D9A3),
                bg: const Color(0x1A00D9A3),
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
                color: const Color(0xFF7B68EE),
                bg: const Color(0x1F7B68EE),
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
                color: const Color(0xFFF5C842),
                bg: const Color(0x20F5C842),
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
                color: const Color(0xFFFF9F43),
                bg: const Color(0x1FFF9F43),
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
        color: const Color(0xFF1C1C28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x18FFFFFF)),
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
                  color: positive
                      ? const Color(0x1A00D9A3)
                      : const Color(0x1AFF5F6D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: positive
                        ? const Color(0xFF00D9A3)
                        : const Color(0xFFFF5F6D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF0F0FF),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF4A4A62),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chart Card ───────────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final List<DailySalesEntity> dailySales;
  final AnimationController animController;

  const _ChartCard({
    required this.dailySales,
    required this.animController,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              const Text(
                'Last 7 Days',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF0F0FF),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x1A00D9A3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Revenue',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF00D9A3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: animController,
            builder: (_, __) => SizedBox(
              height: 160,
              child: CustomPaint(
                painter: _ChartPainter(
                  dailySales: dailySales,
                  progress: animController.value,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<DailySalesEntity> dailySales;
  final double progress;

  _ChartPainter({required this.dailySales, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (dailySales.isEmpty) return;

    final linePaint = Paint()
      ..color = const Color(0xFF00D9A3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = const Color(0xFF00D9A3)
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00D9A3).withOpacity(0.2),
          const Color(0xFF00D9A3).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final maxRevenue = dailySales
        .map((d) => d.revenue)
        .reduce((a, b) => a > b ? a : b);
    if (maxRevenue == 0) return;

    final count = dailySales.length;
    final points = <Offset>[];
    for (int i = 0; i < count; i++) {
      final x = count > 1 ? (i / (count - 1)) * size.width : size.width / 2;
      final y = size.height -
          (dailySales[i].revenue / maxRevenue) * size.height * 0.85;
      points.add(Offset(x, y));
    }

    // Clamp visible points by progress
    final visibleCount = (points.length * progress).ceil().clamp(1, points.length);
    final visible = points.sublist(0, visibleCount);

    // Fill
    final fillPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(visible.first.dx, visible.first.dy);
    for (int i = 1; i < visible.length; i++) {
      fillPath.lineTo(visible[i].dx, visible[i].dy);
    }
    fillPath.lineTo(visible.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePath = Path()..moveTo(visible.first.dx, visible.first.dy);
    for (int i = 1; i < visible.length; i++) {
      linePath.lineTo(visible[i].dx, visible[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    for (final p in visible) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..color = const Color(0xFF1C1C28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Baseline
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()
        ..color = const Color(0x18FFFFFF)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.progress != progress;
}

// ─── Transaction Card ─────────────────────────────────────────────────────────
class _TransactionCard extends StatelessWidget {
  final List<dynamic> sales;
  const _TransactionCard({required this.sales});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: Column(
        children: sales.asMap().entries.map((entry) {
          final i = entry.key;
          final sale = entry.value;
          final isLast = i == sales.length - 1;
          return Column(
            children: [
              _TxRow(sale: sale, index: i),
              if (!isLast)
                const Divider(height: 1, color: Color(0x18FFFFFF)),
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
        statusColor = const Color(0xFF00D9A3);
        statusBg = const Color(0x1A00D9A3);
        break;
      case 'pending':
        statusColor = const Color(0xFFFF9F43);
        statusBg = const Color(0x1FFF9F43);
        break;
      default:
        statusColor = const Color(0xFFFF5F6D);
        statusBg = const Color(0x1AFF5F6D);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0x1F7B68EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '#${index + 1}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7B68EE),
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
                  sale.customerName ?? 'Unknown Customer',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF0F0FF),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '#TRX${sale.id ?? index + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF4A4A62),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${(sale.total ?? 0.0).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF0F0FF),
                ),
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
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
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
        color: const Color(0xFF1C1C28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF5C842),
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1AFF5F6D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF5F6D).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFFF5F6D), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFFF5F6D)),
            ),
          ),
        ],
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
        color: const Color(0xFF1C1C28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 13, color: Color(0xFF4A4A62)),
        ),
      ),
    );
  }
}