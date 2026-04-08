import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/transactions_bloc.dart';
import '../bloc/transactions_event.dart';
import '../bloc/transactions_state.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  DateTime? _selectedDate;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const _bg = Color(0xFFF8FAFC);
  static const _white = Color(0xFFFFFFFF);
  static const _primary = Color(0xFF475569);
  static const _primaryLt = Color(0xFF64748B);
  static const _danger = Color(0xFFEF4444);
  static const _ink = Color(0xFF1E293B);
  static const _inkMid = Color(0xFF64748B);
  static const _inkLight = Color(0xFFCBD5E1);
  static const _border = Color(0xFFE2E8F0);

  // Typography helper
  static TextStyle _ts(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = _ink,
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

    // Initial fetch
    context.read<TransactionsBloc>().add(const TransactionsFetchRequested());

    _animController.forward();
  }

  Future<void> _refreshTransactions() async {
    context.read<TransactionsBloc>().add(
          TransactionsFetchRequested(
            date: _selectedDate != null
                ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                : null,
          ),
        );
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionEntity> _filterTransactions(List<TransactionEntity> transactions) {
    if (_searchQuery.isEmpty && _selectedDate == null) {
      return transactions;
    }

    return transactions.where((transaction) {
      bool matchesSearch = true;
      bool matchesDate = true;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        matchesSearch = transaction.id.toString().toLowerCase().contains(query) ||
            transaction.cashierName.toLowerCase().contains(query) ||
            transaction.paymentMethod.toLowerCase().contains(query) ||
            (transaction.customerName?.toLowerCase().contains(query) ?? false);
      }

      if (_selectedDate != null) {
        matchesDate = transaction.createdAt.year == _selectedDate!.year &&
            transaction.createdAt.month == _selectedDate!.month &&
            transaction.createdAt.day == _selectedDate!.day;
      }

      return matchesSearch && matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _bg,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: BlocConsumer<TransactionsBloc, TransactionsState>(
          listener: (context, state) {
            if (state is TransactionsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(state.message,
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  backgroundColor: _danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          builder: (context, state) {
            final filteredTransactions = state is TransactionsLoaded
                ? _filterTransactions(state.transactions)
                : <TransactionEntity>[];

            return RefreshIndicator(
              onRefresh: _refreshTransactions,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // App Bar
                  SliverAppBar(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    pinned: true,
                    expandedHeight: 110,
                    surfaceTintColor: Colors.transparent,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      title: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transactions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'View and manage all transactions',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primary, _primaryLt],
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
                          onTap: () {
                            setState(() {
                              _searchQuery = '';
                              _selectedDate = null;
                              _searchController.clear();
                            });
                            context
                                .read<TransactionsBloc>()
                                .add(const TransactionsFetchRequested());
                          },
                          child: Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh_rounded,
                                    size: 15, color: Colors.white),
                                SizedBox(width: 5),
                                Text(
                                  'Refresh',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Filters
                  SliverToBoxAdapter(
                    child: Container(
                      color: _white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Search bar
                          Container(
                            decoration: BoxDecoration(
                              color: _bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _border),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              style: _ts(14, color: _ink),
                              decoration: InputDecoration(
                                hintText:
                                    'Search by ID, cashier, or payment method…',
                                hintStyle: _ts(13, color: _inkMid),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: _inkMid,
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 13),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Date filter
                          GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => _selectedDate = date);
                                _refreshTransactions();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 13),
                              decoration: BoxDecoration(
                                color: _bg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    color: _inkMid,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedDate != null
                                          ? DateFormat('MMM dd, yyyy')
                                              .format(_selectedDate!)
                                          : 'Select date',
                                      style: _ts(
                                        14,
                                        color: _selectedDate != null
                                            ? _ink
                                            : _inkMid,
                                      ),
                                    ),
                                  ),
                                  if (_selectedDate != null)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => _selectedDate = null);
                                        _refreshTransactions();
                                      },
                                      child: const Icon(
                                        Icons.clear_rounded,
                                        color: _inkMid,
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Main Content
                  if (state is TransactionsLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: _primary,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else if (state is TransactionsError)
                    SliverFillRemaining(
                      child: _EmptyTransactionsState(
                        message: 'Failed to load transactions',
                        onRetry: () => context
                            .read<TransactionsBloc>()
                            .add(const TransactionsFetchRequested()),
                      ),
                    )
                  else if (state is TransactionsLoaded)
                    if (filteredTransactions.isEmpty)
                      SliverFillRemaining(
                        child: _EmptyTransactionsState(
                          message: 'No transactions found',
                          onRetry: _refreshTransactions,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final transaction = filteredTransactions[index];
                              return FadeTransition(
                                opacity: _fadeAnim,
                                child: _TransactionCard(
                                  transaction: transaction,
                                  index: index,
                                ),
                              );
                            },
                            childCount: filteredTransactions.length,
                          ),
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Transaction Card Widget
// ──────────────────────────────────────────────────────────────
class _TransactionCard extends StatelessWidget {
  final TransactionEntity transaction;
  final int index;

  const _TransactionCard({
    super.key,
    required this.transaction,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final status = transaction.status.toLowerCase();
    Color statusColor = Colors.grey;
    Color statusBg = Colors.grey.withOpacity(0.1);

    switch (status) {
      case 'completed':
        statusColor = const Color(0xFF10B981);
        statusBg = const Color(0x1A10B981);
        break;
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        statusBg = const Color(0x1AF59E0B);
        break;
      case 'failed':
      case 'cancelled':
        statusColor = const Color(0xFFEF4444);
        statusBg = const Color(0x1AEF4444);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF475569).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF475569).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
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
                        'Transaction #${transaction.id}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a')
                            .format(transaction.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cashier',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        transaction.cashierName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        transaction.paymentMethod,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${transaction.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${transaction.items.length} items',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (transaction.customerName != null) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Customer: ${transaction.customerName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Empty State Widget
// ──────────────────────────────────────────────────────────────
class _EmptyTransactionsState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _EmptyTransactionsState({
    super.key,
    required this.message,
    required this.onRetry,
  });

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
                color: const Color(0xFF475569).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your filters or refresh to see transactions',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFCBD5E1),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF475569),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}