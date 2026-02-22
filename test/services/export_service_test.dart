import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myduit/models/transaction_model.dart';

// We test the CSV generation logic directly since ExportService.exportToCsv
// depends on path_provider (platform channel). We extract & test the core logic.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  // Helper: replicate the CSV escape logic from ExportService
  String escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // Helper: build CSV content like ExportService does
  String buildCsvContent(List<TransactionModel> transactions) {
    final buffer = StringBuffer();
    buffer.writeln('Tanggal,Judul,Kategori,Tipe,Jumlah,Catatan');

    for (final tx in transactions) {
      final title = escapeCsv(tx.title);
      final category = tx.category.label;
      final type = tx.type == TransactionType.income
          ? 'Pemasukan'
          : 'Pengeluaran';
      final amount = tx.amount.toStringAsFixed(0);
      final note = escapeCsv(tx.note ?? '');

      // We skip date formatting to avoid locale dependency in this unit test
      buffer.writeln('DATE,$title,$category,$type,$amount,$note');
    }
    return buffer.toString();
  }

  group('CSV escape logic', () {
    test('does not escape simple strings', () {
      expect(escapeCsv('Hello'), 'Hello');
    });

    test('escapes strings with commas', () {
      expect(escapeCsv('Hello, World'), '"Hello, World"');
    });

    test('escapes strings with quotes', () {
      expect(escapeCsv('Say "Hi"'), '"Say ""Hi"""');
    });

    test('escapes strings with newlines', () {
      expect(escapeCsv('Line1\nLine2'), '"Line1\nLine2"');
    });

    test('escapes strings with multiple special chars', () {
      expect(escapeCsv('A, "B"\nC'), '"A, ""B""\nC"');
    });

    test('handles empty string', () {
      expect(escapeCsv(''), '');
    });
  });

  group('CSV content generation', () {
    test('generates correct header', () {
      final csv = buildCsvContent([]);
      expect(csv.trim(), 'Tanggal,Judul,Kategori,Tipe,Jumlah,Catatan');
    });

    test('generates row for income transaction', () {
      final tx = TransactionModel(
        id: 'tx-1',
        title: 'Gaji Bulanan',
        amount: 5000000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        date: DateTime(2026, 2, 15),
        note: 'Gaji Feb',
      );

      final csv = buildCsvContent([tx]);
      final lines = csv.trim().split('\n');

      expect(lines.length, 2);
      expect(lines[1], contains('Gaji Bulanan'));
      expect(lines[1], contains('Gaji'));
      expect(lines[1], contains('Pemasukan'));
      expect(lines[1], contains('5000000'));
      expect(lines[1], contains('Gaji Feb'));
    });

    test('generates row for expense transaction', () {
      final tx = TransactionModel(
        id: 'tx-2',
        title: 'Makan Siang',
        amount: 25000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime(2026, 2, 15),
      );

      final csv = buildCsvContent([tx]);
      final lines = csv.trim().split('\n');

      expect(lines.length, 2);
      expect(lines[1], contains('Makan Siang'));
      expect(lines[1], contains('Makanan'));
      expect(lines[1], contains('Pengeluaran'));
      expect(lines[1], contains('25000'));
    });

    test('handles transaction with null note', () {
      final tx = TransactionModel(
        id: 'tx-3',
        title: 'Test',
        amount: 1000,
        type: TransactionType.expense,
        category: TransactionCategory.other,
        date: DateTime(2026, 2, 15),
      );

      final csv = buildCsvContent([tx]);
      // The note field should be empty string (from `tx.note ?? ''`)
      final lines = csv.trim().split('\n');
      expect(lines[1].endsWith(','), isTrue);
    });

    test('handles title with commas (CSV escape)', () {
      final tx = TransactionModel(
        id: 'tx-4',
        title: 'Nasi, Sayur, Lauk',
        amount: 15000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime(2026, 2, 15),
      );

      final csv = buildCsvContent([tx]);
      expect(csv, contains('"Nasi, Sayur, Lauk"'));
    });

    test('generates multiple rows', () {
      final txs = [
        TransactionModel(
          id: 'tx-a',
          title: 'Income 1',
          amount: 1000,
          type: TransactionType.income,
          category: TransactionCategory.salary,
          date: DateTime(2026, 2, 10),
        ),
        TransactionModel(
          id: 'tx-b',
          title: 'Expense 1',
          amount: 500,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(2026, 2, 11),
        ),
        TransactionModel(
          id: 'tx-c',
          title: 'Expense 2',
          amount: 300,
          type: TransactionType.expense,
          category: TransactionCategory.transport,
          date: DateTime(2026, 2, 12),
        ),
      ];

      final csv = buildCsvContent(txs);
      final lines = csv.trim().split('\n');

      // Header + 3 data rows
      expect(lines.length, 4);
    });

    test('amount has no decimal places', () {
      final tx = TransactionModel(
        id: 'tx-dec',
        title: 'Test',
        amount: 1234.56,
        type: TransactionType.expense,
        category: TransactionCategory.other,
        date: DateTime(2026, 2, 15),
      );

      final csv = buildCsvContent([tx]);
      expect(csv, contains('1235')); // toStringAsFixed(0) rounds
      expect(csv, isNot(contains('1234.56')));
    });
  });
}
