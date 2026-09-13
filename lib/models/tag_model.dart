import 'package:uuid/uuid.dart';

class TagModel {
  final String id;
  final String name;
  final int colorValue;
  final DateTime createdAt;

  TagModel({
    String? id,
    required this.name,
    this.colorValue = 0xFF0D9373,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory TagModel.fromMap(Map<String, dynamic> map) {
    return TagModel(
      id: map['id'] as String,
      name: map['name'] as String,
      colorValue: map['colorValue'] as int? ?? 0xFF0D9373,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  TagModel copyWith({
    String? id,
    String? name,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return TagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
