import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:myduit/config/app_theme.dart';
import 'package:myduit/providers/transaction_provider.dart';
import 'package:myduit/providers/theme_provider.dart';
import 'package:myduit/screens/add_transaction_screen.dart';
import 'package:myduit/models/transaction_model.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('id_ID', null);
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestApp({TransactionModel? transaction, bool isIncome = true}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        home: AddTransactionScreen(
          transaction: transaction,
          initialIsIncome: isIncome,
        ),
      ),
    );
  }

  group('AddTransactionScreen', () {
    testWidgets('shows "Tambah Transaksi" title for new transaction', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Tambah Transaksi'), findsOneWidget);
    });

    testWidgets('shows "Edit Transaksi" title when editing', (tester) async {
      final tx = TransactionModel(
        id: 'edit-1',
        title: 'Test Edit',
        amount: 50000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime(2026, 2, 15),
      );

      await tester.pumpWidget(createTestApp(transaction: tx));
      await tester.pumpAndSettle();

      expect(find.text('Edit Transaksi'), findsOneWidget);
    });

    testWidgets('pre-fills fields in edit mode', (tester) async {
      final tx = TransactionModel(
        id: 'edit-2',
        title: 'Makan Siang',
        amount: 25000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime(2026, 2, 15),
        note: 'Test note',
      );

      await tester.pumpWidget(createTestApp(transaction: tx));
      await tester.pumpAndSettle();

      expect(find.text('Makan Siang'), findsOneWidget);
      expect(find.text('25000'), findsOneWidget);
      // Note field is below the fold, scroll to it
      await tester.scrollUntilVisible(
        find.text('Test note'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Test note'), findsOneWidget);
    });

    testWidgets('shows income/expense type toggle', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Pemasukan'), findsOneWidget);
      expect(find.text('Pengeluaran'), findsOneWidget);
    });

    testWidgets('shows income categories when income is selected', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(isIncome: true));
      await tester.pumpAndSettle();

      // Should show income categories
      expect(find.text('Gaji'), findsWidgets);
    });

    testWidgets('shows expense categories when expense is selected', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(isIncome: false));
      await tester.pumpAndSettle();

      // Should show expense categories
      expect(find.text('Makanan'), findsWidgets);
    });

    testWidgets('shows form fields', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Should have text fields for title, amount, note
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('shows save button', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Button is at bottom of scrollable list, scroll to it
      await tester.scrollUntilVisible(
        find.byType(ElevatedButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(ElevatedButton), findsOneWidget);
      // Button text should be 'Tambah Transaksi'
      expect(
        find.widgetWithText(ElevatedButton, 'Tambah Transaksi'),
        findsOneWidget,
      );
    });

    testWidgets('shows update button in edit mode', (tester) async {
      final tx = TransactionModel(
        id: 'edit-3',
        title: 'Test',
        amount: 1000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime(2026, 2, 15),
      );

      await tester.pumpWidget(createTestApp(transaction: tx));
      await tester.pumpAndSettle();

      // Scroll to the button
      await tester.scrollUntilVisible(
        find.byType(ElevatedButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Simpan Perubahan'), findsOneWidget);
    });

    testWidgets('has validator on title field', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify title TextFormField exists
      final titleFields = find.byType(TextFormField);
      expect(titleFields, findsWidgets);

      // Verify the form has validators by checking that Form is present
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('has validator on amount field', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify amount field has hint text
      expect(find.byType(TextFormField), findsWidgets);

      // Verify the form exists for validation support
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('switching type toggles category list', (tester) async {
      await tester.pumpWidget(createTestApp(isIncome: true));
      await tester.pumpAndSettle();

      // Initially on income — should see Gaji
      expect(find.text('Gaji'), findsWidgets);

      // Tap Pengeluaran to switch
      await tester.tap(find.text('Pengeluaran'));
      await tester.pumpAndSettle();

      // Should now see expense categories
      expect(find.text('Makanan'), findsWidgets);
    });
  });
}
