import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/receipt_data.dart';
import 'package:myduit/services/receipt_validation_service.dart';

void main() {
  group('ReceiptValidationService', () {
    test('a fully consistent receipt produces no issues', () {
      final data = ReceiptData(
        merchantName: 'Toko Maju',
        totalAmount: 20000,
        subtotalAmount: 20000,
        date: DateTime(2026, 1, 1),
        items: const [ReceiptItem(name: 'Gula', totalPrice: 20000)],
        isMathConsistent: true,
        confidenceScore: 0.9,
        rawText: 'dummy',
      );

      final issues = ReceiptValidationService.validate(data);
      expect(issues, isEmpty);
    });

    test('flags missing total as a warning', () {
      final data = ReceiptData(rawText: 'dummy');
      final issues = ReceiptValidationService.validate(data);
      expect(
        issues.any(
          (i) =>
              i.severity == ValidationSeverity.warning &&
              i.message.contains('Total'),
        ),
        isTrue,
      );
    });

    test('flags missing date as a warning', () {
      final data = ReceiptData(
        totalAmount: 10000,
        confidenceScore: 0.9,
        rawText: 'dummy',
      );
      final issues = ReceiptValidationService.validate(data);
      expect(issues.any((i) => i.message.contains('Tanggal')), isTrue);
    });

    test(
      'flags math inconsistency between subtotal/discount/tax and total',
      () {
        final data = ReceiptData(
          totalAmount: 50000,
          subtotalAmount: 20000,
          date: DateTime(2026, 1, 1),
          isMathConsistent: false,
          confidenceScore: 0.9,
          rawText: 'dummy',
        );
        final issues = ReceiptValidationService.validate(data);
        expect(
          issues.any((i) => i.message.contains('cocok dengan total')),
          isTrue,
        );
      },
    );

    test('does not flag math inconsistency when subtotal is absent', () {
      final data = ReceiptData(
        totalAmount: 50000,
        date: DateTime(2026, 1, 1),
        isMathConsistent: false,
        confidenceScore: 0.9,
        rawText: 'dummy',
      );
      final issues = ReceiptValidationService.validate(data);
      expect(
        issues.any((i) => i.message.contains('cocok dengan total')),
        isFalse,
      );
    });

    test('flags an item larger than the receipt total', () {
      final data = ReceiptData(
        totalAmount: 10000,
        date: DateTime(2026, 1, 1),
        items: const [ReceiptItem(name: 'Barang Aneh', totalPrice: 999999)],
        confidenceScore: 0.9,
        rawText: 'dummy',
      );
      final issues = ReceiptValidationService.validate(data);
      expect(
        issues.any(
          (i) =>
              i.severity == ValidationSeverity.warning &&
              i.message.contains('Barang Aneh'),
        ),
        isTrue,
      );
    });

    test('flags an item with invalid (non-positive) nominal as an error', () {
      final data = ReceiptData(
        totalAmount: 10000,
        date: DateTime(2026, 1, 1),
        items: const [ReceiptItem(name: 'Item Rusak', totalPrice: 0)],
        confidenceScore: 0.9,
        rawText: 'dummy',
      );
      final issues = ReceiptValidationService.validate(data);
      expect(
        issues.any(
          (i) =>
              i.severity == ValidationSeverity.error &&
              i.message.contains('Item Rusak'),
        ),
        isTrue,
      );
    });

    test('flags negative discount/tax amounts as errors', () {
      final data = ReceiptData(
        totalAmount: 10000,
        date: DateTime(2026, 1, 1),
        discounts: const [ReceiptDiscount(name: 'Promo Aneh', amount: -500)],
        taxes: const [ReceiptTax(name: 'Pajak Aneh', amount: -100)],
        confidenceScore: 0.9,
        rawText: 'dummy',
      );
      final issues = ReceiptValidationService.validate(data);
      expect(
        issues.where((i) => i.severity == ValidationSeverity.error).length,
        greaterThanOrEqualTo(2),
      );
    });

    test('flags conflicting totals as a warning', () {
      final data = ReceiptData(
        totalAmount: 10000,
        date: DateTime(2026, 1, 1),
        hasConflictingTotals: true,
        confidenceScore: 0.9,
        rawText: 'dummy',
      );
      final issues = ReceiptValidationService.validate(data);
      expect(
        issues.any((i) => i.message.contains('lebih dari satu nominal total')),
        isTrue,
      );
    });

    test('flags low confidence score as a warning', () {
      final data = ReceiptData(
        totalAmount: 10000,
        date: DateTime(2026, 1, 1),
        confidenceScore: 0.2,
        rawText: 'dummy',
      );
      final issues = ReceiptValidationService.validate(data);
      expect(issues.any((i) => i.message.contains('kurang yakin')), isTrue);
    });
  });
}
