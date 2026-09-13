import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';

class _PdfCategoryItem {
  final String label;
  final double amount;
  const _PdfCategoryItem(this.label, this.amount);
}

class PdfExportService {
  static Future<void> exportAndShare(
    List<TransactionModel> transactions, {
    required int year,
    required int month,
    required double totalIncome,
    required double totalExpense,
    required Map<TransactionCategory, double> expenseCategoryTotals,
    Map<String, double>? expenseCustomTotals,
    Map<String, String>? customCategoryNames,
  }) async {
    final pdf = pw.Document();
    final monthName = DateFormatter.monthYear(year, month);

    final categoryItems = _buildCategoryItems(
      expenseCategoryTotals,
      expenseCustomTotals,
      customCategoryNames,
    );

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
          if (categoryItems.isNotEmpty) ...[
            _buildCategorySection(categoryItems, totalExpense),
            pw.SizedBox(height: 16),
          ],

          // Transaction table
          _buildTransactionTable(transactions, customCategoryNames),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'MyDuit_${monthName.replaceAll(' ', '_')}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Laporan Keuangan MyDuit - $monthName');
  }

  static Future<void> printReport(
    List<TransactionModel> transactions, {
    required int year,
    required int month,
    required double totalIncome,
    required double totalExpense,
    required Map<TransactionCategory, double> expenseCategoryTotals,
    Map<String, double>? expenseCustomTotals,
    Map<String, String>? customCategoryNames,
  }) async {
    final monthName = DateFormatter.monthYear(year, month);
    final categoryItems = _buildCategoryItems(
      expenseCategoryTotals,
      expenseCustomTotals,
      customCategoryNames,
    );

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
              if (categoryItems.isNotEmpty) ...[
                _buildCategorySection(categoryItems, totalExpense),
                pw.SizedBox(height: 16),
              ],
              _buildTransactionTable(transactions, customCategoryNames),
            ],
          ),
        );
        return pdf.save();
      },
    );
  }

  static List<_PdfCategoryItem> _buildCategoryItems(
    Map<TransactionCategory, double> expenseCategoryTotals,
    Map<String, double>? expenseCustomTotals,
    Map<String, String>? customCategoryNames,
  ) {
    final List<_PdfCategoryItem> items = [];
    expenseCategoryTotals.forEach((cat, amt) {
      if (amt > 0) {
        items.add(_PdfCategoryItem(_cleanText(cat.label), amt));
      }
    });

    if (expenseCustomTotals != null && customCategoryNames != null) {
      expenseCustomTotals.forEach((catId, amt) {
        if (amt > 0) {
          final name = customCategoryNames[catId] ?? 'Kustom';
          items.add(_PdfCategoryItem(_cleanText(name), amt));
        }
      });
    }

    items.sort((a, b) => b.amount.compareTo(a.amount));
    return items;
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
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
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
    double totalIncome,
    double totalExpense,
  ) {
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
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
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
    List<_PdfCategoryItem> categoryItems,
    double totalExpense,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Pengeluaran per Kategori',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        ...categoryItems.map((entry) {
          final pct = totalExpense > 0
              ? (entry.amount / totalExpense * 100).toStringAsFixed(1)
              : '0';
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 100,
                  child: pw.Text(
                    entry.label,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
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
                            (totalExpense > 0 ? (entry.amount / totalExpense).clamp(0.0, 1.0) : 0.0) *
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
                    CurrencyFormatter.format(entry.amount),
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.SizedBox(
                  width: 35,
                  child: pw.Text(
                    '$pct%',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Transaction Table ─────────────────────────────────────
  static pw.Widget _buildTransactionTable(
    List<TransactionModel> transactions,
    Map<String, String>? customCategoryNames,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Daftar Transaksi',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
          headerAlignment: pw.Alignment.centerLeft,
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 4,
          ),
          headers: ['Tanggal', 'Judul', 'Kategori', 'Tipe', 'Jumlah'],
          data: transactions.map((tx) {
            final cleanTitle = _cleanText(tx.title);
            final categoryLabel = _cleanText(
              (tx.customCategoryId != null && customCategoryNames != null)
                  ? (customCategoryNames[tx.customCategoryId] ?? tx.category.label)
                  : tx.category.label,
            );

            return [
              DateFormatter.shortDate(tx.date),
              cleanTitle.isEmpty ? '-' : cleanTitle,
              categoryLabel.isEmpty ? '-' : categoryLabel,
              tx.type == TransactionType.income ? 'Masuk' : 'Keluar',
              CurrencyFormatter.format(tx.amount),
            ];
          }).toList(),
        ),
      ],
    );
  }

  static String _cleanText(String text) {
    return text
        .replaceAll(
          RegExp(
            r'[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{FE00}-\u{FE0F}\u{200D}\u{1F3FB}-\u{1F3FF}]',
            unicode: true,
          ),
          '',
        )
        .trim();
  }
}
