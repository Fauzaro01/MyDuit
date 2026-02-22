import 'package:uuid/uuid.dart';

class TransferModel {
  final String id;
  final String fromWalletId;
  final String toWalletId;
  final double amount;
  final String? note;
  final DateTime date;

  TransferModel({
    String? id,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    this.note,
    DateTime? date,
  }) : id = id ?? const Uuid().v4(),
       date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromWalletId': fromWalletId,
      'toWalletId': toWalletId,
      'amount': amount,
      'note': note,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory TransferModel.fromMap(Map<String, dynamic> map) {
    return TransferModel(
      id: map['id'] as String,
      fromWalletId: map['fromWalletId'] as String,
      toWalletId: map['toWalletId'] as String,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    );
  }

  TransferModel copyWith({
    String? id,
    String? fromWalletId,
    String? toWalletId,
    double? amount,
    String? note,
    DateTime? date,
  }) {
    return TransferModel(
      id: id ?? this.id,
      fromWalletId: fromWalletId ?? this.fromWalletId,
      toWalletId: toWalletId ?? this.toWalletId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }
}
