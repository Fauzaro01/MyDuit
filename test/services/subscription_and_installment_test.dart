import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/subscription_model.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/models/installment_model.dart';
import 'package:myduit/services/subscription_analyzer_service.dart';

void main() {
  group('Subscription & Installment Engine Tests', () {
    test('detects price hike accurately when transaction is higher than baseline', () {
      final sub = SubscriptionModel(
        id: 'sub1',
        name: 'Netflix Premium',
        amount: 186000,
        billingCycle: BillingCycle.monthly,
        dueDay: 15,
      );

      final txOld = TransactionModel(
        id: 'tx1',
        title: 'Netflix Premium',
        amount: 186000,
        type: TransactionType.expense,
        category: TransactionCategory.bills,
        date: DateTime(2026, 8, 15),
      );

      final txHiked = TransactionModel(
        id: 'tx2',
        title: 'Netflix Premium Family',
        amount: 216000, // 30.000 increase (~16.1%)
        type: TransactionType.expense,
        category: TransactionCategory.bills,
        date: DateTime(2026, 9, 15),
      );

      final alerts = SubscriptionAnalyzerService.detectPriceHikes(
        subscriptions: [sub],
        transactions: [txOld, txHiked],
      );

      expect(alerts.length, 1);
      final alert = alerts.first;
      expect(alert.oldAmount, 186000);
      expect(alert.newAmount, 216000);
      expect(alert.percentageIncrease, closeTo(16.129, 0.01));
      expect(alert.annualImpact, 360000); // 30.000 * 12
    });

    test('installment model calculates remaining tenure and amounts', () {
      final installment = InstallmentModel(
        title: 'Cicilan Laptop MacBook',
        totalPrincipal: 24000000,
        monthlyPayment: 2000000,
        totalTenorMonths: 12,
        paidTenorMonths: 5,
      );

      expect(installment.isCompleted, isFalse);
      expect(installment.remainingTenorMonths, 7);
      expect(installment.totalPaidAmount, 10000000);
      expect(installment.totalRemainingAmount, 14000000);
      expect(installment.progressPercentage, closeTo(5 / 12, 0.001));
    });
  });
}
