import 'package:uuid/uuid.dart';

enum DebtType { iOwe, owedToMe }

extension DebtTypeExtension on DebtType {
  String get label {
    switch (this) {
      case DebtType.iOwe:
        return 'Hutang Saya';
      case DebtType.owedToMe:
        return 'Piutang Saya';
    }
  }

  String get shortLabel {
    switch (this) {
      case DebtType.iOwe:
        return 'Hutang';
      case DebtType.owedToMe:
        return 'Piutang';
    }
  }

  String get emoji {
    switch (this) {
      case DebtType.iOwe:
        return '📤';
      case DebtType.owedToMe:
        return '📥';
    }
  }
}

class DebtModel {
  final String id;
  final String personName;
  final double amount;
  final double paidAmount;
  final DebtType type;
  final String? note;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool isSettled;

  DebtModel({
    String? id,
    required this.personName,
    required this.amount,
    this.paidAmount = 0,
    required this.type,
    this.note,
    DateTime? createdAt,
    this.dueDate,
    this.isSettled = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  double get remainingAmount =>
      (amount - paidAmount).clamp(0.0, double.infinity);

  double get progressPercent =>
      amount > 0 ? (paidAmount / amount).clamp(0.0, 1.0) : 0.0;

  bool get isFullyPaid => paidAmount >= amount;

  bool get isOverdue =>
      dueDate != null && !isSettled && DateTime.now().isAfter(dueDate!);

  int? get daysUntilDue {
    if (dueDate == null || isSettled) return null;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'amount': amount,
      'paidAmount': paidAmount,
      'type': type.index,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'isSettled': isSettled ? 1 : 0,
    };
  }

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] as String,
      personName: map['personName'] as String,
      amount: (map['amount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num? ?? 0).toDouble(),
      type: DebtType.values[map['type'] as int],
      note: map['note'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int)
          : null,
      isSettled: (map['isSettled'] as int? ?? 0) == 1,
    );
  }

  DebtModel copyWith({
    String? id,
    String? personName,
    double? amount,
    double? paidAmount,
    DebtType? type,
    String? note,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isSettled,
  }) {
    return DebtModel(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      type: type ?? this.type,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isSettled: isSettled ?? this.isSettled,
    );
  }
}
