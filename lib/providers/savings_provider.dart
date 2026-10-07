import 'package:flutter/material.dart';
import '../models/savings_goal_model.dart';
import '../models/savings_contribution_model.dart';
import '../services/database_service.dart';

class SavingsProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<SavingsGoalModel> _goals = [];
  List<SavingsGoalModel> get goals => _goals;

  List<SavingsGoalModel> get activeGoals =>
      _goals.where((g) => !g.isCompleted).toList();

  List<SavingsGoalModel> get completedGoals =>
      _goals.where((g) => g.isCompleted).toList();

  double get totalSaved => _goals.fold(0, (sum, g) => sum + g.currentAmount);
  double get totalTarget => _goals.fold(0, (sum, g) => sum + g.targetAmount);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SavingsProvider() {
    loadGoals();
  }

  Future<void> loadGoals() async {
    _isLoading = true;
    notifyListeners();

    try {
      _goals = await _dbService.getAllSavingsGoals();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGoal(SavingsGoalModel goal) async {
    await _dbService.insertSavingsGoal(goal);
    await loadGoals();
  }

  Future<void> updateGoal(SavingsGoalModel goal) async {
    await _dbService.updateSavingsGoal(goal);
    await loadGoals();
  }

  Future<void> deleteGoal(String id) async {
    await _dbService.deleteSavingsGoal(id);
    await loadGoals();
  }

  /// Records a contribution. Returns true if it just fully funded the goal.
  Future<bool> addAmountToGoal(
    String goalId,
    double amount, {
    String? note,
    String? walletId,
  }) async {
    if (amount <= 0) return false;
    final justCompleted = await _dbService.addToSavingsGoal(
      goalId,
      amount,
      note: note,
      walletId: walletId,
    );
    await loadGoals();
    return justCompleted;
  }

  Future<List<SavingsContributionModel>> getContributionsForGoal(String goalId) =>
      _dbService.getSavingsContributions(goalId);
}
