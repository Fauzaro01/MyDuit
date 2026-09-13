import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/debt_payment_model.dart';
import 'package:myduit/models/transfer_model.dart';

void main() {
  group('DebtPaymentModel Tests', () {
    test('toMap and fromMap serializes correctly', () {
      final now = DateTime(2026, 9, 13, 10, 30);
      final payment = DebtPaymentModel(
        id: 'dp-123',
        debtId: 'debt-456',
        amount: 250000,
        date: now,
        note: 'Cicilan ke-1',
      );

      final map = payment.toMap();
      expect(map['id'], equals('dp-123'));
      expect(map['debtId'], equals('debt-456'));
      expect(map['amount'], equals(250000.0));
      expect(map['date'], equals(now.millisecondsSinceEpoch));
      expect(map['note'], equals('Cicilan ke-1'));

      final reconstructed = DebtPaymentModel.fromMap(map);
      expect(reconstructed.id, equals('dp-123'));
      expect(reconstructed.debtId, equals('debt-456'));
      expect(reconstructed.amount, equals(250000.0));
      expect(reconstructed.date.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
      expect(reconstructed.note, equals('Cicilan ke-1'));
    });
  });

  group('TransferModel with Admin Fee Tests', () {
    test('Serializes and deserializes adminFee correctly', () {
      final transfer = TransferModel(
        id: 'tf-1',
        fromWalletId: 'w-from',
        toWalletId: 'w-to',
        amount: 500000,
        adminFee: 2500,
        note: 'Transfer BI-Fast',
      );

      final map = transfer.toMap();
      expect(map['adminFee'], equals(2500.0));

      final reconstructed = TransferModel.fromMap(map);
      expect(reconstructed.adminFee, equals(2500.0));
      expect(reconstructed.amount, equals(500000.0));
    });

    test('Defaults adminFee to 0.0 when missing from map', () {
      final map = {
        'id': 'tf-2',
        'fromWalletId': 'w-1',
        'toWalletId': 'w-2',
        'amount': 100000.0,
        'date': DateTime.now().millisecondsSinceEpoch,
      };

      final reconstructed = TransferModel.fromMap(map);
      expect(reconstructed.adminFee, equals(0.0));
    });
  });
}
