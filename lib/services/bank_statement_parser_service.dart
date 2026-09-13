import '../models/import_transaction_item.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';

enum BankPreset {
  universal('Universal CSV / Custom'),
  bca('BCA Mutasi Rekening'),
  mandiri('Mandiri Livin'),
  bri('BRImo'),
  bni('BNI Mobile / Wondr');

  final String label;
  const BankPreset(this.label);
}

class BankStatementParserService {
  /// Parse CSV or raw pasted text according to chosen preset
  static List<ImportTransactionItem> parse({
    required String rawText,
    required BankPreset preset,
    List<TransactionModel> existingTransactions = const [],
  }) {
    if (rawText.trim().isEmpty) return [];

    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return [];

    final List<ImportTransactionItem> items = [];

    switch (preset) {
      case BankPreset.bca:
        _parseBca(lines, items);
        break;
      case BankPreset.mandiri:
        _parseMandiri(lines, items);
        break;
      case BankPreset.bri:
      case BankPreset.bni:
      case BankPreset.universal:
        _parseUniversalCsv(lines, items);
        break;
    }

    // Mark duplicates
    for (final item in items) {
      final isDup = existingTransactions.any((tx) {
        final sameAmount = (tx.amount - item.amount).abs() < 0.01;
        final sameType = tx.type == item.type;
        final sameDate = tx.date.year == item.date.year &&
            tx.date.month == item.date.month &&
            tx.date.day == item.date.day;
        return sameAmount && sameType && sameDate;
      });
      if (isDup) {
        item.isDuplicate = true;
        item.isSelected = false; // Uncheck duplicates by default
      }
    }

    return items;
  }

  /// Parse BCA CSV format (Tgl, Keterangan, CBG, Mutasi, Saldo)
  static void _parseBca(List<String> lines, List<ImportTransactionItem> items) {
    for (final line in lines) {
      final parts = _splitCsvLine(line);
      if (parts.length < 3) continue;

      // Skip header lines
      if (parts[0].toLowerCase().contains('tgl') ||
          parts[0].toLowerCase().contains('tanggal')) {
        continue;
      }

      final date = _parseDate(parts[0]);
      if (date == null) continue;

      final desc = parts[1].replaceAll('"', '').trim();
      final amountPart = parts[parts.length - 2];
      final isCredit = line.toUpperCase().contains(' CR') ||
          amountPart.toUpperCase().contains('CR');
      final cleanAmt = RupiahInputFormatter.parse(amountPart);

      if (cleanAmt > 0) {
        items.add(
          ImportTransactionItem(
            title: desc.isEmpty ? 'Mutasi BCA' : desc,
            amount: cleanAmt,
            type: isCredit ? TransactionType.income : TransactionType.expense,
            category: _guessCategory(desc, isCredit),
            date: date,
            note: 'Impor BCA: $desc',
          ),
        );
      }
    }
  }

  /// Parse Mandiri Livin CSV
  static void _parseMandiri(
    List<String> lines,
    List<ImportTransactionItem> items,
  ) {
    for (final line in lines) {
      final parts = _splitCsvLine(line);
      if (parts.length < 4) continue;

      if (parts[0].toLowerCase().contains('tanggal') ||
          parts[0].toLowerCase().contains('date')) {
        continue;
      }

      final date = _parseDate(parts[0]);
      if (date == null) continue;

      final desc = parts[1].replaceAll('"', '').trim();
      final debit = RupiahInputFormatter.parse(parts[2]);
      final credit = RupiahInputFormatter.parse(parts[3]);

      if (debit > 0) {
        items.add(
          ImportTransactionItem(
            title: desc.isEmpty ? 'Pengeluaran Mandiri' : desc,
            amount: debit,
            type: TransactionType.expense,
            category: _guessCategory(desc, false),
            date: date,
            note: 'Impor Mandiri: $desc',
          ),
        );
      } else if (credit > 0) {
        items.add(
          ImportTransactionItem(
            title: desc.isEmpty ? 'Pemasukan Mandiri' : desc,
            amount: credit,
            type: TransactionType.income,
            category: _guessCategory(desc, true),
            date: date,
            note: 'Impor Mandiri: $desc',
          ),
        );
      }
    }
  }

