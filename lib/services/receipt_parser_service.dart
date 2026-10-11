import '../models/receipt_data.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';
import 'auto_categorize_service.dart';

class ReceiptParserService {
  /// Comprehensive dictionary of 100+ Indonesian & multinational brands mapped to TransactionCategory
  static const Map<String, TransactionCategory> _knownMerchants = {
    // 1. Retail, Minimarket & Supermarket -> Shopping
    'indomaret': TransactionCategory.shopping,
    'alfamart': TransactionCategory.shopping,
    'alfamidi': TransactionCategory.shopping,
    'superindo': TransactionCategory.shopping,
    'hypermart': TransactionCategory.shopping,
    'transmart': TransactionCategory.shopping,
    'lotte mart': TransactionCategory.shopping,
    'lotte': TransactionCategory.shopping,
    'hero': TransactionCategory.shopping,
    'grandlucky': TransactionCategory.shopping,
    'grand lucky': TransactionCategory.shopping,
    'farmers market': TransactionCategory.shopping,
    'ranch market': TransactionCategory.shopping,
    'papaya fresh': TransactionCategory.shopping,
    'circle k': TransactionCategory.shopping,
    'familymart': TransactionCategory.shopping,
    'family mart': TransactionCategory.shopping,
    'lawson': TransactionCategory.shopping,
    'gs supermarket': TransactionCategory.shopping,
    'tip top': TransactionCategory.shopping,
    'tiptop': TransactionCategory.shopping,
    'hari hari': TransactionCategory.shopping,
    'naga swalayan': TransactionCategory.shopping,
    'yogya': TransactionCategory.shopping,
    'griya': TransactionCategory.shopping,
    'mirota': TransactionCategory.shopping,
    'luwes': TransactionCategory.shopping,
    'borma': TransactionCategory.shopping,
    'miniso': TransactionCategory.shopping,
    'uniqlo': TransactionCategory.shopping,
    'h&m': TransactionCategory.shopping,
    'zara': TransactionCategory.shopping,
    'matahari': TransactionCategory.shopping,
    'ramayana': TransactionCategory.shopping,
    'mr diy': TransactionCategory.shopping,
    'mr. diy': TransactionCategory.shopping,
    'ace hardware': TransactionCategory.shopping,
    'informa': TransactionCategory.shopping,
    'mitra10': TransactionCategory.shopping,
    'ikea': TransactionCategory.shopping,
    'decathlon': TransactionCategory.shopping,
    'kKV': TransactionCategory.shopping,
    'sociolla': TransactionCategory.shopping,

    // 2. Food & Beverage -> Food
    'starbucks': TransactionCategory.food,
    'mcdonald': TransactionCategory.food,
    'mcd': TransactionCategory.food,
    'kfc': TransactionCategory.food,
    'hokben': TransactionCategory.food,
    'hoka hoka bento': TransactionCategory.food,
    'j.co': TransactionCategory.food,
    'jco': TransactionCategory.food,
    'mixue': TransactionCategory.food,
    'kopi kenangan': TransactionCategory.food,
    'janji jiwa': TransactionCategory.food,
    'fore coffee': TransactionCategory.food,
    'point coffee': TransactionCategory.food,
    'solaria': TransactionCategory.food,
    'pizza hut': TransactionCategory.food,
    'domino': TransactionCategory.food,
    'burger king': TransactionCategory.food,
    'richeese': TransactionCategory.food,
    "d'cost": TransactionCategory.food,
    'dcost': TransactionCategory.food,
    'bakmi gm': TransactionCategory.food,
    'yoshinoya': TransactionCategory.food,
    'marugame udon': TransactionCategory.food,
    'marugame': TransactionCategory.food,
    'a&w': TransactionCategory.food,
    'subway': TransactionCategory.food,
    'mie gacoan': TransactionCategory.food,
    'gacoan': TransactionCategory.food,
    'shihlin': TransactionCategory.food,
    "wendy's": TransactionCategory.food,
    'imperial kitchen': TransactionCategory.food,
    'pepper lunch': TransactionCategory.food,
    'ta wan': TransactionCategory.food,
    'restoran sederhana': TransactionCategory.food,
    'rm sederhana': TransactionCategory.food,
    'pagi sore': TransactionCategory.food,
    'dunkin': TransactionCategory.food,
    'kopi tuku': TransactionCategory.food,
    'tuku': TransactionCategory.food,
    'tomoro coffee': TransactionCategory.food,
    'haus!': TransactionCategory.food,
    'haus': TransactionCategory.food,
    'chatime': TransactionCategory.food,
    'kopi lain hati': TransactionCategory.food,
    'warung': TransactionCategory.food,
    'resto': TransactionCategory.food,
    'cafe': TransactionCategory.food,
    'coffee': TransactionCategory.food,

    // 3. Transport & Fuel -> Transport
    'pertamina': TransactionCategory.transport,
    'spbu': TransactionCategory.transport,
    'shell': TransactionCategory.transport,
    'bp akr': TransactionCategory.transport,
    'bp-akr': TransactionCategory.transport,
    'vivo energy': TransactionCategory.transport,
    'grab': TransactionCategory.transport,
    'gojek': TransactionCategory.transport,
    'goride': TransactionCategory.transport,
    'gocar': TransactionCategory.transport,
    'grabbike': TransactionCategory.transport,
    'grabcar': TransactionCategory.transport,
    'maxim': TransactionCategory.transport,
    'bluebird': TransactionCategory.transport,
    'blue bird': TransactionCategory.transport,
    'indrive': TransactionCategory.transport,
    'kai': TransactionCategory.transport,
    'kereta api': TransactionCategory.transport,
    'mrt jakarta': TransactionCategory.transport,
    'lrt jakarta': TransactionCategory.transport,
    'damri': TransactionCategory.transport,
    'transjakarta': TransactionCategory.transport,
    'kci': TransactionCategory.transport,
    'commuter line': TransactionCategory.transport,
    'e-toll': TransactionCategory.transport,
    'etoll': TransactionCategory.transport,
    'parkir': TransactionCategory.transport,
    'secure parking': TransactionCategory.transport,

    // 4. Bills & Utilities -> Bills
    'pln': TransactionCategory.bills,
    'listrik': TransactionCategory.bills,
    'pdam': TransactionCategory.bills,
    'telkom': TransactionCategory.bills,
    'indihome': TransactionCategory.bills,
    'bpjs': TransactionCategory.bills,
    'telkomsel': TransactionCategory.bills,
    'by.u': TransactionCategory.bills,
    'indosat': TransactionCategory.bills,
    'im3': TransactionCategory.bills,
    'xl axiata': TransactionCategory.bills,
    'xl': TransactionCategory.bills,
    'axis': TransactionCategory.bills,
    'smartfren': TransactionCategory.bills,
    'tri': TransactionCategory.bills,
    'first media': TransactionCategory.bills,
    'biznet': TransactionCategory.bills,
    'myrepublic': TransactionCategory.bills,
    'cbn': TransactionCategory.bills,
    'pgn': TransactionCategory.bills,
    'samsat': TransactionCategory.bills,
    'pbb': TransactionCategory.bills,

    // 5. Entertainment -> Entertainment
    'cinema xxi': TransactionCategory.entertainment,
    'xxi': TransactionCategory.entertainment,
    'cgv': TransactionCategory.entertainment,
    'cinepolis': TransactionCategory.entertainment,
    'flix cinema': TransactionCategory.entertainment,
    'timezone': TransactionCategory.entertainment,
    'amazone': TransactionCategory.entertainment,
    'funworld': TransactionCategory.entertainment,
    'kidzania': TransactionCategory.entertainment,
    'spotify': TransactionCategory.entertainment,
    'netflix': TransactionCategory.entertainment,
    'disney+': TransactionCategory.entertainment,
    'youtube': TransactionCategory.entertainment,
    'steam': TransactionCategory.entertainment,
    'playstation': TransactionCategory.entertainment,

    // 6. Education & Books -> Education
    'gramedia': TransactionCategory.education,
    'periplus': TransactionCategory.education,
    'kinokuniya': TransactionCategory.education,
    'togamas': TransactionCategory.education,
    'udemy': TransactionCategory.education,
    'coursera': TransactionCategory.education,
    'ruangguru': TransactionCategory.education,
    'zenius': TransactionCategory.education,

    // 7. Health & Pharmacy -> Health
    'guardian': TransactionCategory.health,
    'watsons': TransactionCategory.health,
    'kimia farma': TransactionCategory.health,
    'century': TransactionCategory.health,
    'k-24': TransactionCategory.health,
    'k24': TransactionCategory.health,
    'apotek': TransactionCategory.health,
    'apotik': TransactionCategory.health,
    'halodoc': TransactionCategory.health,
    'alodokter': TransactionCategory.health,
    'prodia': TransactionCategory.health,
    'pramita': TransactionCategory.health,
    'siloam': TransactionCategory.health,
    'hermina': TransactionCategory.health,
    'mitra keluarga': TransactionCategory.health,
    'pondok indah': TransactionCategory.health,
  };

