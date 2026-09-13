import '../models/financial_health_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/transaction_model.dart';

class CashflowForecastService {
  /// Generate daily projected cashflow for the next [days] days
  static List<CashflowForecastItem> forecast({
    required double currentBalance,
    required double averageDailyExpense,
    required List<RecurringTransactionModel> activeRecurrings,
    int days = 30,
  }) {
    final List<CashflowForecastItem> result = [];
    double runningBalance = currentBalance;
    final now = DateTime.now();

    for (int i = 1; i <= days; i++) {
      final forecastDate = now.add(Duration(days: i));
      double dayNetChange = -averageDailyExpense;

      // Check recurring transactions hitting on this day
      for (final rec in activeRecurrings) {
        if (_isDueOnDate(rec, forecastDate)) {
          if (rec.type == TransactionType.income) {
            dayNetChange += rec.amount;
          } else {
            dayNetChange -= rec.amount;
          }
        }
      }

      runningBalance += dayNetChange;
      result.add(
        CashflowForecastItem(
          date: forecastDate,
          projectedBalance: runningBalance,
          dailyNetChange: dayNetChange,
          isDeficit: runningBalance < 0,
        ),
      );
    }

    return result;
  }

  static bool _isDueOnDate(
    RecurringTransactionModel rec,
    DateTime date,
  ) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(rec.startDate.year, rec.startDate.month, rec.startDate.day);
    if (dateOnly.isBefore(startOnly)) return false;
    if (rec.endDate != null) {
      final endOnly = DateTime(rec.endDate!.year, rec.endDate!.month, rec.endDate!.day);
      if (dateOnly.isAfter(endOnly)) return false;
    }

    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0).day;
    final expectedDay = rec.startDate.day > lastDayOfMonth
        ? lastDayOfMonth
        : rec.startDate.day;

    switch (rec.frequency) {
      case RecurrenceFrequency.daily:
        return true;
      case RecurrenceFrequency.weekly:
        return date.weekday == rec.startDate.weekday;
      case RecurrenceFrequency.monthly:
        return date.day == expectedDay;
      case RecurrenceFrequency.yearly:
        return date.month == rec.startDate.month && date.day == expectedDay;
    }
  }
}
