import 'package:flutter/material.dart';
import '../models/recurring_transaction_model.dart';
import '../services/database_service.dart';
import 'transaction_provider.dart';
import 'wallet_provider.dart';

class RecurringProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  TransactionProvider? _transactionProvider;
  WalletProvider? _walletProvider;

  void setProviders(
    TransactionProvider transactionProvider,
    WalletProvider walletProvider,
  ) {
    _transactionProvider = transactionProvider;
    _walletProvider = walletProvider;
  }

  List<RecurringTransactionModel> _recurringTransactions = [];
  List<RecurringTransactionModel> get recurringTransactions =>
      _recurringTransactions;

  List<RecurringTransactionModel> get activeRecurrings =>
      _recurringTransactions.where((r) => r.isActive).toList();

  List<RecurringTransactionModel> get inactiveRecurrings =>
      _recurringTransactions.where((r) => !r.isActive).toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadRecurringTransactions() async {
    _isLoading = true;
    notifyListeners();

    _recurringTransactions = await _dbService.getAllRecurringTransactions();

    _isLoading = false;
    notifyListeners();
  }

  /// Generate pending recurring transactions and refresh data
  Future<int> generatePendingTransactions() async {
    final generated = await _dbService.generatePendingRecurringTransactions();

    if (generated.isNotEmpty) {
      // Reload everything
      await loadRecurringTransactions();
      await _transactionProvider?.loadData();
      await _walletProvider?.loadWallets();
    }

    return generated.length;
  }

  Future<void> addRecurringTransaction(
    RecurringTransactionModel recurring,
  ) async {
    await _dbService.insertRecurringTransaction(recurring);
    await loadRecurringTransactions();
  }

  Future<void> updateRecurringTransaction(
    RecurringTransactionModel recurring,
  ) async {
    await _dbService.updateRecurringTransaction(recurring);
    await loadRecurringTransactions();
  }

  Future<void> toggleActive(RecurringTransactionModel recurring) async {
    final updated = recurring.copyWith(isActive: !recurring.isActive);
    await _dbService.updateRecurringTransaction(updated);
    await loadRecurringTransactions();
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await _dbService.deleteRecurringTransaction(id);
    await loadRecurringTransactions();
  }
}
