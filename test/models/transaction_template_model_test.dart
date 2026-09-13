import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/models/transaction_template_model.dart';

void main() {
  group('TransactionTemplateModel Tests', () {
    test('create template with default values', () {
      final tpl = TransactionTemplateModel(
        name: 'Makan Siang',
        title: 'Makan Padang',
        amount: 30000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        emoji: '🍛',
      );

      expect(tpl.id, isNotEmpty);
      expect(tpl.name, 'Makan Siang');
      expect(tpl.title, 'Makan Padang');
      expect(tpl.amount, 30000);
      expect(tpl.type, TransactionType.expense);
      expect(tpl.category, TransactionCategory.food);
      expect(tpl.emoji, '🍛');
    });

    test('toMap and fromMap serialization', () {
      final tpl = TransactionTemplateModel(
        id: 'tpl-1',
        name: 'Bensin',
        title: 'Bensin Motor',
        amount: 50000,
        type: TransactionType.expense,
        category: TransactionCategory.transport,
        walletId: 'wallet-1',
        tags: ['bensin', 'motor'],
        emoji: '⛽',
      );

      final map = tpl.toMap();
      final fromMap = TransactionTemplateModel.fromMap(map);

      expect(fromMap.id, 'tpl-1');
      expect(fromMap.name, 'Bensin');
      expect(fromMap.title, 'Bensin Motor');
      expect(fromMap.amount, 50000);
      expect(fromMap.type, TransactionType.expense);
      expect(fromMap.category, TransactionCategory.transport);
      expect(fromMap.walletId, 'wallet-1');
      expect(fromMap.tags, ['bensin', 'motor']);
      expect(fromMap.emoji, '⛽');
    });

    test('default templates provide valid templates', () {
      final defaults = TransactionTemplateModel.defaultTemplates;
      expect(defaults, isNotEmpty);
      expect(defaults.any((t) => t.id == 'tpl-kopi'), isTrue);
    });

    test('copyWith updates fields correctly', () {
      final tpl = TransactionTemplateModel(
        name: 'Kopi',
        title: 'Kopi Susu',
        amount: 20000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
      );

      final updated = tpl.copyWith(amount: 25000, name: 'Kopi Spesial');
      expect(updated.amount, 25000);
      expect(updated.name, 'Kopi Spesial');
      expect(updated.title, 'Kopi Susu');
    });
  });
}
