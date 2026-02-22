import 'package:uuid/uuid.dart';

enum TransactionType { income, expense }

enum TransactionCategory {
  salary,
  freelance,
  investment,
  gift,
  food,
  transport,
  shopping,
  bills,
  entertainment,
  health,
  education,
  travel,
  other,
}

extension TransactionCategoryExtension on TransactionCategory {
  String get label {
    switch (this) {
      case TransactionCategory.salary:
        return 'Gaji';
      case TransactionCategory.freelance:
        return 'Freelance';
      case TransactionCategory.investment:
        return 'Investasi';
      case TransactionCategory.gift:
        return 'Hadiah';
      case TransactionCategory.food:
        return 'Makanan';
      case TransactionCategory.transport:
        return 'Transportasi';
      case TransactionCategory.shopping:
        return 'Belanja';
      case TransactionCategory.bills:
        return 'Tagihan';
      case TransactionCategory.entertainment:
        return 'Hiburan';
      case TransactionCategory.health:
        return 'Kesehatan';
      case TransactionCategory.education:
        return 'Pendidikan';
      case TransactionCategory.travel:
        return 'Perjalanan';
      case TransactionCategory.other:
        return 'Lainnya';
    }
  }

  String get icon {
    switch (this) {
      case TransactionCategory.salary:
        return '💰';
      case TransactionCategory.freelance:
        return '💻';
      case TransactionCategory.investment:
        return '📈';
      case TransactionCategory.gift:
        return '🎁';
      case TransactionCategory.food:
        return '🍔';
      case TransactionCategory.transport:
        return '🚗';
      case TransactionCategory.shopping:
        return '🛍️';
      case TransactionCategory.bills:
        return '📄';
      case TransactionCategory.entertainment:
        return '🎮';
      case TransactionCategory.health:
        return '🏥';
      case TransactionCategory.education:
        return '📚';
      case TransactionCategory.travel:
        return '✈️';
      case TransactionCategory.other:
        return '📌';
    }
  }

  bool get isIncomeCategory {
    switch (this) {
      case TransactionCategory.salary:
      case TransactionCategory.freelance:
      case TransactionCategory.investment:
      case TransactionCategory.gift:
        return true;
      default:
        return false;
    }
  }
}

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final String? note;

  TransactionModel({
    String? id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.index,
      'category': category.index,
      'date': date.millisecondsSinceEpoch,
      'note': note,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values[map['type'] as int],
      category: TransactionCategory.values[map['category'] as int],
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      note: map['note'] as String?,
    );
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    DateTime? date,
    String? note,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
