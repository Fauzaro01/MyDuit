import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/transaction_model.dart';
import '../providers/custom_category_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/tag_provider.dart';
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
  String? _selectedWalletId;
  TransactionCategory? _selectedCategory;
  String? _selectedCustomCatId;
  String? _selectedCategoryName;
  String? _selectedTag;
  DateTimeRange? _selectedDateRange;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _setPresetDateRange(String preset) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (preset) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'this_week':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case 'this_month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'last_30_days':
        start = now.subtract(const Duration(days: 30));
        start = DateTime(start.year, start.month, start.day);
        break;
      case 'this_year':
        start = DateTime(now.year, 1, 1);
        break;
      default:
        return;
    }
    setState(() => _selectedDateRange = DateTimeRange(start: start, end: end));
  }

  Widget _buildPresetDateChip(
    String label,
    String presetKey,
    bool isDark,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        onPressed: () => _setPresetDateRange(presetKey),
      ),
    );
  }

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

  void _showCategoryFilterDialog(BuildContext context) {
    final customCatProvider = Provider.of<CustomCategoryProvider?>(context, listen: false);
    final customCategories = customCatProvider?.categories ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Kategori',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                if (_selectedCategory != null || _selectedCustomCatId != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                        _selectedCustomCatId = null;
                        _selectedCategoryName = null;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Reset'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.all_inclusive_rounded, size: 20),
                    ),
                    title: const Text('Semua Kategori'),
                    selected: _selectedCategory == null && _selectedCustomCatId == null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = null;
                        _selectedCustomCatId = null;
                        _selectedCategoryName = null;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'PENGELUARAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...TransactionCategory.values
                      .where((c) => !c.isIncomeCategory)
                      .map((cat) => ListTile(
                            leading: CircleAvatar(
                              child: Text(cat.icon, style: const TextStyle(fontSize: 18)),
                            ),
                            title: Text(cat.label),
                            selected: _selectedCategory == cat && _selectedCustomCatId == null,
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat;
                                _selectedCustomCatId = null;
                                _selectedCategoryName = cat.label;
                              });
                              Navigator.pop(ctx);
                            },
                          )),
                  if (customCategories.any((c) => !c.isIncome)) ...[
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'KATEGORI KUSTOM PENGELUARAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...customCategories
                        .where((c) => !c.isIncome)
                        .map((cat) => ListTile(
                              leading: CircleAvatar(
                                child: Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                              ),
                              title: Text(cat.name),
                              selected: _selectedCustomCatId == cat.id,
                              onTap: () {
                                setState(() {
                                  _selectedCategory = null;
                                  _selectedCustomCatId = cat.id;
                                  _selectedCategoryName = cat.name;
                                });
                                Navigator.pop(ctx);
                              },
                            )),
                  ],
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'PEMASUKAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...TransactionCategory.values
                      .where((c) => c.isIncomeCategory)
                      .map((cat) => ListTile(
                            leading: CircleAvatar(
                              child: Text(cat.icon, style: const TextStyle(fontSize: 18)),
                            ),
                            title: Text(cat.label),
                            selected: _selectedCategory == cat && _selectedCustomCatId == null,
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat;
                                _selectedCustomCatId = null;
                                _selectedCategoryName = cat.label;
                              });
                              Navigator.pop(ctx);
                            },
                          )),
                  if (customCategories.any((c) => c.isIncome)) ...[
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'KATEGORI KUSTOM PEMASUKAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...customCategories
                        .where((c) => c.isIncome)
                        .map((cat) => ListTile(
                              leading: CircleAvatar(
                                child: Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                              ),
                              title: Text(cat.name),
                              selected: _selectedCustomCatId == cat.id,
                              onTap: () {
                                setState(() {
                                  _selectedCategory = null;
                                  _selectedCustomCatId = cat.id;
                                  _selectedCategoryName = cat.name;
                                });
                                Navigator.pop(ctx);
                              },
                            )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<TransactionProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final tagProvider = Provider.of<TagProvider?>(context);
    final wallets = walletProvider.wallets;
    final hasCategoryFilter = _selectedCategory != null || _selectedCustomCatId != null;

    final allTagsSet = <String>{};
    for (final tx in provider.transactions) {
      allTagsSet.addAll(tx.tags);
    }
    if (tagProvider != null) {
      allTagsSet.addAll(tagProvider.tags.map((t) => t.name));
    }
    final availableTags = allTagsSet.toList();

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat',
                      style: theme.textTheme.headlineMedium,
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _selectedDateRange != null
                                ? Icons.date_range_rounded
                                : Icons.date_range_outlined,
                            color: _selectedDateRange != null
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          tooltip: 'Rentang Tanggal',
                          onPressed: _pickDateRange,
                        ),
                        IconButton(
                          icon: Icon(
                            hasCategoryFilter
                                ? Icons.filter_alt_rounded
                                : Icons.filter_alt_outlined,
                            color: hasCategoryFilter
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          tooltip: 'Filter Kategori',
                          onPressed: () => _showCategoryFilterDialog(context),
                        ),
                        IconButton(
                          icon: Icon(
                            _showSearch
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                          ),
                          tooltip: 'Cari',
                          onPressed: () => _toggleSearch(provider),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_showSearch)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Cari judul, catatan, atau nominal...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.search('');
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) =>
                          provider.search(value),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: -0.1, end: 0),
                const MonthSelector(),
                const SizedBox(height: 8),
                // Quick Date Range Presets
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetDateChip('Hari Ini', 'today', isDark, theme),
                      _buildPresetDateChip('Minggu Ini', 'this_week', isDark, theme),
                      _buildPresetDateChip('Bulan Ini', 'this_month', isDark, theme),
                      _buildPresetDateChip('30 Hari', 'last_30_days', isDark, theme),
                      _buildPresetDateChip('Tahun Ini', 'this_year', isDark, theme),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Active date range filter chip
                      if (_selectedDateRange != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(
                              '${DateFormatter.shortDate(_selectedDateRange!.start)} - ${DateFormatter.shortDate(_selectedDateRange!.end)}',
                            ),
                            labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
                            backgroundColor: theme.colorScheme.primary,
                            deleteIcon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                            onDeleted: () {
                              setState(() {
                                _selectedDateRange = null;
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      // Active category filter chip
                      if (hasCategoryFilter)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(_selectedCategoryName ?? 'Kategori'),
                            labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
                            backgroundColor: theme.colorScheme.primary,
                            deleteIcon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                            onDeleted: () {
                              setState(() {
                                _selectedCategory = null;
                                _selectedCustomCatId = null;
                                _selectedCategoryName = null;
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      if (wallets.length > 1) ...[
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: _selectedWalletId == null,
                            label: const Text('Semua Dompet'),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: _selectedWalletId == null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: _selectedWalletId == null
                                  ? Colors.white
                                  : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                            ),
                            backgroundColor: isDark
                                ? AppColors.cardDark
                                : AppColors.cardLight,
                            selectedColor: theme.colorScheme.primary,
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: _selectedWalletId == null
                                  ? theme.colorScheme.primary
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.08)),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (_) {
                              setState(() => _selectedWalletId = null);
                            },
                          ),
                        ),
                        ...wallets.map((wallet) {
                          final isSelected = _selectedWalletId == wallet.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: isSelected,
                              label: Text('${wallet.emoji} ${wallet.name}'),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight),
                              ),
                              backgroundColor: isDark
                                  ? AppColors.cardDark
                                  : AppColors.cardLight,
                              selectedColor: theme.colorScheme.primary,
                              checkmarkColor: Colors.white,
                              side: BorderSide(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.black.withValues(
                                              alpha: 0.08,
                                            )),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedWalletId = isSelected
                                      ? null
                                      : wallet.id;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                      // Tag filter chips
                      ...availableTags.map((tag) {
                        final isTagSelected = _selectedTag == tag;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isTagSelected,
                            label: Text('#$tag'),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isTagSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isTagSelected
                                  ? Colors.white
                                  : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                            ),
                            backgroundColor: isDark
                                ? AppColors.cardDark
                                : AppColors.cardLight,
                            selectedColor: isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight,
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isTagSelected
                                  ? (isDark
                                      ? AppColors.primaryDark
                                      : AppColors.primaryLight)
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.08)),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (_) {
                              setState(() {
                                _selectedTag = isTagSelected ? null : tag;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
                _TransactionList(
                  filter: null,
                  walletId: _selectedWalletId,
                  category: _selectedCategory,
                  customCategoryId: _selectedCustomCatId,
                  tag: _selectedTag,
                  dateRange: _selectedDateRange,
                  searchQuery: _searchController.text.trim(),
                ),
                _TransactionList(
                  filter: TransactionType.income,
                  walletId: _selectedWalletId,
                  category: _selectedCategory,
                  customCategoryId: _selectedCustomCatId,
                  tag: _selectedTag,
                  dateRange: _selectedDateRange,
                  searchQuery: _searchController.text.trim(),
                ),
                _TransactionList(
                  filter: TransactionType.expense,
                  walletId: _selectedWalletId,
                  category: _selectedCategory,
                  customCategoryId: _selectedCustomCatId,
                  tag: _selectedTag,
                  dateRange: _selectedDateRange,
                  searchQuery: _searchController.text.trim(),
                ),
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
  final String? walletId;
  final TransactionCategory? category;
  final String? customCategoryId;
  final String? tag;
  final DateTimeRange? dateRange;
  final String searchQuery;

  const _TransactionList({
    this.filter,
    this.walletId,
    this.category,
    this.customCategoryId,
    this.tag,
    this.dateRange,
    this.searchQuery = '',
  });

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

    // Filter by custom date range if selected
    if (dateRange != null) {
      final start = DateTime(
        dateRange!.start.year,
        dateRange!.start.month,
        dateRange!.start.day,
      );
      final end = DateTime(
        dateRange!.end.year,
        dateRange!.end.month,
        dateRange!.end.day,
        23,
        59,
        59,
      );
      transactions = transactions
          .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
          .toList();
    }

    // Filter by wallet if selected
    if (walletId != null) {
      transactions =
          transactions.where((t) => t.walletId == walletId).toList();
    }

    // Filter by category if selected
    if (category != null) {
      transactions =
          transactions.where((t) => t.category == category && t.customCategoryId == null).toList();
    } else if (customCategoryId != null) {
      transactions =
          transactions.where((t) => t.customCategoryId == customCategoryId).toList();
    }

    // Filter by tag if selected
    if (tag != null) {
      transactions = transactions.where((t) => t.tags.contains(tag)).toList();
    }

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      final message = provider.isSearching
          ? (searchQuery.isNotEmpty
              ? 'Tidak ada transaksi untuk "$searchQuery"'
              : 'Tidak ada transaksi yang cocok.')
          : 'Belum ada transaksi';
      return EmptyState(message: message);
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

        double dayIncome = 0.0;
        double dayExpense = 0.0;
        for (final tx in group.value) {
          if (tx.type == TransactionType.income) {
            dayIncome += tx.amount;
          } else {
            dayExpense += tx.amount;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    group.key,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      if (dayIncome > 0)
                        Text(
                          '+${CurrencyFormatter.formatCompact(dayIncome)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.income,
                          ),
                        ),
                      if (dayIncome > 0 && dayExpense > 0)
                        const SizedBox(width: 8),
                      if (dayExpense > 0)
                        Text(
                          '-${CurrencyFormatter.formatCompact(dayExpense)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.expense,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            ...group.value.asMap().entries.map((entry) {
              final index = entry.key;
              final tx = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TransactionTile(
                  transaction: tx,
                  onDismissed: () {
                    provider.deleteTransaction(tx.id);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Transaksi "${tx.title}" dihapus'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        action: SnackBarAction(
                          label: 'Undo',
                          textColor: AppColors.primaryLight,
                          onPressed: () {
                            provider.addTransaction(tx);
                          },
                        ),
                      ),
                    );
                  },
                  onTap: () {
                    showTransactionDetail(
                      context,
                      tx,
                      onDeleted: () {
                        provider.deleteTransaction(tx.id);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Transaksi "${tx.title}" dihapus'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            action: SnackBarAction(
                              label: 'Undo',
                              textColor: AppColors.primaryLight,
                              onPressed: () {
                                provider.addTransaction(tx);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 30 * index),
                      duration: 300.ms,
                    )
                    .slideX(begin: 0.05, end: 0),
              );
            }),
          ],
        );
      },
    );
  }
}
