import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';

class ExportService {
  static Future<String> exportToCsv(
    List<TransactionModel> transactions, {
    required int year,
    required int month,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('Tanggal,Judul,Kategori,Tipe,Jumlah,Catatan');

    for (final tx in transactions) {
      final date = DateFormatter.fullDate(tx.date);
      final title = _escapeCsv(tx.title);
      final category = tx.category.label;
      final type = tx.type == TransactionType.income
          ? 'Pemasukan'
          : 'Pengeluaran';
      final amount = tx.amount.toStringAsFixed(0);
      final note = _escapeCsv(tx.note ?? '');

      buffer.writeln('$date,$title,$category,$type,$amount,$note');
    }

    final dir = await getApplicationDocumentsDirectory();
    final monthName = DateFormatter.monthYear(year, month).replaceAll(' ', '_');
    final file = File('${dir.path}/MyDuit_$monthName.csv');
    await file.writeAsString(buffer.toString());

    return file.path;
  }

  static Future<void> shareExport(
    List<TransactionModel> transactions, {
    required int year,
    required int month,
  }) async {
    final filePath = await exportToCsv(transactions, year: year, month: month);

    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Laporan Keuangan MyDuit - ${DateFormatter.monthYear(year, month)}',
    );
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
