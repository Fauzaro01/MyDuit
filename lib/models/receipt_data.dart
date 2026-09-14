import '../models/transaction_model.dart';

class ReceiptItem {
  final String name;
  final int qty;
  final double? unitPrice;
  final double totalPrice;

  const ReceiptItem({
    required this.name,
    this.qty = 1,
    this.unitPrice,
    required this.totalPrice,
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

  const ReceiptDiscount({
    required this.name,
    required this.amount,
  });
}

class ReceiptTax {
  final String name;
  final double? percentage;
  final double amount;

  const ReceiptTax({
    required this.name,
    this.percentage,
    required this.amount,
  });
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
    required this.rawText,
  });

  /// Backwards compatibility helper returning string lines of items
  List<String> get lineItems => items.isNotEmpty
      ? items.map((i) => i.toString()).toList()
      : const [];

  /// Human friendly confidence rating
  String get confidenceLabel {
    if (confidenceScore >= 0.8) return 'Tinggi';
    if (confidenceScore >= 0.5) return 'Sedang';
    return 'Perlu Diperiksa';
  }
}
