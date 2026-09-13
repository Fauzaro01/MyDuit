import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/subscription_model.dart';
import 'package:myduit/models/transaction_model.dart';

void main() {
  group('SubscriptionModel Tests', () {
    test('monthlyCost calculation for different billing cycles', () {
      final monthlySub = SubscriptionModel(
        id: '1',
        name: 'Spotify',
        amount: 55000,
        billingCycle: BillingCycle.monthly,
        dueDay: 5,
      );
      expect(monthlySub.monthlyCost, 55000.0);

      final yearlySub = SubscriptionModel(
        id: '2',
        name: 'iCloud 2TB',
        amount: 1200000,
        billingCycle: BillingCycle.yearly,
        dueDay: 1,
      );
      expect(yearlySub.monthlyCost, 100000.0);

      final weeklySub = SubscriptionModel(
        id: '3',
        name: 'Gym pass',
        amount: 50000,
        billingCycle: BillingCycle.weekly,
        dueDay: 1,
      );
      expect(weeklySub.monthlyCost, 50000 * 4.33);
    });

    test('toMap and fromMap preserves all fields', () {
      final sub = SubscriptionModel(
        id: '10',
        name: 'Netflix',
        amount: 186000,
        billingCycle: BillingCycle.monthly,
        dueDay: 15,
        category: TransactionCategory.entertainment,
        isActive: true,
      );

      final map = sub.toMap();
      final restored = SubscriptionModel.fromMap(map);

      expect(restored.id, sub.id);
      expect(restored.name, sub.name);
      expect(restored.amount, sub.amount);
      expect(restored.billingCycle, sub.billingCycle);
      expect(restored.dueDay, sub.dueDay);
      expect(restored.category, sub.category);
      expect(restored.isActive, sub.isActive);
    });
  });
}
