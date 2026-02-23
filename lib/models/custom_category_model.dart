import 'package:uuid/uuid.dart';

class CustomCategoryModel {
  final String id;
  final String name;
  final String emoji;
  final bool isIncome; // true = income, false = expense
  final int colorValue;
  final int createdAt;

  CustomCategoryModel({
    String? id,
    required this.name,
    required this.emoji,
    required this.isIncome,
    this.colorValue = 0xFF0D9373,
    int? createdAt,
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
    );
  }

  CustomCategoryModel copyWith({
    String? name,
    String? emoji,
    bool? isIncome,
    int? colorValue,
  }) {
    return CustomCategoryModel(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      isIncome: isIncome ?? this.isIncome,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
    );
  }
}
