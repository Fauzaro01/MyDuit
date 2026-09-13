import 'package:uuid/uuid.dart';

class DebtPaymentModel {
  final String id;
  final String debtId;
  final double amount;
  final DateTime date;
  final String? note;

  DebtPaymentModel({
    String? id,
    required this.debtId,
    required this.amount,
    DateTime? date,
    this.note,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debtId': debtId,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'note': note,
    };
  }

  factory DebtPaymentModel.fromMap(Map<String, dynamic> map) {
    return DebtPaymentModel(
      id: map['id'] as String,
      debtId: map['debtId'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      note: map['note'] as String?,
    );
  }

  DebtPaymentModel copyWith({
    String? id,
    String? debtId,
    double? amount,
    DateTime? date,
    String? note,
  }) {
    return DebtPaymentModel(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
