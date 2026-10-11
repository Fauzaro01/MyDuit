import 'package:uuid/uuid.dart';

enum CategoryBucket {
  needs('Kebutuhan (Needs)'),
  wants('Keinginan (Wants)'),
  savings('Tabungan / Investasi (Savings)');

  final String label;
  const CategoryBucket(this.label);
}

class CustomCategoryModel {
  final String id;
  final String name;
  final String emoji;
  final bool isIncome; // true = income, false = expense
  final int colorValue;
  final int createdAt;
  final CategoryBucket? bucket;

  CustomCategoryModel({
    String? id,
    required this.name,
    required this.emoji,
    required this.isIncome,
    this.colorValue = 0xFF0D9373,
    int? createdAt,
    this.bucket,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'isIncome': isIncome ? 1 : 0,
      'colorValue': colorValue,
      'createdAt': createdAt,
      'bucket': bucket?.name,
    };
  }

  factory CustomCategoryModel.fromMap(Map<String, dynamic> map) {
    return CustomCategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      emoji: map['emoji'] as String,
      isIncome: (map['isIncome'] as int) == 1,
      colorValue: map['colorValue'] as int,
      createdAt: map['createdAt'] as int,
      bucket: map['bucket'] != null
          ? CategoryBucket.values
              .where((b) => b.name == map['bucket'])
              .firstOrNull
          : null,
    );
  }

  CustomCategoryModel copyWith({
    String? name,
    String? emoji,
    bool? isIncome,
    int? colorValue,
    CategoryBucket? bucket,
  }) {
    return CustomCategoryModel(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      isIncome: isIncome ?? this.isIncome,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      bucket: bucket ?? this.bucket,
    );
  }
}

class CustomCategoryUsage {
  final int transactionCount;
  final int budgetCount;
  final int recurringCount;

  const CustomCategoryUsage({
    this.transactionCount = 0,
    this.budgetCount = 0,
    this.recurringCount = 0,
  });

  int get totalUsage => transactionCount + budgetCount + recurringCount;
}

