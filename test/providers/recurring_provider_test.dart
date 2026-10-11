import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:myduit/models/recurring_transaction_model.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/providers/recurring_provider.dart';
import 'package:myduit/providers/wallet_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('RecurringProvider Tests', () {
    test(
      'load, add, toggle active, and delete recurring transactions',
      () async {
        final provider = RecurringProvider();
        await provider.loadRecurringTransactions();

        // Clean existing
        for (final r in List.of(provider.recurringTransactions)) {
          await provider.deleteRecurringTransaction(r.id);
        }
        expect(provider.recurringTransactions, isEmpty);

        // recurring_transactions.walletId has a FOREIGN KEY on wallets(id) —
        // a real wallet must exist first, or the insert fails.
        final walletProvider = WalletProvider();
        await walletProvider.loadWallets();
        final walletId = walletProvider.wallets.first.id;

        final rec = RecurringTransactionModel(
          title: 'Netflix',
          amount: 186000,
          type: TransactionType.expense,
          category: TransactionCategory.entertainment,
          walletId: walletId,
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 1, 1),
          isActive: true,
        );

        await provider.addRecurringTransaction(rec);
        expect(provider.recurringTransactions.length, 1);
        expect(provider.activeRecurrings.length, 1);
        expect(provider.inactiveRecurrings, isEmpty);

        // Toggle active to inactive
        await provider.toggleActive(provider.recurringTransactions.first);
        expect(provider.activeRecurrings, isEmpty);
        expect(provider.inactiveRecurrings.length, 1);

        // Delete
        await provider.deleteRecurringTransaction(rec.id);
        expect(provider.recurringTransactions, isEmpty);
      },
    );
  });
}
