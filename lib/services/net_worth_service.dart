import '../models/asset_model.dart';
import '../models/debt_model.dart';
import '../models/wallet_model.dart';

class NetWorthService {
  /// Calculate consolidated Net Worth
  /// Net Worth = Total Cash/Wallets + Total Assets + Piutang (Owed to Me) - Hutang (I Owe)
  static NetWorthSnapshot calculate({
    required List<WalletModel> wallets,
    required Map<String, double> walletBalances,
    required List<AssetModel> assets,
    required List<DebtModel> debts,
  }) {
    double totalWallet = 0.0;
    for (final w in wallets) {
      totalWallet += walletBalances[w.id] ?? 0.0;
    }

    final totalAssets = assets.fold(0.0, (sum, a) => sum + a.amount);

    final totalReceivables = debts
        .where((d) => d.type == DebtType.owedToMe && !d.isSettled)
        .fold(0.0, (sum, d) => sum + d.remainingAmount);

    final totalDebts = debts
        .where((d) => d.type == DebtType.iOwe && !d.isSettled)
        .fold(0.0, (sum, d) => sum + d.remainingAmount);

    return NetWorthSnapshot(
      totalWalletBalance: totalWallet,
      totalAssets: totalAssets,
      totalReceivables: totalReceivables,
      totalDebts: totalDebts,
      date: DateTime.now(),
    );
  }
}
