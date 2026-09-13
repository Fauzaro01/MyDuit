import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/asset_model.dart';
import 'package:myduit/models/debt_model.dart';
import 'package:myduit/models/wallet_model.dart';
import 'package:myduit/services/net_worth_service.dart';

void main() {
  group('NetWorthService Tests', () {
    test('calculate returns correct consolidated net worth snapshot', () {
      final wallets = [
        WalletModel(id: '1', name: 'BCA'),
        WalletModel(id: '2', name: 'Dompet Tunai'),
      ];
      final walletBalances = {'1': 10000000.0, '2': 500000.0};

      final assets = [
        AssetModel(
          id: '1',
          name: 'Emas Antam 10gr',
          type: AssetType.gold,
          amount: 14000000,
        ),
        AssetModel(
          id: '2',
          name: 'Reksadana',
          type: AssetType.mutualFund,
          amount: 6000000,
        ),
      ];

      final debts = [
        DebtModel(
          id: '1',
          personName: 'Pinjaman Bank',
          amount: 5000000,
          type: DebtType.iOwe, // Liability
          isSettled: false,
          createdAt: DateTime(2026, 9, 1),
        ),
        DebtModel(
          id: '2',
          personName: 'Andi Pinjam Uang',
          amount: 2000000,
          type: DebtType.owedToMe, // Receivable
          isSettled: false,
          createdAt: DateTime(2026, 9, 1),
        ),
        DebtModel(
          id: '3',
          personName: 'Hutang Lunas',
          amount: 1000000,
          type: DebtType.iOwe,
          isSettled: true, // Should be ignored
          createdAt: DateTime(2026, 9, 1),
        ),
      ];

      final snapshot = NetWorthService.calculate(
        wallets: wallets,
        walletBalances: walletBalances,
        assets: assets,
        debts: debts,
      );

      // Wallet = 10.5M
      // Assets = 20M
      // Receivables = 2M
      // Gross Assets = 10.5M + 20M + 2M = 32.5M
      // Liabilities = 5M
      // Net Worth = 32.5M - 5M = 27.5M
      expect(snapshot.totalWalletBalance, 10500000.0);
      expect(snapshot.totalAssets, 20000000.0);
      expect(snapshot.totalReceivables, 2000000.0);
      expect(snapshot.grossAssets, 32500000.0);
      expect(snapshot.totalLiabilities, 5000000.0);
      expect(snapshot.netWorth, 27500000.0);
    });
  });
}
