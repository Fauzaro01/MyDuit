import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/debt_model.dart';
import 'package:myduit/models/subscription_model.dart';
import 'package:myduit/models/transaction_model.dart';

void main() {
  group('Enhancements Batch Unit Tests', () {
    test('DebtModel sorting by dueDate, amount, and name', () {
      final now = DateTime.now();
      final debt1 = DebtModel(
        personName: 'Charlie',
        amount: 500000,
        type: DebtType.iOwe,
        dueDate: now.add(const Duration(days: 10)),
      );
      final debt2 = DebtModel(
        personName: 'Alice',
        amount: 1000000,
        type: DebtType.iOwe,
        dueDate: now.add(const Duration(days: 2)),
      );
      final debt3 = DebtModel(
        personName: 'Bob',
        amount: 250000,
        type: DebtType.iOwe,
        dueDate: now.subtract(const Duration(days: 1)),
      );

      final list = [debt1, debt2, debt3];

      // Sort by due date
      list.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      expect(list.first.personName, 'Bob');
      expect(list.last.personName, 'Charlie');

      // Sort by amount desc
      list.sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));
      expect(list.first.personName, 'Alice');
      expect(list.last.personName, 'Bob');

      // Sort by name asc
      list.sort((a, b) => a.personName.compareTo(b.personName));
      expect(list.first.personName, 'Alice');
      expect(list[1].personName, 'Bob');
      expect(list.last.personName, 'Charlie');
    });

    test('DebtModel isOverdue and daysUntilDue calculation', () {
      final now = DateTime.now();
      final overdueDebt = DebtModel(
        personName: 'David',
        amount: 100000,
        type: DebtType.iOwe,
        dueDate: now.subtract(const Duration(days: 3)),
      );
      expect(overdueDebt.isOverdue, isTrue);

      final upcomingDebt = DebtModel(
        personName: 'Eva',
        amount: 100000,
        type: DebtType.owedToMe,
        dueDate: now.add(const Duration(days: 5)),
      );
      expect(upcomingDebt.isOverdue, isFalse);
      expect(upcomingDebt.daysUntilDue, isNotNull);
      expect(upcomingDebt.daysUntilDue, inInclusiveRange(4, 6));
    });

    test('SubscriptionModel billingCycle monthly cost accurately computed', () {
      final monthly = SubscriptionModel(
        name: 'Netflix',
        amount: 186000,
        billingCycle: BillingCycle.monthly,
        dueDay: 15,
      );
      expect(monthly.monthlyCost, 186000);

      final yearly = SubscriptionModel(
        name: 'iCloud',
        amount: 1200000,
        billingCycle: BillingCycle.yearly,
        dueDay: 1,
      );
      expect(yearly.monthlyCost, 100000);

      final weekly = SubscriptionModel(
        name: 'Gym pass',
        amount: 50000,
        billingCycle: BillingCycle.weekly,
        dueDay: 1,
      );
      expect(weekly.monthlyCost, closeTo(216500, 1000));
    });

    test('CSV serialization escaping formatting matches spec', () {
      final tx = TransactionModel(
        id: 'tx-123',
        title: 'Dinner at "Warung" Steak',
        amount: 125000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime(2026, 9, 14),
        note: 'Includes 10% tax, tip',
        tags: ['dinner', 'treat'],
      );

      final titleEscaped = '"${tx.title.replaceAll('"', '""')}"';
      final noteEscaped = '"${(tx.note ?? '').replaceAll('"', '""')}"';
      final tagsEscaped = '"${tx.tags.join(';')}"';

      expect(titleEscaped, '"Dinner at ""Warung"" Steak"');
      expect(noteEscaped, '"Includes 10% tax, tip"');
      expect(tagsEscaped, '"dinner;treat"');
    });
  });
}
