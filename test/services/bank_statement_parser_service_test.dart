import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/services/bank_statement_parser_service.dart';

void main() {
  group('BankStatementParserService', () {
    test('parses BCA CSV rows and detects income/expense', () {
      const bcaCsv = '''
TGL,KETERANGAN,CBG,MUTASI,SALDO
12/09/2026,TRSF E-BANKING DB 12345/FAUZAN,0000,500.000,10.000.000
13/09/2026,TRANSFER CR DARI PT ABC,0000,5.000.000 CR,15.000.000
''';
      final items = BankStatementParserService.parse(
        rawText: bcaCsv,
        preset: BankPreset.bca,
      );

      expect(items.length, 2);
      expect(items[0].type, TransactionType.expense);
      expect(items[0].amount, 500000.0);
      expect(items[1].type, TransactionType.income);
      expect(items[1].amount, 5000000.0);
    });

    test('parses Universal CSV with flexible columns', () {
      const universalCsv = '''
Tanggal,Judul,Jumlah,Tipe
10/09/2026,Gaji Pokok,8000000,Masuk
11/09/2026,Makan Siang,45000,Keluar
''';
      final items = BankStatementParserService.parse(
        rawText: universalCsv,
        preset: BankPreset.universal,
      );

      expect(items.length, 2);
      expect(items[0].type, TransactionType.income);
      expect(items[0].amount, 8000000.0);
      expect(items[1].type, TransactionType.expense);
      expect(items[1].amount, 45000.0);
      expect(items[1].category, TransactionCategory.food);
    });
  });
}
