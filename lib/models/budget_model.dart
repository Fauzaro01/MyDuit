import 'package:uuid/uuid.dart';
import 'transaction_model.dart';

class BudgetModel {
  final String id;
  final TransactionCategory category;
  final double monthlyLimit;
  final int year;
  final int month;

  BudgetModel({
    String? id,
    required this.category,
    required this.monthlyLimit,
    required this.year,
    required this.month,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.index,
      'monthlyLimit': monthlyLimit,
      'year': year,
      'month': month,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      category: TransactionCategory.values[map['category'] as int],
      monthlyLimit: (map['monthlyLimit'] as num).toDouble(),
      year: map['year'] as int,
      month: map['month'] as int,
    );
  }

  BudgetModel copyWith({
    String? id,
    TransactionCategory? category,
    double? monthlyLimit,
    int? year,
    int? month,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }
}
