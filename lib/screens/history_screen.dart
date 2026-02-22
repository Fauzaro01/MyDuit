import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../widgets/transaction_detail_sheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch(TransactionProvider provider) {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        provider.clearSearch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<TransactionProvider>();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Riwayat', style: theme.textTheme.headlineMedium),
                    IconButton(
                      onPressed: () => _toggleSearch(provider),
                      icon: Icon(
                        _showSearch
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (_showSearch)
                  Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.cardDark
                              : AppColors.cardAltLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Cari transaksi...',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      provider.clearSearch();
                                    },
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 20,
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (query) => provider.search(query),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: -0.1, end: 0),
                const MonthSelector(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardAltLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: isDark ? AppColors.cardAltDark : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.textTheme.bodyMedium?.color,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Semua'),
                Tab(text: 'Pemasukan'),
                Tab(text: 'Pengeluaran'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TransactionList(filter: null),
                _TransactionList(filter: TransactionType.income),
                _TransactionList(filter: TransactionType.expense),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final TransactionType? filter;

  const _TransactionList({this.filter});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();

    // Use search results if actively searching
    List<TransactionModel> transactions;
    if (provider.isSearching) {
      transactions = provider.searchResults;
      if (filter != null) {
        transactions = transactions.where((t) => t.type == filter).toList();
      }
    } else if (filter == null) {
      transactions = provider.transactions;
    } else if (filter == TransactionType.income) {
      transactions = provider.incomeTransactions;
    } else {
      transactions = provider.expenseTransactions;
    }

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      return EmptyState(
        message: provider.isSearching
            ? 'Tidak ada transaksi yang cocok.'
            : 'Belum ada transaksi',
      );
    }

    // Group by date
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in transactions) {
      final key = DateFormatter.relative(tx.date);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(tx);
    }

    final groups = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: groups.length,
      itemBuilder: (context, gIndex) {
        final group = groups[gIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                group.key,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            ...group.value.asMap().entries.map((entry) {
              final index = entry.key;
              final tx = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child:
                    TransactionTile(
                          transaction: tx,
                          onDismissed: () {
                            provider.deleteTransaction(tx.id);
                          },
                          onTap: () {
                            showTransactionDetail(
                              context,
                              tx,
                              onDeleted: () =>
                                  provider.deleteTransaction(tx.id),
                            );
                          },
                        )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 50 * index),
                          duration: 300.ms,
                        )
                        .slideX(begin: 0.03, end: 0),
              );
            }),
          ],
        );
      },
    );
  }
}