  /// Parse Universal CSV
  static void _parseUniversalCsv(
    List<String> lines,
    List<ImportTransactionItem> items,
  ) {
    int dateCol = 0;
    int titleCol = 1;
    int amountCol = 2;
    int typeCol = -1;

    // Detect header index
    if (lines.isNotEmpty) {
      final headerCols = _splitCsvLine(lines.first).map((c) => c.toLowerCase()).toList();
      for (int i = 0; i < headerCols.length; i++) {
        final col = headerCols[i];
        if (col.contains('tgl') || col.contains('date') || col.contains('tanggal')) {
          dateCol = i;
        } else if (col.contains('judul') ||
            col.contains('title') ||
            col.contains('ket') ||
            col.contains('desc') ||
            col.contains('memo')) {
          titleCol = i;
        } else if (col.contains('jumlah') ||
            col.contains('amount') ||
            col.contains('nominal') ||
            col.contains('total')) {
          amountCol = i;
        } else if (col.contains('tipe') || col.contains('type')) {
          typeCol = i;
        }
      }
    }

    final startIdx = lines.first.toLowerCase().contains('tgl') ||
            lines.first.toLowerCase().contains('date')
        ? 1
        : 0;

    for (int i = startIdx; i < lines.length; i++) {
      final line = lines[i];
      final parts = _splitCsvLine(line);
      if (parts.length <= dateCol || parts.length <= titleCol) continue;

      final date = _parseDate(parts[dateCol]);
      if (date == null) continue;

      final title = parts[titleCol].replaceAll('"', '').trim();
      final amtString = parts.length > amountCol ? parts[amountCol] : '0';
      final amount = RupiahInputFormatter.parse(amtString);

      if (amount <= 0) continue;

      TransactionType type = TransactionType.expense;
      if (typeCol != -1 && parts.length > typeCol) {
        final typeStr = parts[typeCol].toLowerCase();
        if (typeStr.contains('masuk') ||
            typeStr.contains('income') ||
            typeStr.contains('cr')) {
          type = TransactionType.income;
        }
      }

      items.add(
        ImportTransactionItem(
          title: title.isEmpty ? 'Transaksi Impor' : title,
          amount: amount,
          type: type,
          category: _guessCategory(title, type == TransactionType.income),
          date: date,
        ),
      );
    }
  }

  static List<String> _splitCsvLine(String line) {
    String delimiter = ',';
    if (line.contains(';') && !line.contains(',')) {
      delimiter = ';';
    } else if (line.contains('\t')) {
      delimiter = '\t';
    }

    final List<String> result = [];
    final StringBuffer current = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == delimiter && !inQuotes) {
        result.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  static DateTime? _extractDateNumbers(String text) {
    // 1. Try YYYY-MM-DD or YYYY/MM/DD
    final ymd = RegExp(r'(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})');
    final matchYmd = ymd.firstMatch(text);
    if (matchYmd != null) {
      final y = int.tryParse(matchYmd.group(1)!);
      final m = int.tryParse(matchYmd.group(2)!);
      final d = int.tryParse(matchYmd.group(3)!);
      if (y != null && m != null && d != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        return DateTime(y, m, d);
      }
    }

    // 2. Try DD/MM/YYYY or DD-MM-YY
    final dmy = RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})(?:[\/\-\.](\d{2,4}))?');
    final match = dmy.firstMatch(text);
    if (match != null) {
      final d = int.tryParse(match.group(1)!);
      final m = int.tryParse(match.group(2)!);
      int? y = match.group(3) != null ? int.tryParse(match.group(3)!) : null;
      if (y != null && y < 100) y += 2000;
      y ??= DateTime.now().year;

      if (d != null && m != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        return DateTime(y, m, d);
      }
    }
    return null;
  }

  static DateTime? _parseDate(String text) {
    final clean = text.replaceAll('"', '').trim();
    return _extractDateNumbers(clean);
  }

  static TransactionCategory _guessCategory(String desc, bool isIncome) {
    if (isIncome) return TransactionCategory.salary;
    final lower = desc.toLowerCase();
    if (lower.contains('makan') ||
        lower.contains('kopi') ||
        lower.contains('resto') ||
        lower.contains('cafe')) {
      return TransactionCategory.food;
    }
    if (lower.contains('pln') ||
        lower.contains('pdam') ||
        lower.contains('bpjs') ||
        lower.contains('pulsa') ||
        lower.contains('listrik')) {
      return TransactionCategory.bills;
    }
    if (lower.contains('spbu') ||
        lower.contains('pertamina') ||
        lower.contains('grab') ||
        lower.contains('gojek') ||
        lower.contains('tol')) {
      return TransactionCategory.transport;
    }
    if (lower.contains('apotek') ||
        lower.contains('dokter') ||
        lower.contains('rs') ||
        lower.contains('klinik')) {
      return TransactionCategory.health;
    }
    if (lower.contains('shopee') ||
        lower.contains('tokopedia') ||
        lower.contains('lazada') ||
        lower.contains('mart')) {
      return TransactionCategory.shopping;
    }
    return TransactionCategory.other;
  }
}
