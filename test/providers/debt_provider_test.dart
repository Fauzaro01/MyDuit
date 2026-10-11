import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:myduit/models/debt_model.dart';
import 'package:myduit/providers/debt_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DebtProvider Tests', () {
    test('loadDebts, addDebt, and balance calculations', () async {
      final provider = DebtProvider();
      await provider.loadDebts();

      // Clean existing if any
      for (final d in List.of(provider.debts)) {
        await provider.deleteDebt(d.id);
      }
      expect(provider.debts, isEmpty);
      expect(provider.totalIOwe, 0);
      expect(provider.totalOwedToMe, 0);

      // Add iOwe debt
      final debt1 = DebtModel(
        personName: 'Andi',
        amount: 500000,
        type: DebtType.iOwe,
      );
      await provider.addDebt(debt1);

      // Add owedToMe debt
      final debt2 = DebtModel(
        personName: 'Budi',
        amount: 300000,
        type: DebtType.owedToMe,
      );
      await provider.addDebt(debt2);

      expect(provider.debts.length, 2);
      expect(provider.myDebts.length, 1);
      expect(provider.myReceivables.length, 1);
      expect(provider.totalIOwe, 500000);
      expect(provider.totalOwedToMe, 300000);

      // Partial payment
      final justSettled = await provider.addPayment(debt1.id, 200000);
      expect(justSettled, isFalse);
      expect(provider.totalIOwe, 300000);

      // Final payment settling the debt
      final fullSettled = await provider.addPayment(debt1.id, 300000);
      expect(fullSettled, isTrue);
      expect(provider.settledDebts.length, 1);
      expect(provider.totalIOwe, 0);
    });
  });
}
