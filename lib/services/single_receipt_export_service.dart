import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';

class SingleReceiptExportService {
  /// Generate and share a clean visual single receipt slip PDF
  static Future<void> exportAndShareReceipt(
    TransactionModel transaction, {
    String? walletName,
    String? categoryName,
  }) async {
    final pdf = pw.Document();
    final isIncome = transaction.type == TransactionType.income;
    final catName = categoryName ?? transaction.category.label;

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          160 * PdfPageFormat.mm,
          marginAll: 10 * PdfPageFormat.mm,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'MyDuit Receipt',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Bukti Transaksi Digital',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 8),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tanggal:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    DateFormatter.fullDate(transaction.date),
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Kategori:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(catName, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              if (walletName != null) ...[
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Dompet:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(walletName, style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 8),

              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  transaction.title,
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
              ),
              if (transaction.note != null && transaction.note!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    transaction.note!,
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ),
              ],
              pw.SizedBox(height: 12),

              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      isIncome ? 'TOTAL DITERIMA' : 'TOTAL BAYAR',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      CurrencyFormatter.format(transaction.amount),
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: isIncome ? PdfColors.green800 : PdfColors.red800,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 6),
              pw.Text(
                'Terima kasih telah mencatat di MyDuit',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
              pw.Text(
                'ID: ${transaction.id}',
                style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey500),
              ),
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/receipt_${transaction.id.substring(0, 8)}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Struk Transaksi: ${transaction.title} (${CurrencyFormatter.format(transaction.amount)})',
    );
  }
}
