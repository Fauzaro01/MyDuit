import '../models/receipt_data.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';

class ReceiptParserService {
  /// Known merchant brands for high-precision recognition
  static const Map<String, TransactionCategory> _knownMerchants = {
    'indomaret': TransactionCategory.shopping,
    'alfamart': TransactionCategory.shopping,
    'alfamidi': TransactionCategory.shopping,
    'superindo': TransactionCategory.shopping,
    'hypermart': TransactionCategory.shopping,
    'transmart': TransactionCategory.shopping,
    'lotte': TransactionCategory.shopping,
    'hero': TransactionCategory.shopping,
    'miniso': TransactionCategory.shopping,
    'starbucks': TransactionCategory.food,
    'mcdonald': TransactionCategory.food,
    'kfc': TransactionCategory.food,
    'hokben': TransactionCategory.food,
    'jco': TransactionCategory.food,
    'mixue': TransactionCategory.food,
    'kopi kenangan': TransactionCategory.food,
    'janji jiwa': TransactionCategory.food,
    'fore coffee': TransactionCategory.food,
    'solaria': TransactionCategory.food,
    'pizza hut': TransactionCategory.food,
    'burger king': TransactionCategory.food,
    'pertamina': TransactionCategory.transport,
    'spbu': TransactionCategory.transport,
    'shell': TransactionCategory.transport,
    'bp akr': TransactionCategory.transport,
    'grab': TransactionCategory.transport,
    'gojek': TransactionCategory.transport,
    'bluebird': TransactionCategory.transport,
    'pln': TransactionCategory.bills,
    'pdam': TransactionCategory.bills,
    'telkom': TransactionCategory.bills,
    'indihome': TransactionCategory.bills,
    'bpjs': TransactionCategory.bills,
    'xxi': TransactionCategory.entertainment,
    'cgv': TransactionCategory.entertainment,
    'cinepolis': TransactionCategory.entertainment,
    'gramedia': TransactionCategory.education,
    'guardian': TransactionCategory.health,
    'watsons': TransactionCategory.health,
    'kimia farma': TransactionCategory.health,
    'century': TransactionCategory.health,
    'apotek': TransactionCategory.health,
  };

