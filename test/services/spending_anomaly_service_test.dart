import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/services/spending_anomaly_service.dart';

void main() {
  group('SpendingAnomalyService Tests', () {
    test('returns empty if not enough expense transactions', () {
      final txs = [
        TransactionModel(
          title: 'Gaji',
          amount: 5000000,
          type: TransactionType.income,
          category: TransactionCategory.salary,
          date: DateTime.now(),
        ),
      ];

      final anomalies = SpendingAnomalyService.detectAnomalies(txs);
      expect(anomalies, isEmpty);
    });

    test('detects high anomaly transaction', () {
      final now = DateTime.now();
      final txs = [
        TransactionModel(
          title: 'Makan 1',
          amount: 25000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(now.year, now.month, 1),
        ),
        TransactionModel(
          title: 'Makan 2',
          amount: 30000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(now.year, now.month, 2),
        ),
        TransactionModel(
          title: 'Makan 3',
          amount: 28000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(now.year, now.month, 3),
        ),
        TransactionModel(
          title: 'Makan 4',
          amount: 32000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(now.year, now.month, 4),
        ),
        TransactionModel(
          title: 'Makan Mewah Anomali',
          amount: 350000, // > 10x average
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(now.year, now.month, 5),
        ),
      ];

      final anomalies = SpendingAnomalyService.detectAnomalies(txs);
      expect(anomalies, isNotEmpty);
      expect(anomalies.any((a) => a.title.contains('Makan Mewah Anomali')), isTrue);
    });
  });
}
