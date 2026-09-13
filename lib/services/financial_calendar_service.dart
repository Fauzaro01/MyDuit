import '../models/transaction_model.dart';
import '../models/debt_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/subscription_model.dart';

class CalendarDaySummary {
  final DateTime date;
  final double totalIncome;
  final double totalExpense;
  final List<TransactionModel> transactions;
  final List<DebtModel> debtsDue;
  final List<RecurringTransactionModel> recurringsDue;
  final List<SubscriptionModel> subscriptionsDue;

  const CalendarDaySummary({
    required this.date,
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.transactions = const [],
    this.debtsDue = const [],
    this.recurringsDue = const [],
    this.subscriptionsDue = const [],
  });

  bool get hasEvents =>
      transactions.isNotEmpty ||
      debtsDue.isNotEmpty ||
      recurringsDue.isNotEmpty ||
      subscriptionsDue.isNotEmpty;

  /// Heatmap intensity level 0 to 4
  int get heatLevel {
    if (totalExpense <= 0) return 0;
    if (totalExpense < 50000) return 1;
    if (totalExpense < 200000) return 2;
    if (totalExpense < 1000000) return 3;
    return 4;
  }
}

class FinancialCalendarService {
  /// Generate daily summaries for a given month and year
  static Map<int, CalendarDaySummary> generateMonthSummary({
    required int year,
    required int month,
    required List<TransactionModel> transactions,
    List<DebtModel> debts = const [],
    List<RecurringTransactionModel> recurrings = const [],
    List<SubscriptionModel> subscriptions = const [],
  }) {
    final Map<int, CalendarDaySummary> result = {};
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int d = 1; d <= daysInMonth; d++) {
      final curDate = DateTime(year, month, d);

      final dayTx = transactions.where((tx) {
        return tx.date.year == year &&
            tx.date.month == month &&
            tx.date.day == d;
      }).toList();

      double inc = 0.0;
      double exp = 0.0;
      for (final tx in dayTx) {
        if (tx.type == TransactionType.income) {
          inc += tx.amount;
        } else {
          exp += tx.amount;
        }
      }

      final debtsDue = debts.where((debt) {
        if (debt.isSettled || debt.dueDate == null) return false;
        return debt.dueDate!.year == year &&
            debt.dueDate!.month == month &&
            debt.dueDate!.day == d;
      }).toList();

      final recurringsDue = recurrings.where((rec) {
        if (!rec.isActive) return false;
        if (rec.frequency == RecurrenceFrequency.monthly) {
          return rec.startDate.day == d;
        } else if (rec.frequency == RecurrenceFrequency.weekly) {
          return curDate.weekday == rec.startDate.weekday;
        }
        return false;
      }).toList();

      final subsDue = subscriptions.where((sub) {
        if (!sub.isActive) return false;
        if (sub.billingCycle == BillingCycle.monthly) {
          return sub.dueDay == d;
        }
        return false;
      }).toList();

      result[d] = CalendarDaySummary(
        date: curDate,
        totalIncome: inc,
        totalExpense: exp,
        transactions: dayTx,
        debtsDue: debtsDue,
        recurringsDue: recurringsDue,
        subscriptionsDue: subsDue,
      );
    }

    return result;
  }
}
