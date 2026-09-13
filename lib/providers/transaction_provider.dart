import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../services/database_service.dart';
import 'wallet_provider.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  WalletProvider? _walletProvider;

  void setWalletProvider(WalletProvider provider) {
    _walletProvider = provider;
  }

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;

  double _totalIncome = 0;
  double get totalIncome => _totalIncome;

  double _totalExpense = 0;
  double get totalExpense => _totalExpense;

  double get balance => _totalIncome - _totalExpense;

  int _selectedYear = DateTime.now().year;
  int get selectedYear => _selectedYear;

  int _selectedMonth = DateTime.now().month;
  int get selectedMonth => _selectedMonth;

  Map<TransactionCategory, double> _incomeCategoryTotals = {};
  Map<TransactionCategory, double> get incomeCategoryTotals =>
      _incomeCategoryTotals;

  Map<TransactionCategory, double> _expenseCategoryTotals = {};
  Map<TransactionCategory, double> get expenseCategoryTotals =>
      _expenseCategoryTotals;

  int _loadVersion = 0;

  Map<String, double> _incomeCustomTotals = {};
  Map<String, double> get incomeCustomTotals => _incomeCustomTotals;

  Map<String, double> _expenseCustomTotals = {};
  Map<String, double> get expenseCustomTotals => _expenseCustomTotals;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── Budget ──
  List<BudgetModel> _budgets = [];
  List<BudgetModel> get budgets => _budgets;

  // ── Search ──
  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  List<TransactionModel> _searchResults = [];
  List<TransactionModel> get searchResults => _searchResults;
  bool get isSearching => _searchQuery.isNotEmpty;

  TransactionProvider() {
    loadData();
  }

  Future<void> loadData() async {
    final currentVersion = ++_loadVersion;
    _isLoading = true;
    notifyListeners();

    final results = await Future.wait([
      _dbService.getTransactionsByMonth(_selectedYear, _selectedMonth),
      _dbService.getTotalByTypeAndMonth(
        TransactionType.income,
        _selectedYear,
        _selectedMonth,
      ),
      _dbService.getTotalByTypeAndMonth(
        TransactionType.expense,
        _selectedYear,
        _selectedMonth,
      ),
      _dbService.getCategoryTotals(
        TransactionType.income,
        _selectedYear,
        _selectedMonth,
      ),
      _dbService.getCategoryTotals(
        TransactionType.expense,
        _selectedYear,
        _selectedMonth,
      ),
      _dbService.getCustomCategoryTotals(
        TransactionType.income,
        _selectedYear,
        _selectedMonth,
      ),
      _dbService.getCustomCategoryTotals(
        TransactionType.expense,
        _selectedYear,
        _selectedMonth,
      ),
      _dbService.getBudgets(_selectedYear, _selectedMonth),
    ]);

    if (currentVersion != _loadVersion) return;

    _transactions = results[0] as List<TransactionModel>;
    _totalIncome = results[1] as double;
    _totalExpense = results[2] as double;
    _incomeCategoryTotals = results[3] as Map<TransactionCategory, double>;
    _expenseCategoryTotals = results[4] as Map<TransactionCategory, double>;
    _incomeCustomTotals = results[5] as Map<String, double>;
    _expenseCustomTotals = results[6] as Map<String, double>;
    _budgets = results[7] as List<BudgetModel>;

    _isLoading = false;
    notifyListeners();

    if (_searchQuery.isNotEmpty) {
      await search(_searchQuery);
    }
  }

  Future<void> _loadBudgets() async {
    _budgets = await _dbService.getBudgets(_selectedYear, _selectedMonth);
    notifyListeners();
  }

  // ── Transaction CRUD ──
  Future<void> addTransaction(TransactionModel transaction) async {
    await _dbService.insertTransaction(transaction);
    await loadData();
    _walletProvider?.refreshBalances();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _dbService.updateTransaction(transaction);
    await loadData();
    _walletProvider?.refreshBalances();
  }

  Future<void> deleteTransaction(String id) async {
    await _dbService.deleteTransaction(id);
    await loadData();
    _walletProvider?.refreshBalances();
  }

  Future<void> togglePin(String id) async {
    final tx = _transactions.where((t) => t.id == id).firstOrNull;
    if (tx == null) return;
    final updated = tx.copyWith(isPinned: !tx.isPinned);
    await updateTransaction(updated);
  }

  // ── Budget CRUD ──
  Future<void> setBudget(BudgetModel budget) async {
    await _dbService.upsertBudget(budget);
    await _loadBudgets();
    notifyListeners();
  }

  Future<void> deleteBudget(String id) async {
    await _dbService.deleteBudget(id);
    await _loadBudgets();
    notifyListeners();
  }

  // ── Search ──
  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = await _dbService.searchTransactions(
        query.trim(),
        _selectedYear,
        _selectedMonth,
      );
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  // ── Month navigation ──
  void setMonth(int year, int month) {
    _selectedYear = year;
    _selectedMonth = month;
    loadData();
  }

  void nextMonth() {
    if (_selectedMonth == 12) {
      _selectedMonth = 1;
      _selectedYear++;
    } else {
      _selectedMonth++;
    }
    loadData();
  }

  void previousMonth() {
    if (_selectedMonth == 1) {
      _selectedMonth = 12;
      _selectedYear--;
    } else {
      _selectedMonth--;
    }
    loadData();
  }

  List<TransactionModel> get incomeTransactions =>
      _transactions.where((t) => t.type == TransactionType.income).toList();

  List<TransactionModel> get expenseTransactions =>
      _transactions.where((t) => t.type == TransactionType.expense).toList();

  Future<List<Map<String, dynamic>>> getDailyTotals(
    TransactionType type,
  ) async {
    return _dbService.getDailyTotals(type, _selectedYear, _selectedMonth);
  }

  Future<double> getTotalByTypeAndMonth(
    TransactionType type,
    int year,
    int month,
  ) async {
    return _dbService.getTotalByTypeAndMonth(type, year, month);
  }
}
