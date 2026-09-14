import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../models/custom_category_model.dart';

class CsvExportService {
  static Future<void> exportTransactionsToCsv(
    List<TransactionModel> transactions, {
    List<WalletModel> wallets = const [],
    List<CustomCategoryModel> customCategories = const [],
    String? periodLabel,
  }) async {
    final buffer = StringBuffer();
    // CSV Header with UTF-8 BOM for Excel compatibility
    buffer.write('﻿');
    buffer.writeln('ID,Tanggal,Judul,Tipe,Kategori,Nominal,Dompet,Catatan,Tags');

    final walletMap = {for (final w in wallets) w.id: w.name};
    final customCatMap = {for (final c in customCategories) c.id: c.name};

    for (final tx in transactions) {
      final id = tx.id;
      final date = tx.date.toIso8601String().split('T').first;
      final title = '"${tx.title.replaceAll('"', '""')}"';
      final type =
          tx.type == TransactionType.income ? 'Pemasukan' : 'Pengeluaran';
      final category = (tx.customCategoryId != null &&
              customCatMap.containsKey(tx.customCategoryId))
          ? customCatMap[tx.customCategoryId]!
          : tx.category.label;
      final amount = tx.amount.toStringAsFixed(0);
      final wallet = (tx.walletId != null && walletMap.containsKey(tx.walletId))
          ? '"${walletMap[tx.walletId]!.replaceAll('"', '""')}"'
          : '';
      final note = '"${(tx.note ?? '').replaceAll('"', '""')}"';
      final tags = '"${tx.tags.join(';')}"';

      buffer.writeln(
        '$id,$date,$title,$type,"$category",$amount,$wallet,$note,$tags',
      );
    }

    final tempDir = await getTemporaryDirectory();
    final nowStr = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(tempDir.path, 'myduit_transaksi_$nowStr.csv'));
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Ekspor Transaksi MyDuit ${periodLabel ?? ''}',
    );
  }
}
