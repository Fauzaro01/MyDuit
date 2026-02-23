import 'package:uuid/uuid.dart';
import 'transaction_model.dart';

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

extension RecurrenceFrequencyExtension on RecurrenceFrequency {
  String get label {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Harian';
      case RecurrenceFrequency.weekly:
        return 'Mingguan';
      case RecurrenceFrequency.monthly:
        return 'Bulanan';
      case RecurrenceFrequency.yearly:
        return 'Tahunan';
    }
  }

  String get shortLabel {
    switch (this) {
      case RecurrenceFrequency.daily:
        return '/hari';
      case RecurrenceFrequency.weekly:
        return '/minggu';
      case RecurrenceFrequency.monthly:
        return '/bulan';
      case RecurrenceFrequency.yearly:
        return '/tahun';
    }
  }
}

class RecurringTransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final RecurrenceFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final String? note;
  final String? walletId;
  final bool isActive;
  final DateTime? lastGeneratedDate;

  RecurringTransactionModel({
    String? id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.note,
    this.walletId,
    this.isActive = true,
    this.lastGeneratedDate,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.index,
      'category': category.index,
      'frequency': frequency.index,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'note': note,
      'walletId': walletId,
      'isActive': isActive ? 1 : 0,
      'lastGeneratedDate': lastGeneratedDate?.millisecondsSinceEpoch,
    };
  }

  factory RecurringTransactionModel.fromMap(Map<String, dynamic> map) {
    return RecurringTransactionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values[map['type'] as int],
      category: TransactionCategory.values[map['category'] as int],
      frequency: RecurrenceFrequency.values[map['frequency'] as int],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int),
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int)
          : null,
      note: map['note'] as String?,
      walletId: map['walletId'] as String?,
      isActive: (map['isActive'] as int? ?? 1) == 1,
      lastGeneratedDate: map['lastGeneratedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastGeneratedDate'] as int)
          : null,
    );
  }

  RecurringTransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? note,
    String? walletId,
    bool? isActive,
    DateTime? lastGeneratedDate,
  }) {
    return RecurringTransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      note: note ?? this.note,
      walletId: walletId ?? this.walletId,
      isActive: isActive ?? this.isActive,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
    );
  }

  /// Calculate next occurrence date from a given date
  DateTime nextOccurrence(DateTime from) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        final nextMonth = from.month == 12
            ? DateTime(from.year + 1, 1, from.day)
            : DateTime(from.year, from.month + 1, from.day);
        return nextMonth;
      case RecurrenceFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }
}
