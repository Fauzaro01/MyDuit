import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/services/receipt_parser_service.dart';

void main() {
  group('ReceiptParserService', () {
    test('extracts merchant, amount, date and category for Indomaret receipt', () {
      const sample = '''
INDOMARET KEMANG
JL. KEMANG RAYA NO. 10
15/09/2026
1x ROTI TAWAR Rp 15.000
2x ULTRA MILK Rp 14.000
TOTAL BELANJA Rp 29.000
TUNAI Rp 50.000
KEMBALI Rp 21.000
''';
      final parsed = ReceiptParserService.parse(sample);

      expect(parsed.merchantName?.toLowerCase(), contains('indomaret'));
      expect(parsed.totalAmount, 29000.0);
      expect(parsed.suggestedCategory, TransactionCategory.shopping);
      expect(parsed.suggestedType, TransactionType.expense);
      expect(parsed.date?.day, 15);
      expect(parsed.date?.month, 9);
      expect(parsed.date?.year, 2026);
    });

    test('extracts Starbucks receipt with Food category', () {
      const sample = '''
STARBUCKS COFFEE
GRAND INDONESIA
10-08-2026
1x Caffe Latte 58.000
Grand Total 58.000
''';
      final parsed = ReceiptParserService.parse(sample);

      expect(parsed.merchantName?.toLowerCase(), contains('starbucks'));
      expect(parsed.totalAmount, 58000.0);
      expect(parsed.suggestedCategory, TransactionCategory.food);
    });

    test('extracts textual Indonesian date from receipt line', () {
      const sample = '''
ALFAMART
24 Februari 2026
Total 45.000
''';
      final parsed = ReceiptParserService.parse(sample);
      expect(parsed.date?.day, 24);
      expect(parsed.date?.month, 2);
      expect(parsed.date?.year, 2026);
    });

    test('handles empty or broken receipt gracefully', () {
      final parsed = ReceiptParserService.parse('');
      expect(parsed.rawText, '');
      expect(parsed.merchantName, isNull);
    });
  });
}
