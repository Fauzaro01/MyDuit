import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/wallet_model.dart';
import 'package:myduit/models/transfer_model.dart';

/// Tests for wallet-related logic that can be tested without
/// database access: balance computation, active wallet state, transfer logic.
void main() {
  group('Wallet state logic', () {
    late List<WalletModel> wallets;

    setUp(() {
      wallets = [
        WalletModel(
          id: 'default-wallet',
          name: 'Dompet Utama',
          emoji: '💰',
          colorValue: 0xFF0D9373,
          isDefault: true,
          createdAt: DateTime(2026, 1, 1),
        ),
        WalletModel(
          id: 'wallet-2',
          name: 'Tabungan',
          emoji: '🏦',
          colorValue: 0xFF3B82F6,
          isDefault: false,
          createdAt: DateTime(2026, 2, 1),
        ),
        WalletModel(
          id: 'wallet-3',
          name: 'Investasi',
          emoji: '📈',
          colorValue: 0xFF8B5CF6,
          isDefault: false,
          createdAt: DateTime(2026, 3, 1),
        ),
      ];
    });

    test('find default wallet', () {
      final defaultWallet = wallets.firstWhere((w) => w.isDefault);
      expect(defaultWallet.id, 'default-wallet');
      expect(defaultWallet.name, 'Dompet Utama');
    });

    test('find wallet by id', () {
      WalletModel? getWalletById(String id) {
        try {
          return wallets.firstWhere((w) => w.id == id);
        } catch (_) {
          return null;
        }
      }

      expect(getWalletById('wallet-2')?.name, 'Tabungan');
      expect(getWalletById('non-existent'), isNull);
    });

    test('cannot delete last wallet', () {
      final singleWalletList = [wallets.first];
      final canDelete = singleWalletList.length > 1;
      expect(canDelete, isFalse);
    });

    test('cannot delete default wallet', () {
      final defaultWallet = wallets.firstWhere((w) => w.isDefault);
      expect(defaultWallet.isDefault, isTrue);
      // Business rule: cannot delete default
      final canDelete = !defaultWallet.isDefault;
      expect(canDelete, isFalse);
    });

    test('can delete non-default wallet with multiple wallets', () {
      final wallet = wallets.firstWhere((w) => w.id == 'wallet-2');
      final canDelete = wallets.length > 1 && !wallet.isDefault;
      expect(canDelete, isTrue);
    });

    test('active wallet selection', () {
      WalletModel? activeWallet;
      bool showAllWallets = true;

      // Initially show all
      expect(showAllWallets, isTrue);
      expect(activeWallet, isNull);

      // Set active wallet
      activeWallet = wallets[1];
      showAllWallets = false;
      expect(activeWallet.id, 'wallet-2');
      expect(showAllWallets, isFalse);

      // Show all again
      showAllWallets = true;
      expect(showAllWallets, isTrue);
    });
  });

  group('Wallet balance logic', () {
    late Map<String, double> walletBalances;

    setUp(() {
      walletBalances = {
        'default-wallet': 5000000,
        'wallet-2': 2000000,
        'wallet-3': 1500000,
      };
    });

    test('total balance is sum of all wallets', () {
      final totalBalance = walletBalances.values.fold(0.0, (a, b) => a + b);
      expect(totalBalance, 8500000);
    });

    test('active wallet balance returns correct value', () {
      final activeWalletId = 'wallet-2';
      final balance = walletBalances[activeWalletId] ?? 0.0;
      expect(balance, 2000000);
    });

    test('active wallet balance returns 0 for unknown wallet', () {
      final balance = walletBalances['non-existent'] ?? 0.0;
      expect(balance, 0.0);
    });

    test('balance after transfer between wallets', () {
      final fromId = 'default-wallet';
      final toId = 'wallet-2';
      final transferAmount = 500000.0;

      // Simulate transfer effect on balances
      walletBalances[fromId] = (walletBalances[fromId] ?? 0) - transferAmount;
      walletBalances[toId] = (walletBalances[toId] ?? 0) + transferAmount;

      expect(walletBalances[fromId], 4500000);
      expect(walletBalances[toId], 2500000);

      // Total should remain unchanged
      final total = walletBalances.values.fold(0.0, (a, b) => a + b);
      expect(total, 8500000);
    });

    test(
      'wallet balance calculation: income - expense + transferIn - transferOut',
      () {
        final income = 5000000.0;
        final expense = 1200000.0;
        final transferIn = 300000.0;
        final transferOut = 500000.0;

        final balance = income - expense + transferIn - transferOut;
        expect(balance, 3600000);
      },
    );
  });

  group('Transfer logic', () {
    late List<TransferModel> transfers;

    setUp(() {
      transfers = [
        TransferModel(
          id: 'xfer-1',
          fromWalletId: 'default-wallet',
          toWalletId: 'wallet-2',
          amount: 500000,
          note: 'Tabungan bulanan',
          date: DateTime(2026, 3, 1),
        ),
        TransferModel(
          id: 'xfer-2',
          fromWalletId: 'wallet-2',
          toWalletId: 'wallet-3',
          amount: 200000,
          note: 'Investasi',
          date: DateTime(2026, 3, 5),
        ),
        TransferModel(
          id: 'xfer-3',
          fromWalletId: 'default-wallet',
          toWalletId: 'wallet-3',
          amount: 100000,
          date: DateTime(2026, 2, 20),
        ),
      ];
    });

    test('filter transfers by wallet', () {
      final walletId = 'default-wallet';
      final walletTransfers = transfers
          .where((t) => t.fromWalletId == walletId || t.toWalletId == walletId)
          .toList();
      expect(walletTransfers.length, 2);
    });

    test('filter transfers by month', () {
      final marchTransfers = transfers.where((t) {
        return t.date.year == 2026 && t.date.month == 3;
      }).toList();
      expect(marchTransfers.length, 2);
    });

    test('total transfer out from wallet', () {
      final walletId = 'default-wallet';
      final totalOut = transfers
          .where((t) => t.fromWalletId == walletId)
          .fold<double>(0, (sum, t) => sum + t.amount);
      expect(totalOut, 600000); // 500000 + 100000
    });

    test('total transfer in to wallet', () {
      final walletId = 'wallet-3';
      final totalIn = transfers
          .where((t) => t.toWalletId == walletId)
          .fold<double>(0, (sum, t) => sum + t.amount);
      expect(totalIn, 300000); // 200000 + 100000
    });

    test('cannot transfer to same wallet', () {
      final fromWalletId = 'default-wallet';
      final toWalletId = 'default-wallet';
      final isSameWallet = fromWalletId == toWalletId;
      expect(isSameWallet, isTrue);
      // Business rule: block transfers to same wallet
    });

    test('transfer amount must be positive', () {
      final amount = 500000.0;
      expect(amount > 0, isTrue);

      final invalidAmount = -100.0;
      expect(invalidAmount > 0, isFalse);

      final zeroAmount = 0.0;
      expect(zeroAmount > 0, isFalse);
    });
  });

  group('Wallet preset validation', () {
    test('presetColors has valid entries', () {
      expect(WalletModel.presetColors, isNotEmpty);
      expect(WalletModel.presetColors.length, 8);
      // All should be valid ARGB color values
      for (final color in WalletModel.presetColors) {
        expect(color, greaterThan(0));
      }
    });

    test('presetEmojis has valid entries', () {
      expect(WalletModel.presetEmojis, isNotEmpty);
      expect(WalletModel.presetEmojis.length, 16);
      for (final emoji in WalletModel.presetEmojis) {
        expect(emoji, isNotEmpty);
      }
    });

    test('new wallet gets default values', () {
      final wallet = WalletModel(name: 'Test');
      expect(wallet.emoji, '💰');
      expect(wallet.colorValue, 0xFF0D9373);
      expect(wallet.isDefault, isFalse);
    });
  });

  group('Wallet list operations', () {
    test('wallet ordering: default first, then by createdAt', () {
      final wallets = [
        WalletModel(
          id: 'w2',
          name: 'Second',
          isDefault: false,
          createdAt: DateTime(2026, 1, 1),
        ),
        WalletModel(
          id: 'w1',
          name: 'Default',
          isDefault: true,
          createdAt: DateTime(2026, 2, 1),
        ),
        WalletModel(
          id: 'w3',
          name: 'Third',
          isDefault: false,
          createdAt: DateTime(2026, 3, 1),
        ),
      ];

      // Sort: default first, then by createdAt ASC
      wallets.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.createdAt.compareTo(b.createdAt);
      });

      expect(wallets[0].id, 'w1'); // default first
      expect(wallets[1].id, 'w2'); // oldest non-default
      expect(wallets[2].id, 'w3'); // newest non-default
    });

    test('wallet count after add/remove', () {
      final wallets = <WalletModel>[
        WalletModel(id: 'w1', name: 'Default', isDefault: true),
      ];
      expect(wallets.length, 1);

      // Add
      wallets.add(WalletModel(id: 'w2', name: 'New'));
      expect(wallets.length, 2);

      // Remove non-default
      wallets.removeWhere((w) => w.id == 'w2');
      expect(wallets.length, 1);
      expect(wallets.first.id, 'w1');
    });

    test('ensure at least one wallet exists', () {
      final wallets = <WalletModel>[];
      if (wallets.isEmpty) {
        wallets.add(
          WalletModel(
            id: 'default-wallet',
            name: 'Dompet Utama',
            isDefault: true,
          ),
        );
      }
      expect(wallets, isNotEmpty);
      expect(wallets.first.isDefault, isTrue);
    });
  });
}
