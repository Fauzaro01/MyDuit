import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/services/receipt_parser_service.dart';

void main() {
  group('ReceiptParserService Overhaul Suite', () {
    test('extracts Indomaret receipt with itemized lines, discount, PPN, and math check', () {
      const sample = '''
INDOMARET KEMANG RAYA
JL. KEMANG RAYA NO. 10
15/09/2026 14:30:00 WIB
--------------------------------
1x ROTI TAWAR Rp 15.000
2x ULTRA MILK Rp 14.000
SUBTOTAL Rp 29.000
PROMO HEMAT MEMBER Rp 2.000
PPN 11% Rp 2.970
TOTAL BAYAR Rp 29.970
TUNAI Rp 50.000
KEMBALI Rp 20.030
--------------------------------
TERIMA KASIH TELAH BERBELANJA
''';
      final parsed = ReceiptParserService.parse(sample);

      expect(parsed.merchantName?.toLowerCase(), contains('indomaret'));
      expect(parsed.totalAmount, 29970.0);
      expect(parsed.subtotalAmount, 29000.0);
      expect(parsed.suggestedCategory, TransactionCategory.shopping);
      expect(parsed.suggestedType, TransactionType.expense);
      expect(parsed.date?.day, 15);
      expect(parsed.date?.month, 9);
      expect(parsed.date?.year, 2026);
      expect(parsed.date?.hour, 14);
      expect(parsed.date?.minute, 30);
      expect(parsed.paymentMethod, 'Tunai');
      expect(parsed.detectedWalletKeyword, 'tunai');

      // Check extracted items
      expect(parsed.items.length, greaterThanOrEqualTo(2));
      expect(parsed.discounts.length, 1);
      expect(parsed.discounts.first.amount, 2000.0);
      expect(parsed.taxes.length, 1);
      expect(parsed.taxes.first.amount, 2970.0);

      // Check math & confidence
      expect(parsed.isMathConsistent, isTrue);
      expect(parsed.confidenceScore, greaterThanOrEqualTo(0.8));
      expect(parsed.confidenceLabel, 'Tinggi');
    });

    test('extracts Starbucks receipt with Food category, QRIS, and service/tax', () {
      const sample = '''
STARBUCKS COFFEE
GRAND INDONESIA MALL
10-08-2026 09:15
1x Caffe Latte 58.000
1x Croissant 35.000
SUB TOTAL 93.000
SERVICE CHARGE 5% 4.650
PB1 10% 9.765
GRAND TOTAL 107.415
QRIS PAYMENT
''';
      final parsed = ReceiptParserService.parse(sample);

      expect(parsed.merchantName?.toLowerCase(), contains('starbucks'));
      expect(parsed.totalAmount, 107415.0);
      expect(parsed.suggestedCategory, TransactionCategory.food);
      expect(parsed.paymentMethod, 'QRIS');
      expect(parsed.detectedWalletKeyword, 'qris');
      expect(parsed.taxes.length, 2);
      expect(parsed.isMathConsistent, isTrue);
      expect(parsed.confidenceScore, greaterThanOrEqualTo(0.8));
    });

    test('extracts SPBU Pertamina receipt with Transport category and BCA Debit', () {
      const sample = '''
SPBU PERTAMINA 31.12345
JL. MT HARYONO KAV 10
2026-09-01 08:45
PERTAMAX TURBO
TOTAL Rp 350.000
DEBIT BCA
''';
      final parsed = ReceiptParserService.parse(sample);

      expect(parsed.merchantName?.toLowerCase(), contains('pertamina'));
      expect(parsed.totalAmount, 350000.0);
      expect(parsed.suggestedCategory, TransactionCategory.transport);
      expect(parsed.paymentMethod, 'Debit BCA');
      expect(parsed.detectedWalletKeyword, 'bca');
      expect(parsed.date?.day, 1);
      expect(parsed.date?.month, 9);
      expect(parsed.date?.year, 2026);
    });

    test('extracts PLN Token receipt with Bills category', () {
      const sample = '''
STRUK PEMBELIAN TOKEN PLN
12 Agustus 2026
NO METER: 1234567890
TOTAL BAYAR: Rp 202.500
ADMIN BANK: Rp 2.500
GOPAY
''';
      final parsed = ReceiptParserService.parse(sample);

      expect(parsed.merchantName?.toLowerCase(), contains('pln'));
      expect(parsed.totalAmount, 202500.0);
      expect(parsed.suggestedCategory, TransactionCategory.bills);
      expect(parsed.date?.day, 12);
      expect(parsed.date?.month, 8);
      expect(parsed.date?.year, 2026);
      expect(parsed.paymentMethod, 'GoPay');
      expect(parsed.detectedWalletKeyword, 'gopay');
    });

    test('resilient to OCR noise and character substitutions (l, O, S, B, Z)', () {
      const sample = '''
ALFAMART
24-Feb-2026
TOTAL Rp l5O.OOO
''';
      final parsed = ReceiptParserService.parse(sample);

      expect(parsed.merchantName?.toLowerCase(), contains('alfamart'));
      expect(parsed.totalAmount, 150000.0);
      expect(parsed.date?.day, 24);
      expect(parsed.date?.month, 2);
      expect(parsed.date?.year, 2026);
      expect(parsed.suggestedCategory, TransactionCategory.shopping);
    });

    test('handles empty or broken receipt gracefully', () {
      final parsed = ReceiptParserService.parse('');
      expect(parsed.rawText, '');
      expect(parsed.merchantName, isNull);
      expect(parsed.totalAmount, isNull);
      expect(parsed.confidenceScore, 0.0);
      expect(parsed.confidenceLabel, 'Perlu Diperiksa');
    });
  });
}
