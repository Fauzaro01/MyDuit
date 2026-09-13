import '../models/transaction_model.dart';

class ReceiptData {
  final String? merchantName;
  final double? totalAmount;
  final DateTime? date;
  final TransactionCategory suggestedCategory;
  final TransactionType suggestedType;
  final List<String> lineItems;
  final String rawText;

  const ReceiptData({
    this.merchantName,
    this.totalAmount,
    this.date,
    this.suggestedCategory = TransactionCategory.shopping,
    this.suggestedType = TransactionType.expense,
    this.lineItems = const [],
    required this.rawText,
  });
}
