import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myduit/config/app_theme.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/widgets/common_widgets.dart';

/// Helper to wrap a widget with MaterialApp and providers for testing
Widget createTestApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme(),
    darkTheme: AppTheme.darkTheme(),
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    SharedPreferences.setMockInitialValues({});
  });

  group('EmptyState', () {
    testWidgets('displays default message', (tester) async {
      await tester.pumpWidget(createTestApp(const EmptyState()));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada transaksi'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });

    testWidgets('displays custom message', (tester) async {
      await tester.pumpWidget(
        createTestApp(const EmptyState(message: 'Custom empty message')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom empty message'), findsOneWidget);
    });

    testWidgets('displays custom icon', (tester) async {
      await tester.pumpWidget(
        createTestApp(const EmptyState(icon: Icons.search_off)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });
  });

  group('TransactionTile', () {
    late TransactionModel expenseTx;
    late TransactionModel incomeTx;

    setUp(() {
      expenseTx = TransactionModel(
        id: 'tx-expense',
        title: 'Makan Siang',
        amount: 25000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime.now(),
        note: 'Di warteg',
      );

      incomeTx = TransactionModel(
        id: 'tx-income',
        title: 'Gaji Bulanan',
        amount: 5000000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        date: DateTime.now(),
      );
    });

    testWidgets('displays expense transaction title', (tester) async {
      await tester.pumpWidget(
        createTestApp(TransactionTile(transaction: expenseTx)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Makan Siang'), findsOneWidget);
    });

    testWidgets('displays income transaction title', (tester) async {
      await tester.pumpWidget(
        createTestApp(TransactionTile(transaction: incomeTx)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gaji Bulanan'), findsOneWidget);
    });

    testWidgets('shows category label in subtitle', (tester) async {
      await tester.pumpWidget(
        createTestApp(TransactionTile(transaction: expenseTx)),
      );
      await tester.pumpAndSettle();

      // The subtitle contains "Makanan · ..."
      expect(find.textContaining('Makanan'), findsOneWidget);
    });

    testWidgets('shows category emoji icon', (tester) async {
      await tester.pumpWidget(
        createTestApp(TransactionTile(transaction: expenseTx)),
      );
      await tester.pumpAndSettle();

      expect(find.text('🍔'), findsOneWidget);
    });

    testWidgets('displays formatted amount with sign', (tester) async {
      await tester.pumpWidget(
        createTestApp(TransactionTile(transaction: expenseTx)),
      );
      await tester.pumpAndSettle();

      // Should find the amount text with minus sign
      expect(find.textContaining('-'), findsOneWidget);
      expect(find.textContaining('Rp'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        createTestApp(
          TransactionTile(transaction: expenseTx, onTap: () => tapped = true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Makan Siang'));
      expect(tapped, isTrue);
    });

    testWidgets('shows dismiss background on swipe', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          TransactionTile(transaction: expenseTx, onDismissed: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Start swiping left
      await tester.drag(find.text('Makan Siang'), const Offset(-100, 0));
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });
  });
}
