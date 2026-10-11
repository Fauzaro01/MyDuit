import '../models/transaction_model.dart';

class ReceiptItem {
  final String name;
  final int qty;
  final double? unitPrice;
  final double totalPrice;
  final TransactionCategory? suggestedCategory;

  const ReceiptItem({
    required this.name,
    this.qty = 1,
    this.unitPrice,
    required this.totalPrice,
    this.suggestedCategory,
  });

  @override
  String toString() {
    if (qty > 1 && unitPrice != null) {
      return '$name (${qty}x @${unitPrice!.toStringAsFixed(0)}) = ${totalPrice.toStringAsFixed(0)}';
    }
    return '$name = ${totalPrice.toStringAsFixed(0)}';
  }
}

class ReceiptDiscount {
  final String name;
  final double amount;

  const ReceiptDiscount({required this.name, required this.amount});
}

class ReceiptTax {
  final String name;
  final double? percentage;
  final double amount;

  const ReceiptTax({required this.name, this.percentage, required this.amount});
}

class ReceiptData {
  final String? merchantName;
  final double? totalAmount;
  final double? subtotalAmount;
  final DateTime? date;
  final TransactionCategory suggestedCategory;
  final TransactionType suggestedType;
  final List<ReceiptItem> items;
  final List<ReceiptDiscount> discounts;
  final List<ReceiptTax> taxes;
  final String? paymentMethod;
  final String? detectedWalletKeyword;
  final double confidenceScore; // 0.0 - 1.0
  final List<String> confidenceReasons;
  final bool isMathConsistent;
  final String rawText;

  /// True when more than one distinct "total"-labeled line was found on the
  /// receipt (e.g. a reprinted/duplicated total) — the parser still picks
  /// one value for [totalAmount], but flags the ambiguity so it can be
  /// surfaced as a warning instead of silently trusting the first match.
  final bool hasConflictingTotals;

  const ReceiptData({
    this.merchantName,
    this.totalAmount,
    this.subtotalAmount,
    this.date,
    this.suggestedCategory = TransactionCategory.shopping,
    this.suggestedType = TransactionType.expense,
    this.items = const [],
    this.discounts = const [],
    this.taxes = const [],
    this.paymentMethod,
    this.detectedWalletKeyword,
    this.confidenceScore = 0.0,
    this.confidenceReasons = const [],
    this.isMathConsistent = false,
    this.hasConflictingTotals = false,
    required this.rawText,
  });

  /// Backwards compatibility helper returning string lines of items
  List<String> get lineItems =>
      items.isNotEmpty ? items.map((i) => i.toString()).toList() : const [];

  /// Human friendly confidence rating
  String get confidenceLabel {
    if (confidenceScore >= 0.8) return 'Tinggi';
    if (confidenceScore >= 0.5) return 'Sedang';
    return 'Perlu Diperiksa';
  }

  /// Returns a copy with [items] replaced — used by the review UI to
  /// re-validate against the user's edited item list without re-parsing.
  ReceiptData copyWith({List<ReceiptItem>? items}) {
    return ReceiptData(
      merchantName: merchantName,
      totalAmount: totalAmount,
      subtotalAmount: subtotalAmount,
      date: date,
      suggestedCategory: suggestedCategory,
      suggestedType: suggestedType,
      items: items ?? this.items,
      discounts: discounts,
      taxes: taxes,
      paymentMethod: paymentMethod,
      detectedWalletKeyword: detectedWalletKeyword,
      confidenceScore: confidenceScore,
      confidenceReasons: confidenceReasons,
      isMathConsistent: isMathConsistent,
      hasConflictingTotals: hasConflictingTotals,
      rawText: rawText,
    );
  }
}
