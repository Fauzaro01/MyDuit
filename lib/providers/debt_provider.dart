import 'package:flutter/material.dart';
import '../models/debt_model.dart';
import '../services/database_service.dart';

class DebtProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<DebtModel> _debts = [];
  List<DebtModel> get debts => _debts;

  List<DebtModel> get activeDebts => _debts.where((d) => !d.isSettled).toList();

  List<DebtModel> get settledDebts => _debts.where((d) => d.isSettled).toList();

  List<DebtModel> get myDebts =>
      _debts.where((d) => d.type == DebtType.iOwe && !d.isSettled).toList();

  List<DebtModel> get myReceivables =>
      _debts.where((d) => d.type == DebtType.owedToMe && !d.isSettled).toList();

  List<DebtModel> get overdueDebts =>
      activeDebts.where((d) => d.isOverdue).toList();

  double get totalIOwe => myDebts.fold(0, (sum, d) => sum + d.remainingAmount);

  double get totalOwedToMe =>
      myReceivables.fold(0, (sum, d) => sum + d.remainingAmount);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadDebts() async {
    _isLoading = true;
    notifyListeners();

    _debts = await _dbService.getAllDebts();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addDebt(DebtModel debt) async {
    await _dbService.insertDebt(debt);
    await loadDebts();
  }

  Future<void> updateDebt(DebtModel debt) async {
    await _dbService.updateDebt(debt);
    await loadDebts();
  }

  Future<void> deleteDebt(String id) async {
    await _dbService.deleteDebt(id);
    await loadDebts();
  }

  Future<void> addPayment(String debtId, double amount) async {
    await _dbService.addDebtPayment(debtId, amount);
    await loadDebts();
  }

  Future<void> settleDebt(DebtModel debt) async {
    final updated = debt.copyWith(isSettled: true, paidAmount: debt.amount);
    await _dbService.updateDebt(updated);
    await loadDebts();
  }
}
