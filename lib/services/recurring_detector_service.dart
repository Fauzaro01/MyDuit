import '../models/transaction_model.dart';
import '../models/recurring_transaction_model.dart';

class DetectedRecurringPattern {
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String? customCategoryId;
  final String? walletId;
  final RecurrenceFrequency frequency;
  final int occurrenceCount;
  final double confidence; // 0.0 to 1.0
  final DateTime nextEstimatedDate;

  DetectedRecurringPattern({
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.customCategoryId,
    this.walletId,
    required this.frequency,
    required this.occurrenceCount,
    required this.confidence,
    required this.nextEstimatedDate,
  });
}

class RecurringDetectorService {
  /// Analyzes transaction history to find recurring patterns (e.g. monthly subscriptions, regular rent, weekly bills)
  static List<DetectedRecurringPattern> detectPatterns(
    List<TransactionModel> transactions, {
    List<RecurringTransactionModel> existingRecurring = const [],
  }) {
    if (transactions.length < 2) return [];

    // Group transactions by normalized title and type
    final grouped = <String, List<TransactionModel>>{};
    for (final tx in transactions) {
      final key = '${tx.type.name}_${tx.title.trim().toLowerCase()}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final patterns = <DetectedRecurringPattern>[];

    for (final entry in grouped.entries) {
      final list = entry.value;
      if (list.length < 2) continue;

      // Sort by date ascending
      list.sort((a, b) => a.date.compareTo(b.date));

      // Calculate intervals in days between consecutive occurrences
      final intervals = <int>[];
      for (int i = 1; i < list.length; i++) {
        final days = list[i].date.difference(list[i - 1].date).inDays;
        if (days > 0) intervals.add(days);
      }

      if (intervals.isEmpty) continue;

      // Determine candidate frequency based on average interval
      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      RecurrenceFrequency? freq;

      if (avgInterval >= 6 && avgInterval <= 9) {
        freq = RecurrenceFrequency.weekly;
      } else if (avgInterval >= 25 && avgInterval <= 35) {
        freq = RecurrenceFrequency.monthly;
      } else if (avgInterval >= 350 && avgInterval <= 380) {
        freq = RecurrenceFrequency.yearly;
      }

      if (freq == null) continue;

      // Check amount consistency (within 15% variation)
      final amounts = list.map((t) => t.amount).toList();
      final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
      final isAmountConsistent = amounts.every((a) => (a - avgAmount).abs() <= avgAmount * 0.15);

      if (!isAmountConsistent && list.length < 3) continue;

      final lastTx = list.last;

      // Check if already registered as recurring
      final alreadyExists = existingRecurring.any((r) =>
          r.title.trim().toLowerCase() == lastTx.title.trim().toLowerCase() &&
          r.type == lastTx.type);

      if (alreadyExists) continue;

      // Calculate confidence
      double confidence = 0.5;
      if (isAmountConsistent) confidence += 0.3;
      if (list.length >= 3) confidence += 0.2;
      confidence = confidence.clamp(0.0, 1.0);

      DateTime nextDate = lastTx.date;
      if (freq == RecurrenceFrequency.weekly) {
        nextDate = lastTx.date.add(const Duration(days: 7));
      } else if (freq == RecurrenceFrequency.monthly) {
        nextDate = DateTime(lastTx.date.year, lastTx.date.month + 1, lastTx.date.day);
      } else if (freq == RecurrenceFrequency.yearly) {
        nextDate = DateTime(lastTx.date.year + 1, lastTx.date.month, lastTx.date.day);
      }

      patterns.add(
        DetectedRecurringPattern(
          title: lastTx.title,
          amount: avgAmount,
          type: lastTx.type,
          category: lastTx.category,
          customCategoryId: lastTx.customCategoryId,
          walletId: lastTx.walletId,
          frequency: freq,
          occurrenceCount: list.length,
          confidence: confidence,
          nextEstimatedDate: nextDate,
        ),
      );
    }

    // Sort by confidence and occurrence count descending
    patterns.sort((a, b) => (b.confidence * b.occurrenceCount).compareTo(a.confidence * a.occurrenceCount));
    return patterns;
  }
}
