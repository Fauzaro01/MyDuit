import '../models/subscription_model.dart';
import '../models/transaction_model.dart';

class SubscriptionHikeAlert {
  final SubscriptionModel subscription;
  final TransactionModel recentTransaction;
  final double oldAmount;
  final double newAmount;
  final double percentageIncrease;
  final double annualImpact;

  const SubscriptionHikeAlert({
    required this.subscription,
    required this.recentTransaction,
    required this.oldAmount,
    required this.newAmount,
    required this.percentageIncrease,
    required this.annualImpact,
  });
}

class SubscriptionAnalyzerService {
  /// Analyzes recent expense transactions to identify unexpected price increases
  /// comparing transaction amount against baseline subscription amount
  static List<SubscriptionHikeAlert> detectPriceHikes({
    required List<SubscriptionModel> subscriptions,
    required List<TransactionModel> transactions,
  }) {
    final List<SubscriptionHikeAlert> alerts = [];
    final activeSubs = subscriptions.where((s) => s.isActive).toList();

    for (final sub in activeSubs) {
      final subNameNorm = sub.name.trim().toLowerCase();

      // Find matching transactions (by title containing sub name or identical category)
      final matches = transactions.where((tx) {
        if (tx.type != TransactionType.expense) return false;
        final txTitleNorm = tx.title.trim().toLowerCase();
        return txTitleNorm.contains(subNameNorm) || subNameNorm.contains(txTitleNorm);
      }).toList();

      if (matches.isEmpty) continue;

      // Sort by date descending to get the most recent transaction
      matches.sort((a, b) => b.date.compareTo(a.date));
      final latestTx = matches.first;

      // Compare amount: if transaction is higher than subscription baseline amount
      if (latestTx.amount > sub.amount) {
        final diff = latestTx.amount - sub.amount;
        final pct = (diff / sub.amount) * 100;

        // Calculate annual impact based on cycle
        double annualImpact = diff * 12; // default monthly
        if (sub.billingCycle == BillingCycle.yearly) {
          annualImpact = diff;
        } else if (sub.billingCycle == BillingCycle.weekly) {
          annualImpact = diff * 52;
        }

        alerts.add(
          SubscriptionHikeAlert(
            subscription: sub,
            recentTransaction: latestTx,
            oldAmount: sub.amount,
            newAmount: latestTx.amount,
            percentageIncrease: pct,
            annualImpact: annualImpact,
          ),
        );
      }
    }

    return alerts;
  }
}
