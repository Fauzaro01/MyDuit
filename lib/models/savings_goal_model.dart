import 'package:uuid/uuid.dart';

class SavingsGoalModel {
  final String id;
  final String title;
  final String emoji;
  final double targetAmount;
  final double currentAmount;
  final DateTime createdAt;
  final DateTime? targetDate;
  final bool isCompleted;

  SavingsGoalModel({
    String? id,
    required this.title,
    this.emoji = '🎯',
    required this.targetAmount,
    this.currentAmount = 0,
    DateTime? createdAt,
    this.targetDate,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get remainingAmount =>
      (targetAmount - currentAmount).clamp(0.0, double.infinity);

  bool get isReached => currentAmount >= targetAmount;

  /// Estimate days remaining based on average daily saving
  int? get estimatedDaysRemaining {
    if (isReached || currentAmount <= 0) return null;
    final daysSinceCreated = DateTime.now()
        .difference(createdAt)
        .inDays
        .clamp(1, 99999);
    final avgPerDay = currentAmount / daysSinceCreated;
    if (avgPerDay <= 0) return null;
    return (remainingAmount / avgPerDay).ceil();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'emoji': emoji,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'targetDate': targetDate?.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) {
    return SavingsGoalModel(
      id: map['id'] as String,
      title: map['title'] as String,
      emoji: map['emoji'] as String? ?? '🎯',
      targetAmount: (map['targetAmount'] as num).toDouble(),
      currentAmount: (map['currentAmount'] as num? ?? 0).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      targetDate: map['targetDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['targetDate'] as int)
          : null,
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
    );
  }

  SavingsGoalModel copyWith({
    String? id,
    String? title,
    String? emoji,
    double? targetAmount,
    double? currentAmount,
    DateTime? createdAt,
    DateTime? targetDate,
    bool? isCompleted,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  static const List<String> presetEmojis = [
    '🎯',
    '🏠',
    '🚗',
    '✈️',
    '📱',
    '💻',
    '🎓',
    '💍',
    '🎮',
    '📷',
    '🏥',
    '👶',
    '🎉',
    '💎',
    '🏦',
    '🛍️',
  ];
}
