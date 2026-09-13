import 'package:uuid/uuid.dart';
import 'transaction_model.dart';

class BudgetModel {
  final String id;
  final TransactionCategory category;
  final double monthlyLimit;
  final int year;
  final int month;
  final String? customCategoryId;
  final bool isRollover;

  BudgetModel({
    String? id,
    required this.category,
    required this.monthlyLimit,
    required this.year,
    required this.month,
    this.customCategoryId,
    this.isRollover = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.index,
      'monthlyLimit': monthlyLimit,
      'year': year,
      'month': month,
      'customCategoryId': customCategoryId,
      'isRollover': isRollover ? 1 : 0,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      category: TransactionCategory.values[map['category'] as int],
      monthlyLimit: (map['monthlyLimit'] as num).toDouble(),
      year: map['year'] as int,
      month: map['month'] as int,
      customCategoryId: map['customCategoryId'] as String?,
      isRollover: (map['isRollover'] as int? ?? 0) == 1,
    );
  }

  BudgetModel copyWith({
    String? id,
    TransactionCategory? category,
    double? monthlyLimit,
    int? year,
    int? month,
    String? customCategoryId,
    bool? isRollover,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      year: year ?? this.year,
      month: month ?? this.month,
      customCategoryId: customCategoryId ?? this.customCategoryId,
      isRollover: isRollover ?? this.isRollover,
    );
  }
}
