import 'package:uuid/uuid.dart';

class WalletModel {
  final String id;
  final String name;
  final String emoji;
  final int colorValue;
  final bool isDefault;
  final DateTime createdAt;

  WalletModel({
    String? id,
    required this.name,
    this.emoji = '💰',
    this.colorValue = 0xFF0D9373,
    this.isDefault = false,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'colorValue': colorValue,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'] as String,
      name: map['name'] as String,
      emoji: map['emoji'] as String? ?? '💰',
      colorValue: map['colorValue'] as int? ?? 0xFF0D9373,
      isDefault: (map['isDefault'] as int? ?? 0) == 1,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }

  WalletModel copyWith({
    String? id,
    String? name,
    String? emoji,
    int? colorValue,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Preset wallet colors
  static const List<int> presetColors = [
    0xFF0D9373, // Teal
    0xFF3B82F6, // Blue
    0xFFF59E0B, // Amber
    0xFFEF4444, // Red
    0xFF8B5CF6, // Purple
    0xFFEC4899, // Pink
    0xFF06B6D4, // Cyan
    0xFFF97316, // Orange
  ];

  /// Preset wallet emojis
  static const List<String> presetEmojis = [
    '💰',
    '💳',
    '🏦',
    '💵',
    '🪙',
    '💎',
    '🐷',
    '🎯',
    '📱',
    '🏠',
    '✈️',
    '🎓',
    '🏥',
    '🛒',
    '🎮',
    '📊',
  ];
}
