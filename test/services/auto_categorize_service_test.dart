import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/services/auto_categorize_service.dart';

void main() {
  group('AutoCategorizeService Tests', () {
    test('returns null for empty or unknown text', () {
      expect(AutoCategorizeService.suggest(''), isNull);
      expect(AutoCategorizeService.suggest('   '), isNull);
      expect(AutoCategorizeService.suggest('xyz random 12345'), isNull);
    });

    test('categorizes food keywords accurately', () {
      final s1 = AutoCategorizeService.suggest('Makan siang di warung padang');
      expect(s1, isNotNull);
      expect(s1!.category, TransactionCategory.food);
      expect(s1.type, TransactionType.expense);

      final s2 = AutoCategorizeService.suggest('Beli Kopi Kenangan & snack');
      expect(s2, isNotNull);
      expect(s2!.category, TransactionCategory.food);
      expect(s2.type, TransactionType.expense);

      final s3 = AutoCategorizeService.suggest('Order GoFood');
      expect(s3, isNotNull);
      expect(s3!.category, TransactionCategory.food);
    });

    test('categorizes transport keywords accurately', () {
      final s1 = AutoCategorizeService.suggest('Beli Pertalite motor');
      expect(s1, isNotNull);
      expect(s1!.category, TransactionCategory.transport);
      expect(s1.type, TransactionType.expense);

      final s2 = AutoCategorizeService.suggest('Tiket MRT & KRL');
      expect(s2, isNotNull);
      expect(s2!.category, TransactionCategory.transport);
    });

    test('categorizes bills keywords accurately', () {
      final s1 = AutoCategorizeService.suggest('Bayar tagihan listrik PLN');
      expect(s1, isNotNull);
      expect(s1!.category, TransactionCategory.bills);
      expect(s1.type, TransactionType.expense);

      final s2 = AutoCategorizeService.suggest('Langganan IndiHome bulanan');
      expect(s2, isNotNull);
      expect(s2!.category, TransactionCategory.bills);
    });

    test('categorizes shopping keywords accurately', () {
      final s1 = AutoCategorizeService.suggest('Belanja di Tokopedia');
      expect(s1, isNotNull);
      expect(s1!.category, TransactionCategory.shopping);
      expect(s1.type, TransactionType.expense);

      final s2 = AutoCategorizeService.suggest('Beli skincare di Shopee');
      expect(s2, isNotNull);
      expect(s2!.category, TransactionCategory.shopping);
    });

    test('categorizes income keywords accurately', () {
      final s1 = AutoCategorizeService.suggest('Gaji PT Maju Mundur');
      expect(s1, isNotNull);
      expect(s1!.category, TransactionCategory.salary);
      expect(s1.type, TransactionType.income);

      final s2 = AutoCategorizeService.suggest('Pembayaran freelance website');
      expect(s2, isNotNull);
      expect(s2!.category, TransactionCategory.freelance);
      expect(s2.type, TransactionType.income);

      final s3 = AutoCategorizeService.suggest('Bonus THR kantor');
      expect(s3, isNotNull);
      expect(s3!.category, TransactionCategory.salary);
      expect(s3.type, TransactionType.income);
    });
  });
}
