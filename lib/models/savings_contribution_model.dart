import 'package:uuid/uuid.dart';

class SavingsContributionModel {
  final String id;
  final String goalId;
  final double amount;
  final DateTime date;
  final String? note;
  final String? walletId; // null = not synced to any wallet

  SavingsContributionModel({
    String? id,
    required this.goalId,
    required this.amount,
    DateTime? date,
    this.note,
    this.walletId,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'note': note,
      'walletId': walletId,
    };
  }

  factory SavingsContributionModel.fromMap(Map<String, dynamic> map) {
    return SavingsContributionModel(
      id: map['id'] as String,
      goalId: map['goalId'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      note: map['note'] as String?,
      walletId: map['walletId'] as String?,
    );
  }

  SavingsContributionModel copyWith({
    String? id,
    String? goalId,
    double? amount,
    DateTime? date,
    String? note,
    String? walletId,
  }) {
    return SavingsContributionModel(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      walletId: walletId ?? this.walletId,
    );
  }
}
