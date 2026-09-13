import '../models/transaction_model.dart';

class ImportTransactionItem {
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final String? note;
  bool isSelected;
  bool isDuplicate;

  ImportTransactionItem({
    required this.title,
    required this.amount,
    required this.type,
    this.category = TransactionCategory.other,
    required this.date,
    this.note,
    this.isSelected = true,
    this.isDuplicate = false,
  });

  TransactionModel toTransactionModel({String? walletId}) {
    return TransactionModel(
      title: title,
      amount: amount,
      type: type,
      category: category,
      date: date,
      note: note,
      walletId: walletId,
    );
  }
}
