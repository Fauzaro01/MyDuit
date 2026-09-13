import '../models/budget_model.dart';
import '../models/transaction_model.dart';

enum BudgetAlertLevel {
  safe, // < 50%
  warning, // 50% - 79%
  alert, // 80% - 99%
  exceeded, // >= 100%
}

class BudgetUsageReport {
  final BudgetModel budget;
  final double baseLimit;
  final double rolloverAmount;
  final double effectiveLimit;
  final double spent;
  final double remaining;
  final double usagePercentage;
  final BudgetAlertLevel alertLevel;

  const BudgetUsageReport({
    required this.budget,
    required this.baseLimit,
    required this.rolloverAmount,
    required this.effectiveLimit,
    required this.spent,
    required this.remaining,
    required this.usagePercentage,
    required this.alertLevel,
  });
}

class BudgetRolloverService {
  /// Returns a tuple of (year, month) for the preceding month period
  static (int year, int month) getPreviousPeriod(int year, int month) {
    if (month <= 1) {
      return (year - 1, 12);
    }
    return (year, month - 1);
  }

  /// Calculate the rollover surplus from previous month if budget is enabled
  static double calculateRollover({
    required BudgetModel budget,
    required List<TransactionModel> previousMonthTransactions,
    required double previousMonthLimit,
  }) {
    if (!budget.isRollover) return 0.0;

    double previousSpent = 0.0;
    for (final tx in previousMonthTransactions) {
      if (tx.type == TransactionType.expense &&
          tx.category == budget.category &&
          (budget.customCategoryId == null ||
              tx.customCategoryId == budget.customCategoryId)) {
        previousSpent += tx.amount;
      }
    }

    final surplus = previousMonthLimit - previousSpent;
    return surplus > 0 ? surplus : 0.0;
  }

  /// Evaluates full budget usage including rollover and alert level
  static BudgetUsageReport evaluate({
    required BudgetModel budget,
    required List<TransactionModel> currentMonthTransactions,
    double rolloverAmount = 0.0,
  }) {
    final safeRollover = (budget.isRollover && rolloverAmount > 0) ? rolloverAmount : 0.0;
    final effectiveLimit = budget.monthlyLimit + safeRollover;
    double spent = 0.0;

    for (final tx in currentMonthTransactions) {
      if (tx.type == TransactionType.expense &&
          tx.category == budget.category &&
          (budget.customCategoryId == null ||
              tx.customCategoryId == budget.customCategoryId)) {
        spent += tx.amount;
      }
    }

    final remaining = effectiveLimit - spent;
    final percentage = effectiveLimit > 0 ? (spent / effectiveLimit) * 100 : 0.0;

    BudgetAlertLevel level;
    if (percentage >= 100) {
      level = BudgetAlertLevel.exceeded;
    } else if (percentage >= 80) {
      level = BudgetAlertLevel.alert;
    } else if (percentage >= 50) {
      level = BudgetAlertLevel.warning;
    } else {
      level = BudgetAlertLevel.safe;
    }

    return BudgetUsageReport(
      budget: budget,
      baseLimit: budget.monthlyLimit,
      rolloverAmount: safeRollover,
      effectiveLimit: effectiveLimit,
      spent: spent,
      remaining: remaining,
      usagePercentage: percentage,
      alertLevel: level,
    );
  }
}
