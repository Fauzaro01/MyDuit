import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';

class PdfExportService {
  static Future<void> exportAndShare(
    List<TransactionModel> transactions, {
    required int year,
    required int month,
    required double totalIncome,
    required double totalExpense,
    required Map<TransactionCategory, double> expenseCategoryTotals,
  }) async {
    final pdf = pw.Document();
    final monthName = DateFormatter.monthYear(year, month);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(monthName),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Summary
          _buildSummarySection(totalIncome, totalExpense),
          pw.SizedBox(height: 16),

          // Category breakdown
          if (expenseCategoryTotals.isNotEmpty) ...[
            _buildCategorySection(expenseCategoryTotals, totalExpense),
            pw.SizedBox(height: 16),
          ],

          // Transaction table
          _buildTransactionTable(transactions),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'MyDuit_${monthName.replaceAll(' ', '_')}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Laporan Keuangan MyDuit - $monthName',
    );
  }

  static Future<void> printReport(
    List<TransactionModel> transactions, {
    required int year,
    required int month,
    required double totalIncome,
    required double totalExpense,
    required Map<TransactionCategory, double> expenseCategoryTotals,
  }) async {
    final monthName = DateFormatter.monthYear(year, month);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.MultiPage(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(32),
            header: (context) => _buildHeader(monthName),
            footer: (context) => _buildFooter(context),
            build: (context) => [
              _buildSummarySection(totalIncome, totalExpense),
              pw.SizedBox(height: 16),
              if (expenseCategoryTotals.isNotEmpty) ...[
                _buildCategorySection(expenseCategoryTotals, totalExpense),
                pw.SizedBox(height: 16),
              ],
              _buildTransactionTable(transactions),
            ],
          ),
        );
        return pdf.save();
      },
    );
  }

  // ── Header ────────────────────────────────────────────────
  static pw.Widget _buildHeader(String monthName) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.teal, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MyDuit',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal,
                ),
              ),
              pw.Text(
                'Laporan Keuangan',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
              ),
            ],
          ),
          pw.Text(
            monthName,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Halaman ${context.pageNumber} dari ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  // ── Summary ───────────────────────────────────────────────
  static pw.Widget _buildSummarySection(
      double totalIncome, double totalExpense) {
    final balance = totalIncome - totalExpense;
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Pemasukan', totalIncome, PdfColors.green700),
          _summaryItem('Pengeluaran', totalExpense, PdfColors.red700),
          _summaryItem(
            'Saldo',
            balance,
            balance >= 0 ? PdfColors.teal : PdfColors.red700,
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryItem(String label, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(
          CurrencyFormatter.format(amount),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Category Breakdown ────────────────────────────────────
  static pw.Widget _buildCategorySection(
    Map<TransactionCategory, double> categoryTotals,
    double totalExpense,
  ) {
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Pengeluaran per Kategori',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        ...sorted.map((entry) {
          final pct = totalExpense > 0
              ? (entry.value / totalExpense * 100).toStringAsFixed(1)
              : '0';
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Row(
              children: [
                pw.SizedBox(
                    width: 100,
                    child: pw.Text(entry.key.label,
                        style: const pw.TextStyle(fontSize: 10))),
                pw.Expanded(
                  child: pw.Stack(
                    children: [
                      pw.Container(
                        height: 12,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                      ),
                      pw.Container(
                        height: 12,
                        width:
                            (totalExpense > 0 ? entry.value / totalExpense : 0)
                                    .toDouble() *
                                200,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.teal300,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.SizedBox(
                    width: 80,
                    child: pw.Text(
                      CurrencyFormatter.format(entry.value),
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.right,
                    )),
                pw.SizedBox(
                    width: 35,
                    child: pw.Text(
                      '$pct%',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey600),
                      textAlign: pw.TextAlign.right,
                    )),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Transaction Table ─────────────────────────────────────
  static pw.Widget _buildTransactionTable(
      List<TransactionModel> transactions) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Daftar Transaksi',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
            color: PdfColors.white,
          ),
          headerDecoration:
              const pw.BoxDecoration(color: PdfColors.teal),
          headerAlignment: pw.Alignment.centerLeft,
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding:
              const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          headers: ['Tanggal', 'Judul', 'Kategori', 'Tipe', 'Jumlah'],
          data: transactions.map((tx) {
            return [
              DateFormatter.shortDate(tx.date),
              tx.title,
              tx.category.label,
              tx.type == TransactionType.income ? 'Masuk' : 'Keluar',
              CurrencyFormatter.format(tx.amount),
            ];
          }).toList(),
        ),
      ],
    );
  }
}
