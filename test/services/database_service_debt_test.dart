import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:myduit/models/debt_model.dart';
import 'package:myduit/models/split_bill_model.dart';
import 'package:myduit/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseService.addDebtPayment', () {
    test('full payment settles the debt and returns true', () async {
      final dbService = DatabaseService();
      final debt = DebtModel(
        personName: 'Budi',
        amount: 100000,
        type: DebtType.owedToMe,
      );
      await dbService.insertDebt(debt);

      final justSettled = await dbService.addDebtPayment(debt.id, 100000);
      expect(justSettled, isTrue);

      final all = await dbService.getAllDebts();
      final updated = all.firstWhere((d) => d.id == debt.id);
      expect(updated.isSettled, isTrue);
      expect(updated.paidAmount, 100000);
    });

    test('partial payment does not settle the debt', () async {
      final dbService = DatabaseService();
      final debt = DebtModel(
        personName: 'Siti',
        amount: 100000,
        type: DebtType.iOwe,
      );
      await dbService.insertDebt(debt);

      final justSettled = await dbService.addDebtPayment(debt.id, 40000);
      expect(justSettled, isFalse);

      final all = await dbService.getAllDebts();
      final updated = all.firstWhere((d) => d.id == debt.id);
      expect(updated.isSettled, isFalse);
      expect(updated.paidAmount, 40000);
    });

    test('settling a debt synced from a split bill marks the participant paid and auto-settles the bill', () async {
      final dbService = DatabaseService();
      final debt = DebtModel(
        personName: 'Rina',
        amount: 50000,
        type: DebtType.owedToMe,
      );
      await dbService.insertDebt(debt);

      final participant = SplitParticipant(
        billId: 'bill-x',
        name: 'Rina',
        amount: 50000,
        debtId: debt.id,
      );
      final bill = SplitBillModel(
        id: 'bill-x',
        title: 'Makan Malam',
        totalAmount: 50000,
        participants: [participant],
      );
      await dbService.insertSplitBill(bill);

      final justSettled = await dbService.addDebtPayment(debt.id, 50000);
      expect(justSettled, isTrue);

      final db = await dbService.database;
      final participants = await db.query(
        'split_participants',
        where: 'billId = ?',
        whereArgs: ['bill-x'],
      );
      expect(participants.single['isPaid'], 1);

      final bills = await db.query(
        'split_bills',
        where: 'id = ?',
        whereArgs: ['bill-x'],
      );
      expect(bills.single['isSettled'], 1);
    });
  });

  group('DatabaseService.deleteDebt', () {
    test('clears a dangling split_participants.debtId reference', () async {
      final dbService = DatabaseService();
      final debt = DebtModel(
        personName: 'Andi',
        amount: 25000,
        type: DebtType.owedToMe,
      );
      await dbService.insertDebt(debt);

      final participant = SplitParticipant(
        billId: 'bill-y',
        name: 'Andi',
        amount: 25000,
        debtId: debt.id,
      );
      final bill = SplitBillModel(
        id: 'bill-y',
        title: 'Nonton',
        totalAmount: 25000,
        participants: [participant],
      );
      await dbService.insertSplitBill(bill);

      await dbService.deleteDebt(debt.id);

      final db = await dbService.database;
      final rows = await db.query(
        'split_participants',
        where: 'billId = ?',
        whereArgs: ['bill-y'],
      );
      expect(rows.single['debtId'], isNull);
    });
  });

  group('DatabaseService.toggleSplitParticipantPaid bidirectional reconciliation', () {
    test('marking participant paid updates linked debt to settled', () async {
      final dbService = DatabaseService();
      final debt = DebtModel(
        personName: 'Dewi',
        amount: 75000,
        type: DebtType.owedToMe,
      );
      await dbService.insertDebt(debt);

      final participant = SplitParticipant(
        id: 'part-dewi',
        billId: 'bill-z',
        name: 'Dewi',
        amount: 75000,
        debtId: debt.id,
        isPaid: false,
      );
      final bill = SplitBillModel(
        id: 'bill-z',
        title: 'Lunch',
        totalAmount: 75000,
        participants: [participant],
      );
      await dbService.insertSplitBill(bill);

      await dbService.toggleSplitParticipantPaid('part-dewi', true);

      final debts = await dbService.getAllDebts();
      final updatedDebt = debts.firstWhere((d) => d.id == debt.id);
      expect(updatedDebt.isSettled, isTrue);
      expect(updatedDebt.paidAmount, 75000);
    });
  });
}