  // --- Shared line-classification keywords -------------------------------
  // Defined once and reused by both the main line-type scan (parse()) and
  // the item-line skip check (_parseItemLine()) so the two can never drift
  // out of sync with each other (previously two independent, slightly
  // different lists risked a discount/total/payment line being misread as
  // a purchased item).
  static const List<String> _primaryTotalKeywords = [
    'total bayar',
    'grand total',
    'total belanja',
    'total akhir',
    'total tagihan',
    'nilai transaksi',
    'jumlah bayar',
    'total',
  ];

  static const List<String> _subtotalKeywords = [
    'subtotal',
    'sub total',
    'jumlah harga',
    'total item',
    'jumlah belanja',
  ];

  static const List<String> _discountKeywords = [
    'discount',
    'diskon',
    'promo',
    'potongan',
    'hemat',
    'voucher',
    'cashback',
  ];

  static const List<String> _taxKeywords = [
    'ppn',
    'pb1',
    'pajak',
    'tax',
    'service charge',
    'service',
    'svc',
    'biaya layanan',
    'biaya admin',
    'admin fee',
  ];

  static const List<String> _paymentMethodKeywords = [
    'tunai',
    'cash',
    'debit',
    'qris',
    'kartu',
    'card',
    'kredit',
    'credit card',
    'gopay',
    'go-pay',
    'ovo',
    'dana',
    'shopeepay',
    'shopee pay',
    'linkaja',
  ];

