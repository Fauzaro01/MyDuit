import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/savings_goal_model.dart';

class MonthlyRecapData {
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final double savingsRate; // 0 to 100%
  final String topExpenseCategory;
  final double topExpenseCategoryAmount;
  final double topExpenseCategoryPercent;
  final int mostExpensiveDayOfMonth;
  final double mostExpensiveDayAmount;
  final int mostFrugalDayOfMonth;
  final int transactionCount;
  final double prevMonthExpense;
  final double expenseChangePercent; // +15% or -10% vs prev month
  final String personalityTitle; // e.g. "Sang Penghemat Ulung", "Kolektor Belanja", etc.
  final String personalityEmoji;
  final String keyInsightSummary;

  const MonthlyRecapData({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.savingsRate,
    required this.topExpenseCategory,
    required this.topExpenseCategoryAmount,
    required this.topExpenseCategoryPercent,
    required this.mostExpensiveDayOfMonth,
    required this.mostExpensiveDayAmount,
    required this.mostFrugalDayOfMonth,
    required this.transactionCount,
    required this.prevMonthExpense,
    required this.expenseChangePercent,
    required this.personalityTitle,
    required this.personalityEmoji,
    required this.keyInsightSummary,
  });
}

class MonthlyRecapService {
  static MonthlyRecapData generateRecap({
    required int year,
    required int month,
    required List<TransactionModel> allTransactions,
    List<BudgetModel> budgets = const [],
    List<SavingsGoalModel> goals = const [],
  }) {
    // Current month transactions
    final currentTx = allTransactions.where((t) => t.date.year == year && t.date.month == month).toList();

    // Previous month transactions
    final prevMonthDate = DateTime(year, month - 1, 1);
    final prevTx = allTransactions.where((t) => t.date.year == prevMonthDate.year && t.date.month == prevMonthDate.month).toList();

    double income = 0;
    double expense = 0;
    final categoryExpenseMap = <TransactionCategory, double>{};
    final dailyExpenseMap = <int, double>{};

    for (final tx in currentTx) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
        categoryExpenseMap[tx.category] = (categoryExpenseMap[tx.category] ?? 0) + tx.amount;
        dailyExpenseMap[tx.date.day] = (dailyExpenseMap[tx.date.day] ?? 0) + tx.amount;
      }
    }

    double prevExpense = 0;
    for (final tx in prevTx) {
      if (tx.type == TransactionType.expense) {
        prevExpense += tx.amount;
      }
    }

    final netSavings = income - expense;
    final savingsRate = income > 0 ? ((income - expense) / income * 100).clamp(-100.0, 100.0) : 0.0;

    // Top expense category
    String topCat = 'Belum ada';
    double topCatAmt = 0;
    for (final entry in categoryExpenseMap.entries) {
      if (entry.value > topCatAmt) {
        topCatAmt = entry.value;
        topCat = entry.key.label;
      }
    }
    final topCatPercent = expense > 0 ? (topCatAmt / expense * 100) : 0.0;

    // Daily peaks and lows
    int peakDay = 1;
    double peakAmt = 0;
    for (final entry in dailyExpenseMap.entries) {
      if (entry.value > peakAmt) {
        peakAmt = entry.value;
        peakDay = entry.key;
      }
    }

    int frugalDay = 1;
    double minAmt = double.infinity;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (int d = 1; d <= daysInMonth; d++) {
      final amt = dailyExpenseMap[d] ?? 0;
      if (amt < minAmt) {
        minAmt = amt;
        frugalDay = d;
      }
    }

    final expenseDiff = prevExpense > 0 ? ((expense - prevExpense) / prevExpense * 100) : 0.0;

    // Financial personality
    String personaTitle;
    String personaEmoji;
    String summary;

    if (savingsRate >= 40) {
      personaTitle = 'Sang Master Penabung';
      personaEmoji = '👑';
      summary = 'Luar biasa! Anda berhasil menyisihkan ${savingsRate.toStringAsFixed(1)}% dari total penghasilan bulan ini.';
    } else if (savingsRate >= 15) {
      personaTitle = 'Manajer Keuangan Bijak';
      personaEmoji = '⚖️';
      summary = 'Arus kas sehat dan terkendali dengan rasio tabungan stabil di ${savingsRate.toStringAsFixed(1)}%.';
    } else if (netSavings >= 0) {
      personaTitle = 'Penjelajah Keseimbangan';
      personaEmoji = '🧗';
      summary = 'Pengeluaran hampir seimbang dengan pemasukan. Tingkatkan alokasi tabungan untuk dana darurat.';
    } else {
      personaTitle = 'Si Hobi Belanja Ekspresif';
      personaEmoji = '🛍️';
      summary = 'Pengeluaran melebihi pemasukan bulan ini. Kategori "$topCat" menjadi porsi terbesar (${topCatPercent.toStringAsFixed(0)}%).';
    }

    return MonthlyRecapData(
      year: year,
      month: month,
      totalIncome: income,
      totalExpense: expense,
      netSavings: netSavings,
      savingsRate: savingsRate,
      topExpenseCategory: topCat,
      topExpenseCategoryAmount: topCatAmt,
      topExpenseCategoryPercent: topCatPercent,
      mostExpensiveDayOfMonth: peakDay,
      mostExpensiveDayAmount: peakAmt,
      mostFrugalDayOfMonth: frugalDay,
      transactionCount: currentTx.length,
      prevMonthExpense: prevExpense,
      expenseChangePercent: expenseDiff,
      personalityTitle: personaTitle,
      personalityEmoji: personaEmoji,
      keyInsightSummary: summary,
    );
  }
}
