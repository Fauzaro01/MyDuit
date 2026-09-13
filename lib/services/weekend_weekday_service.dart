import '../models/transaction_model.dart';

class WeekendWeekdayStats {
  final double weekdayTotal;
  final double weekendTotal;
  final int weekdayCount;
  final int weekendCount;
  final double weekdayDailyAvg;
  final double weekendDailyAvg;

  WeekendWeekdayStats({
    required this.weekdayTotal,
    required this.weekendTotal,
    required this.weekdayCount,
    required this.weekendCount,
    required this.weekdayDailyAvg,
    required this.weekendDailyAvg,
  });

  double get total => weekdayTotal + weekendTotal;
  double get totalExpense => total;
  double get weekdayRatio => total > 0 ? (weekdayTotal / total) : 0.0;
  double get weekendRatio => total > 0 ? (weekendTotal / total) : 0.0;
  double get weekdayPercentage => weekdayRatio * 100;
  double get weekendPercentage => weekendRatio * 100;
}

class WeekendWeekdayService {
  static WeekendWeekdayStats analyzeSpending(List<TransactionModel> transactions) {
    double weekdaySum = 0.0;
    double weekendSum = 0.0;
    int weekdayCount = 0;
    int weekendCount = 0;

    final Set<String> uniqueWeekdayDays = {};
    final Set<String> uniqueWeekendDays = {};

    for (final tx in transactions) {
      if (tx.type != TransactionType.expense) continue;
      final dayKey = '${tx.date.year}-${tx.date.month}-${tx.date.day}';

      if (tx.date.weekday >= DateTime.saturday) {
        weekendSum += tx.amount;
        weekendCount++;
        uniqueWeekendDays.add(dayKey);
      } else {
        weekdaySum += tx.amount;
        weekdayCount++;
        uniqueWeekdayDays.add(dayKey);
      }
    }

    final double weekdayAvg = uniqueWeekdayDays.isNotEmpty
        ? weekdaySum / uniqueWeekdayDays.length
        : 0.0;
    final double weekendAvg = uniqueWeekendDays.isNotEmpty
        ? weekendSum / uniqueWeekendDays.length
        : 0.0;

    return WeekendWeekdayStats(
      weekdayTotal: weekdaySum,
      weekendTotal: weekendSum,
      weekdayCount: weekdayCount,
      weekendCount: weekendCount,
      weekdayDailyAvg: weekdayAvg,
      weekendDailyAvg: weekendAvg,
    );
  }
}