  /// Parses OCR / raw text of a receipt into structured ReceiptData
  static ReceiptData parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return const ReceiptData(rawText: '');
    }

    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? merchant;
    TransactionCategory category = TransactionCategory.shopping;
    double? totalAmount;
    DateTime? transactionDate;
    final List<String> lineItems = [];

    // 1. Identify Merchant & Category
    for (int i = 0; i < lines.length && i < 6; i++) {
      final lineLower = lines[i].toLowerCase();
      for (final entry in _knownMerchants.entries) {
        if (lineLower.contains(entry.key)) {
          merchant = lines[i];
          category = entry.value;
          break;
        }
      }
      if (merchant != null) break;
    }

    // Fallback merchant name: First non-trivial upper line
    if (merchant == null && lines.isNotEmpty) {
      for (int i = 0; i < lines.length && i < 3; i++) {
        final line = lines[i];
        if (line.length >= 3 && !RegExp(r'^\d+$').hasMatch(line)) {
          merchant = line;
          break;
        }
      }
    }

    // 2. Identify Total Amount
    // Primary total keywords have higher priority than payment lines (tunai/cash)
    final primaryTotalKeywords = [
      'total bayar',
      'grand total',
      'total belanja',
      'total akhir',
      'subtotal',
      'total',
    ];

    final secondaryTotalKeywords = [
      'tunai',
      'cash',
      'debit',
      'qris',
      'jumlah',
    ];

    // Check primary total keywords first (searching backwards from bottom)
    for (int i = lines.length - 1; i >= 0; i--) {
      final lineLower = lines[i].toLowerCase();
      for (final kw in primaryTotalKeywords) {
        if (lineLower.contains(kw)) {
          final amt = _extractAmountFromLine(lines[i]);
          if (amt != null && amt > 0) {
            totalAmount = amt;
            break;
          }
        }
      }
      if (totalAmount != null) break;
    }

    // If no primary total found, check secondary keywords
    if (totalAmount == null) {
      for (int i = lines.length - 1; i >= 0; i--) {
        final lineLower = lines[i].toLowerCase();
        for (final kw in secondaryTotalKeywords) {
          if (lineLower.contains(kw)) {
            final amt = _extractAmountFromLine(lines[i]);
            if (amt != null && amt > 0) {
              totalAmount = amt;
              break;
            }
          }
        }
        if (totalAmount != null) break;
      }
    }

    // If still null, search all numbers in the bottom half of receipt
    if (totalAmount == null) {
      final searchLines = lines.sublist((lines.length / 2).floor());
      double maxFound = 0;
      for (final line in searchLines) {
        final amt = _extractAmountFromLine(line);
        if (amt != null && amt > maxFound) {
          maxFound = amt;
        }
      }
      if (maxFound > 0) totalAmount = maxFound;
    }

    // 3. Identify Date
    for (final line in lines) {
      final date = _extractDate(line);
      if (date != null) {
        transactionDate = date;
        break;
      }
    }

    // 4. Collect item-like lines
    for (final line in lines) {
      if (RegExp(r'\d+[.,]\d+').hasMatch(line) &&
          !line.toLowerCase().contains('total')) {
        lineItems.add(line);
      }
    }

    return ReceiptData(
      merchantName: merchant,
      totalAmount: totalAmount,
      date: transactionDate ?? DateTime.now(),
      suggestedCategory: category,
      suggestedType: TransactionType.expense,
      lineItems: lineItems,
      rawText: rawText,
    );
  }

  static double? _extractAmountFromLine(String line) {
    // Matches patterns like "Rp 150.000", "150,000.00", "50000"
    final regex = RegExp(
      r'(?:Rp\.?|IDR)?\s*([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{2})?|[0-9]+)',
      caseSensitive: false,
    );
    final matches = regex.allMatches(line);

    for (final match in matches) {
      String? rawNum = match.group(1);
      if (rawNum != null) {
        // Strip 2-decimal trailing cents (e.g. ,00 or .00) common on receipts
        if (RegExp(r'[,.]\d{2}$').hasMatch(rawNum) &&
            (rawNum.contains('.') || rawNum.contains(','))) {
          rawNum = rawNum.substring(0, rawNum.length - 3);
        }
        final parsed = RupiahInputFormatter.parse(rawNum);
        if (parsed >= 100) {
          return parsed;
        }
      }
    }
    return null;
  }

  static DateTime? _extractDate(String line) {
    // Pattern 1: DD/MM/YYYY or DD-MM-YYYY
    final dmy = RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})');
    final matchDmy = dmy.firstMatch(line);
    if (matchDmy != null) {
      final day = int.tryParse(matchDmy.group(1)!);
      final month = int.tryParse(matchDmy.group(2)!);
      int? year = int.tryParse(matchDmy.group(3)!);
      if (year != null && year < 100) year += 2000;
      if (day != null &&
          month != null &&
          year != null &&
          month >= 1 &&
          month <= 12 &&
          day >= 1 &&
          day <= 31) {
        return DateTime(year, month, day);
      }
    }

    // Pattern 2: YYYY-MM-DD
    final ymd = RegExp(r'(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})');
    final matchYmd = ymd.firstMatch(line);
    if (matchYmd != null) {
      final year = int.tryParse(matchYmd.group(1)!);
      final month = int.tryParse(matchYmd.group(2)!);
      final day = int.tryParse(matchYmd.group(3)!);
      if (day != null &&
          month != null &&
          year != null &&
          month >= 1 &&
          month <= 12 &&
          day >= 1 &&
          day <= 31) {
        return DateTime(year, month, day);
      }
    }

    // Pattern 3: Textual Indonesian months e.g. "12 Januari 2026", "24-Feb-2026"
    final indonesianMonths = {
      'jan': 1, 'januari': 1,
      'feb': 2, 'februari': 2,
      'mar': 3, 'maret': 3,
      'apr': 4, 'april': 4,
      'mei': 5, 'may': 5,
      'jun': 6, 'juni': 6,
      'jul': 7, 'juli': 7,
      'agu': 8, 'agustus': 8, 'ags': 8,
      'sep': 9, 'september': 9,
      'okt': 10, 'oktober': 10, 'oct': 10,
      'nov': 11, 'november': 11,
      'des': 12, 'desember': 12, 'dec': 12,
    };

    final textMonthRegex = RegExp(r'(\d{1,2})[\s\-]+([a-zA-Z]+)[\s\-]+(\d{2,4})');
    final matchText = textMonthRegex.firstMatch(line);
    if (matchText != null) {
      final day = int.tryParse(matchText.group(1)!);
      final monthStr = matchText.group(2)!.toLowerCase();
      int? year = int.tryParse(matchText.group(3)!);
      if (year != null && year < 100) year += 2000;
      final month = indonesianMonths[monthStr];

      if (day != null &&
          month != null &&
          year != null &&
          day >= 1 &&
          day <= 31) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }
}
