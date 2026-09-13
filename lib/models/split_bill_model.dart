import 'package:uuid/uuid.dart';

class SplitParticipant {
  final String id;
  final String billId;
  final String name;
  final double amount;
  final bool isPaid;
  final String? debtId;

  SplitParticipant({
    String? id,
    required this.billId,
    required this.name,
    required this.amount,
    this.isPaid = false,
    this.debtId,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billId': billId,
      'name': name,
      'amount': amount,
      'isPaid': isPaid ? 1 : 0,
      'debtId': debtId,
    };
  }

  factory SplitParticipant.fromMap(Map<String, dynamic> map) {
    return SplitParticipant(
      id: map['id'] as String,
      billId: map['billId'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      isPaid: (map['isPaid'] as int? ?? 0) == 1,
      debtId: map['debtId'] as String?,
    );
  }

  SplitParticipant copyWith({
    String? id,
    String? billId,
    String? name,
    double? amount,
    bool? isPaid,
    String? debtId,
  }) {
    return SplitParticipant(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      debtId: debtId ?? this.debtId,
    );
  }
}

class SplitBillModel {
  final String id;
  final String title;
  final double totalAmount;
  final DateTime date;
  final bool isSettled;
  final String? note;
  final double taxPercent;
  final double servicePercent;
  final List<SplitParticipant> participants;

  SplitBillModel({
    String? id,
    required this.title,
    required this.totalAmount,
    DateTime? date,
    this.isSettled = false,
    this.note,
    this.taxPercent = 0.0,
    this.servicePercent = 0.0,
    this.participants = const [],
  }) : id = id ?? const Uuid().v4(),
       date = date ?? DateTime.now();

  double get paidTotal =>
      participants.where((p) => p.isPaid).fold(0.0, (sum, p) => sum + p.amount);

  double get remainingTotal =>
      (totalAmount - paidTotal).clamp(0.0, double.infinity);

  bool get isFullyPaid =>
      isSettled || (totalAmount > 0 && paidTotal >= totalAmount);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'totalAmount': totalAmount,
      'date': date.millisecondsSinceEpoch,
      'isSettled': isSettled ? 1 : 0,
      'note': note,
      'taxPercent': taxPercent,
      'servicePercent': servicePercent,
    };
  }

  factory SplitBillModel.fromMap(
    Map<String, dynamic> map, {
    List<SplitParticipant> participants = const [],
  }) {
    return SplitBillModel(
      id: map['id'] as String,
      title: map['title'] as String,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(
        map['date'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isSettled: (map['isSettled'] as int? ?? 0) == 1,
      note: map['note'] as String?,
      taxPercent: (map['taxPercent'] as num? ?? 0.0).toDouble(),
      servicePercent: (map['servicePercent'] as num? ?? 0.0).toDouble(),
      participants: participants,
    );
  }

  SplitBillModel copyWith({
    String? id,
    String? title,
    double? totalAmount,
    DateTime? date,
    bool? isSettled,
    String? note,
    double? taxPercent,
    double? servicePercent,
    List<SplitParticipant>? participants,
  }) {
    return SplitBillModel(
      id: id ?? this.id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      isSettled: isSettled ?? this.isSettled,
      note: note ?? this.note,
      taxPercent: taxPercent ?? this.taxPercent,
      servicePercent: servicePercent ?? this.servicePercent,
      participants: participants ?? this.participants,
    );
  }
}
