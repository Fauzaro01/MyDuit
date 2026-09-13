import 'package:uuid/uuid.dart';
import 'transaction_model.dart';

class TransactionTemplateModel {
  final String id;
  final String name;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String? customCategoryId;
  final String? walletId;
  final String? note;
  final List<String> tags;
  final String emoji;

  TransactionTemplateModel({
    String? id,
    required this.name,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.customCategoryId,
    this.walletId,
    this.note,
    this.tags = const [],
    this.emoji = '⚡',
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'amount': amount,
      'type': type.index,
      'category': category.index,
      'customCategoryId': customCategoryId,
      'walletId': walletId,
      'note': note,
      'tags': tags.join(','),
      'emoji': emoji,
    };
  }

  factory TransactionTemplateModel.fromMap(Map<String, dynamic> map) {
    return TransactionTemplateModel(
      id: map['id'] as String,
      name: map['name'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values[map['type'] as int],
      category: TransactionCategory.values[map['category'] as int],
      customCategoryId: map['customCategoryId'] as String?,
      walletId: map['walletId'] as String?,
      note: map['note'] as String?,
      tags: (map['tags'] as String?)?.isNotEmpty == true
          ? (map['tags'] as String).split(',').where((t) => t.isNotEmpty).toList()
          : [],
      emoji: map['emoji'] as String? ?? '⚡',
    );
  }

  TransactionTemplateModel copyWith({
    String? id,
    String? name,
    String? title,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    String? customCategoryId,
    String? walletId,
    String? note,
    List<String>? tags,
    String? emoji,
  }) {
    return TransactionTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      customCategoryId: customCategoryId ?? this.customCategoryId,
      walletId: walletId ?? this.walletId,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      emoji: emoji ?? this.emoji,
    );
  }

  static List<TransactionTemplateModel> get defaultTemplates => [
        TransactionTemplateModel(
          id: 'tpl-kopi',
          name: 'Kopi Pagi',
          title: 'Kopi Pagi',
          amount: 25000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          emoji: '☕',
          tags: ['kopi', 'harian'],
        ),
        TransactionTemplateModel(
          id: 'tpl-makan-siang',
          name: 'Makan Siang',
          title: 'Makan Siang',
          amount: 35000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          emoji: '🍛',
          tags: ['makan', 'harian'],
        ),
        TransactionTemplateModel(
          id: 'tpl-bensin',
          name: 'Bensin Motor',
          title: 'Bensin Pertalite/Pertamax',
          amount: 50000,
          type: TransactionType.expense,
          category: TransactionCategory.transport,
          emoji: '⛽',
          tags: ['kendaraan'],
        ),
        TransactionTemplateModel(
          id: 'tpl-parkir',
          name: 'Parkir',
          title: 'Parkir Harian',
          amount: 5000,
          type: TransactionType.expense,
          category: TransactionCategory.transport,
          emoji: '🅿️',
          tags: ['transport'],
        ),
      ];
}