  static const List<String> _miscNonItemKeywords = [
    'kembali',
    'change',
    'kembalian',
    'telp',
    'telepon',
    'alamat',
    'jl.',
    'terima kasih',
    'kasir',
    'cashier',
    'struk',
    'receipt',
  ];

  /// Union of every keyword above — any line matching one of these is a
  /// total/subtotal/discount/tax/payment/header line, never a purchased item.
  static const List<String> _nonItemKeywords = [
    ..._primaryTotalKeywords,
    ..._subtotalKeywords,
    ..._discountKeywords,
    ..._taxKeywords,
    ..._paymentMethodKeywords,
    ..._miscNonItemKeywords,
  ];

  /// Parses OCR / raw text of a receipt into structured ReceiptData
  static ReceiptData parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return const ReceiptData(rawText: '');
    }

    final rawLines = rawText.split(RegExp(r'\r?\n'));
    final lines = rawLines
        .map((l) => _sanitizeOcrNoise(l))
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return ReceiptData(rawText: rawText);
    }

    // 1. Identify Merchant & Category
    String? merchant;
    TransactionCategory category = TransactionCategory.shopping;

    for (int i = 0; i < lines.length && i < 8; i++) {
      final lineLower = lines[i].toLowerCase();
      for (final entry in _knownMerchants.entries) {
        if (_containsBrand(lineLower, entry.key)) {
          merchant = lines[i];
          category = entry.value;
          break;
        }
      }
      if (merchant != null) break;
    }

    // Fallback merchant name: First clean non-numeric heading
    if (merchant == null) {
      for (int i = 0; i < lines.length && i < 4; i++) {
        final line = lines[i];
        if (line.length >= 3 &&
            !RegExp(r'^\d+$').hasMatch(line) &&
            !_isDateOrTime(line) &&
            !_isAddressOrPhone(line)) {
          merchant = line;
          break;
        }
      }
    }

    // 2. Identify Date & Time
    DateTime? transactionDate;
    for (final line in lines) {
      final date = _extractDate(line);
      if (date != null) {
        transactionDate = date;
        break;
      }
    }

    // 3. Identify Payment Method & Wallet
    String? paymentMethod;
    String? detectedWalletKeyword;
    final paymentInfo = _detectPaymentMethod(lines);
    paymentMethod = paymentInfo.$1;
    detectedWalletKeyword = paymentInfo.$2;

    // 4. Extract Items, Taxes, Discounts & Subtotals
    final extractedItems = <ReceiptItem>[];
    final extractedDiscounts = <ReceiptDiscount>[];
    final extractedTaxes = <ReceiptTax>[];
    double? subtotalAmount;
    double? grandTotal;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineLower = line.toLowerCase();

      // Check Subtotal
      if (subtotalAmount == null &&
          _subtotalKeywords.any((kw) => lineLower.contains(kw))) {
        final amt = _extractAmountFromLine(line);
        if (amt != null && amt > 0) {
          subtotalAmount = amt;
          continue;
        }
      }

      // Check Discounts
      if (_discountKeywords.any((kw) => lineLower.contains(kw))) {
        final amt = _extractAmountFromLine(line);
        if (amt != null && amt > 0) {
          extractedDiscounts.add(ReceiptDiscount(name: line, amount: amt));
          continue;
        }
      }

      // Check Taxes & Service Charges
      if (_taxKeywords.any((kw) => lineLower.contains(kw))) {
        final amt = _extractAmountFromLine(line);
        if (amt != null && amt > 0) {
          final pctMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*%').firstMatch(line);
          double? pct;
          if (pctMatch != null) {
            pct = double.tryParse(pctMatch.group(1)!.replaceAll(',', '.'));
          }
          extractedTaxes.add(
            ReceiptTax(name: line, percentage: pct, amount: amt),
          );
          continue;
        }
      }

      // Check Item Lines (e.g. "2x Susu UHT Rp 20.000" or "Roti Tawar 15.000")
      final item = _parseItemLine(
        line,
        i < lines.length - 1 ? lines[i + 1] : null,
      );
      if (item != null) {
        extractedItems.add(item);
      }
    }

    // 5. Identify Grand Total
    // Scan every line for primary total keywords (not stopping at the
    // first match) so a receipt with more than one distinct "total"-labeled
    // amount (e.g. a duplicated/reprinted total) can be flagged — the
    // bottom-up first valid match is still the one used as totalAmount.
    final primaryTotalCandidates = <double>[];
    for (int i = lines.length - 1; i >= 0; i--) {
      final lineLower = lines[i].toLowerCase();
      // A subtotal line (e.g. "SUBTOTAL") also contains the bare "total"
      // substring but is never the grand total — exclude it here so it
      // can't be mistaken for one, or double-counted as a "conflicting"
      // total against the real total/grand-total line.
      if (_subtotalKeywords.any((kw) => lineLower.contains(kw))) continue;
      for (final kw in _primaryTotalKeywords) {
        if (lineLower.contains(kw)) {
          final amt = _extractAmountFromLine(lines[i]);
          if (amt != null && amt > 0) {
            primaryTotalCandidates.add(amt);
            grandTotal ??= amt;
          }
          break;
        }
      }
    }
    final hasConflictingTotals = primaryTotalCandidates.toSet().length > 1;

    // Secondary fallback: Payment instrument lines (e.g. "Tunai 50.000" or "QRIS 45.000")
    if (grandTotal == null) {
      for (int i = lines.length - 1; i >= 0; i--) {
        final lineLower = lines[i].toLowerCase();
        for (final kw in _paymentMethodKeywords) {
          if (lineLower.contains(kw)) {
            final amt = _extractAmountFromLine(lines[i]);
            if (amt != null && amt > 0) {
              grandTotal = amt;
              break;
            }
          }
        }
        if (grandTotal != null) break;
      }
    }

    // If still null, search highest numeric amount in bottom half
    if (grandTotal == null) {
      final searchLines = lines.sublist((lines.length / 2).floor());
      double maxFound = 0;
      for (final line in searchLines) {
        final amt = _extractAmountFromLine(line);
        if (amt != null && amt > maxFound) {
          maxFound = amt;
        }
      }
      if (maxFound > 0) grandTotal = maxFound;
    }

    // 6. Mathematical Verification & Confidence Calculation
    final confidenceReasons = <String>[];
    double confidence = 0.0;

    if (grandTotal != null && grandTotal > 0) {
      confidence += 0.35;
      confidenceReasons.add('Nominal total ditemukan');
    }

    if (merchant != null && merchant.isNotEmpty) {
      confidence += 0.20;
      confidenceReasons.add('Merchant teridentifikasi');
    }

    if (transactionDate != null) {
      confidence += 0.10;
      confidenceReasons.add('Tanggal transaksi valid');
    }

    if (extractedItems.isNotEmpty) {
      confidence += 0.10;
      confidenceReasons.add('${extractedItems.length} item berhasil dirinci');
    }

    // Check Math Consistency: Subtotal - Discount + Tax ≈ Grand Total
    bool isMathConsistent = false;
    final totalDiscSum = extractedDiscounts.fold<double>(
      0.0,
      (acc, d) => acc + d.amount,
    );
    final totalTaxSum = extractedTaxes.fold<double>(
      0.0,
      (acc, t) => acc + t.amount,
    );
    final baseSubtotal =
        subtotalAmount ??
        (extractedItems.isNotEmpty
            ? extractedItems.fold<double>(
                0.0,
                (acc, item) => acc + item.totalPrice,
              )
            : null);

    if (grandTotal != null && baseSubtotal != null && baseSubtotal > 0) {
      final expectedTotal = baseSubtotal - totalDiscSum + totalTaxSum;
      final diff = (expectedTotal - grandTotal).abs();
      // Allow rounding difference up to Rp 1.000
      if (diff <= 1000) {
        isMathConsistent = true;
        confidence += 0.25;
        confidenceReasons.add('Perhitungan matematika konsisten');
      }
    }

    confidence = confidence.clamp(0.0, 1.0);

    return ReceiptData(
      merchantName: merchant,
      totalAmount: grandTotal,
      subtotalAmount: subtotalAmount,
      // Nullable on purpose: if no date was actually found on the receipt,
      // we must not invent "today" and report it as if it were read from
      // the receipt (that previously inflated confidenceScore dishonestly).
      date: transactionDate,
      suggestedCategory: category,
      suggestedType: TransactionType.expense,
      items: extractedItems,
      discounts: extractedDiscounts,
      taxes: extractedTaxes,
      paymentMethod: paymentMethod,
      detectedWalletKeyword: detectedWalletKeyword,
      confidenceScore: confidence,
      confidenceReasons: confidenceReasons,
      isMathConsistent: isMathConsistent,
      hasConflictingTotals: hasConflictingTotals,
      rawText: rawText,
    );
  }

  /// Cleans general OCR noise (whitespace/invisible characters) WITHOUT
  /// touching any letters that could be part of a product or merchant name.
  /// Safe to run more than once — every step only removes/collapses
  /// characters, so a second pass is a no-op.
  static String _sanitizeOcrNoise(String line) {
    var text = line;

    // Remove zero-width / invisible formatting characters.
    text = text.replaceAll(RegExp(r'[​-‍﻿]'), '');
    // Normalize non-breaking spaces to regular spaces.
    text = text.replaceAll(' ', ' ');
    // Collapse repeated whitespace (tabs, multiple spaces) into one space.
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    text = text.trim();

    return text;
  }

  /// Normalizes a numeric candidate token's OCR digit-mixups (e.g. "l5O.OOO"
  /// -> "150.000"). Only ever applied to tokens that are already confirmed
  /// to be numeric candidates (via a real digit present, or an explicit
  /// Rp/IDR currency marker) — never to plain alphabetic text, so a product
  /// or merchant name like "BOSS" or "SOLO" is never mistaken for a number.
  static String _normalizeAmountCandidate(String token) {
    return token
        .replaceAll(RegExp(r'[lI|!]'), '1')
        .replaceAll(RegExp(r'[OoD]'), '0')
        .replaceAll(RegExp(r'[S]'), '5')
        .replaceAll(RegExp(r'[B]'), '8')
        .replaceAll(RegExp(r'[Z]'), '2');
  }

  /// Robust amount extractor with OCR typo tolerance
  static double? _extractAmountFromLine(String line) {
    if (line.trim().isEmpty) return null;

    // Correct common OCR digit mixups in price tokens (e.g. "Rp l5O.OOO"),
    // but only within tokens that are genuinely numeric candidates: either
    // explicitly prefixed by a currency marker, or already containing a
    // real digit. A pure-letter token never gets touched.
    var normalized = line;
    normalized = normalized.replaceAllMapped(
      RegExp(
        r'\b(?:(Rp\.?|IDR)\s*)?([0-9lIOoSBZz.,]{3,})\b',
        caseSensitive: false,
      ),
      (match) {
        final prefix = match.group(1);
        final token = match.group(2)!;
        final hasRealDigit = RegExp(r'\d').hasMatch(token);
        if (prefix == null && !hasRealDigit) {
          return match.group(0)!;
        }
        return '${prefix ?? ''}${_normalizeAmountCandidate(token)}';
      },
    );

    // Regex for standard Rupiah amount patterns
    final regex = RegExp(
      r'(?:Rp\.?|IDR)?\s*([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{2})?|[0-9]+)\b',
      caseSensitive: false,
    );
    final matches = regex.allMatches(normalized);

    for (final match in matches) {
      String? rawNum = match.group(1);
      if (rawNum != null) {
        // A long run of bare digits with no thousands separator and no
        // currency marker is almost certainly not a price — it's a phone
        // number, meter number, or receipt ID. Real prices are either
        // grouped ("150.000") or explicitly prefixed ("Rp 1500000"); only
        // reject the un-grouped, un-prefixed, implausibly-long case.
        final hasSeparator = rawNum.contains('.') || rawNum.contains(',');
        final hasCurrencyMarker = RegExp(
          r'rp|idr',
          caseSensitive: false,
        ).hasMatch(match.group(0) ?? '');
        if (!hasSeparator && !hasCurrencyMarker && rawNum.length > 7) {
          continue;
        }

        // Strip 2-decimal trailing cents (e.g. ,00 or .00)
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

  /// Parses an item line (e.g. "2x Teh Botol Rp 10.000" or "Roti Tawar 15.000")
  static ReceiptItem? _parseItemLine(String currentLine, String? nextLine) {
    final lower = currentLine.toLowerCase();

    // Ignore header, total, discount, tax, payment lines — shared list with
    // the main parse() scan, so a line can never be skipped there but
    // counted as an item here (or vice versa).
    if (_nonItemKeywords.any((kw) => lower.contains(kw))) return null;
    if (_isDateOrTime(currentLine)) return null;

    // Pattern A: Multiplier in line -> "2x Susu Ultra 14.000" or "Susu Ultra 2x 14.000" or "Susu Ultra 2 PCS x 7.000 14.000"
    final qtyMatch = RegExp(
      r'(\d+)\s*(?:x|pcs|bh|pack)?\s*@?\s*(?:Rp\.?)?\s*([0-9.,]+)?',
      caseSensitive: false,
    ).firstMatch(currentLine);
    int qty = 1;
    if (qtyMatch != null &&
        RegExp(r'\b\d+\s*x\b', caseSensitive: false).hasMatch(currentLine)) {
      qty = int.tryParse(qtyMatch.group(1)!) ?? 1;
    }

    final amt = _extractAmountFromLine(currentLine);
    if (amt != null && amt > 0) {
      // Clean name by removing amount tokens and qty tokens
      var name = currentLine
          .replaceAll(
            RegExp(
              r'(?:Rp\.?|IDR)?\s*[0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{2})?',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(RegExp(r'\b\d+\s*x\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'[=:@#*]', caseSensitive: false), '')
          .trim();

      if (name.length >= 2 && !RegExp(r'^\d+$').hasMatch(name)) {
        final suggestion = AutoCategorizeService.suggest(name);
        return ReceiptItem(
          name: name,
          qty: qty,
          unitPrice: qty > 1 ? (amt / qty) : amt,
          totalPrice: amt,
          suggestedCategory: suggestion?.category,
        );
      }
    }

    return null;
  }

  /// Extracts date and time across Indonesian & standard formats
  static DateTime? _extractDate(String line) {
    int? hour;
    int? minute;
    int? second;

    // Check if line contains time (HH:mm:ss or HH:mm)
    final timeMatch = RegExp(
      r'\b(\d{1,2})[:.](\d{2})(?:[:.](\d{2}))?\s*(?:wib|wita|wit)?\b',
      caseSensitive: false,
    ).firstMatch(line);
    if (timeMatch != null) {
      final h = int.tryParse(timeMatch.group(1)!);
      final m = int.tryParse(timeMatch.group(2)!);
      final s = timeMatch.group(3) != null
          ? int.tryParse(timeMatch.group(3)!)
          : 0;
      if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
        hour = h;
        minute = m;
        second = s ?? 0;
      }
    }

    // Pattern 1: YYYY-MM-DD or YYYY/MM/DD
    final ymd = RegExp(
      r'\b(20\d{2})[\/\-\.](0?[1-9]|1[0-2])[\/\-\.](0?[1-9]|[12]\d|3[01])\b',
    );
    final matchYmd = ymd.firstMatch(line);
    if (matchYmd != null) {
      final year = int.tryParse(matchYmd.group(1)!);
      final month = int.tryParse(matchYmd.group(2)!);
      final day = int.tryParse(matchYmd.group(3)!);
      if (day != null &&
          month != null &&
          year != null &&
          year >= 2000 &&
          year <= 2050 &&
          month >= 1 &&
          month <= 12 &&
          day >= 1 &&
          day <= 31) {
        return DateTime(year, month, day, hour ?? 12, minute ?? 0, second ?? 0);
      }
    }

    // Pattern 2: Indonesian & English textual months (e.g. "12 Januari 2026", "24-Feb-2026", "15 Agt 2026")
    final indonesianMonths = {
      'jan': 1,
      'januari': 1,
      'january': 1,
      'feb': 2,
      'februari': 2,
      'february': 2,
      'mar': 3,
      'maret': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'mei': 5,
      'may': 5,
      'jun': 6,
      'juni': 6,
      'june': 6,
      'jul': 7,
      'juli': 7,
      'july': 7,
      'agu': 8,
      'agustus': 8,
      'ags': 8,
      'agt': 8,
      'august': 8,
      'aug': 8,
      'sep': 9,
      'september': 9,
      'okt': 10,
      'oktober': 10,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'des': 12,
      'desember': 12,
      'dec': 12,
      'december': 12,
    };

    final textMonthRegex = RegExp(
      r'\b(0?[1-9]|[12]\d|3[01])[\s\-\.\/]+([a-zA-Z]{3,10})[\s\-\.\/]+(20\d{2}|\d{2})\b',
    );
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
          year >= 2000 &&
          year <= 2050 &&
          day >= 1 &&
          day <= 31) {
        return DateTime(year, month, day, hour ?? 12, minute ?? 0, second ?? 0);
      }
    }

    // Pattern 3: DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    final dmy = RegExp(
      r'\b(0?[1-9]|[12]\d|3[01])[\/\-\.](0?[1-9]|1[0-2])[\/\-\.](20\d{2}|\d{2})\b',
    );
    final matchDmy = dmy.firstMatch(line);
    if (matchDmy != null) {
      final day = int.tryParse(matchDmy.group(1)!);
      final month = int.tryParse(matchDmy.group(2)!);
      int? year = int.tryParse(matchDmy.group(3)!);
      if (year != null && year < 100) year += 2000;
      if (day != null &&
          month != null &&
          year != null &&
          year >= 2000 &&
          year <= 2050 &&
          month >= 1 &&
          month <= 12 &&
          day >= 1 &&
          day <= 31) {
        return DateTime(year, month, day, hour ?? 12, minute ?? 0, second ?? 0);
      }
    }

    return null;
  }

  /// Detects payment instrument and maps to active wallet keyword
  static (String?, String?) _detectPaymentMethod(List<String> lines) {
    for (final line in lines) {
      final l = line.toLowerCase();
      if (l.contains('qris')) return ('QRIS', 'qris');
      if (l.contains('gopay') || l.contains('go-pay'))
        return ('GoPay', 'gopay');
      if (l.contains('shopeepay') || l.contains('shopee pay'))
        return ('ShopeePay', 'shopeepay');
      if (l.contains('ovo')) return ('OVO', 'ovo');
      if (l.contains('dana')) return ('DANA', 'dana');
      if (l.contains('linkaja')) return ('LinkAja', 'linkaja');
      if (l.contains('debit bca') ||
          l.contains('bca debit') ||
          l.contains('kartu bca'))
        return ('Debit BCA', 'bca');
      if (l.contains('debit mandiri') || l.contains('mandiri debit'))
        return ('Debit Mandiri', 'mandiri');
      if (l.contains('bca')) return ('BCA', 'bca');
      if (l.contains('mandiri')) return ('Mandiri', 'mandiri');
      if (l.contains('bri')) return ('BRI', 'bri');
      if (l.contains('bni')) return ('BNI', 'bni');
      if (l.contains('cimb')) return ('CIMB Niaga', 'cimb');
      if (l.contains('permata')) return ('Permata', 'permata');
      if (l.contains('bsi')) return ('BSI', 'bsi');
      if (l.contains('tunai') || l.contains('cash')) return ('Tunai', 'tunai');
      if (l.contains('kartu kredit') ||
          l.contains('credit card') ||
          l.contains('cc'))
        return ('Kartu Kredit', 'kredit');
    }
    return (null, null);
  }

  static bool _containsBrand(String lineLower, String brand) {
    final regex = RegExp('\\b${RegExp.escape(brand)}\\b', caseSensitive: false);
    return regex.hasMatch(lineLower) || lineLower.contains(brand);
  }

  static bool _isDateOrTime(String line) {
    return RegExp(r'\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}').hasMatch(line) ||
        RegExp(r'\d{1,2}:\d{2}').hasMatch(line);
  }

  static bool _isAddressOrPhone(String line) {
    final l = line.toLowerCase();
    return l.startsWith('jl.') ||
        l.startsWith('jalan') ||
        l.contains('telp') ||
        l.contains('phone') ||
        l.contains('rt/rw');
  }
}
