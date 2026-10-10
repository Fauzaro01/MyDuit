import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:myduit/config/app_theme.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/models/transaction_template_model.dart';
import 'package:myduit/providers/custom_category_provider.dart';
import 'package:myduit/providers/template_provider.dart';
import 'package:myduit/providers/wallet_provider.dart';
import 'package:myduit/screens/quick_templates_screen.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('id_ID', null);
    SharedPreferences.setMockInitialValues({});
  });

  // WalletProvider()/CustomCategoryProvider()'s normal constructors fire a
  // real, unawaited DB load. That load never resolves inside testWidgets'
  // fake-async zone unless routed through runAsync, and if it outlives the
  // test, its late notifyListeners() fires after dispose — flaky under any
  // fixed delay once another test file contends for the same sqlite file.
  // `.forTesting()` skips the auto-load so the test can await it once,
  // deterministically, via runAsync before the first pump.
  Widget createTestApp({
    required TemplateProvider templateProvider,
    required WalletProvider walletProvider,
    required CustomCategoryProvider customCategoryProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TemplateProvider>.value(value: templateProvider),
        ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
        ChangeNotifierProvider<CustomCategoryProvider>.value(value: customCategoryProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        home: const QuickTemplatesScreen(),
      ),
    );
  }

  group('QuickTemplatesScreen', () {
    testWidgets('shows appbar title and add FAB', (tester) async {
      final provider = TemplateProvider();
      final walletProvider = WalletProvider.forTesting();
      final customCategoryProvider = CustomCategoryProvider.forTesting();
      await tester.runAsync(() async {
        await walletProvider.loadWallets();
        await customCategoryProvider.loadCategories();
      });

      await tester.pumpWidget(createTestApp(
        templateProvider: provider,
        walletProvider: walletProvider,
        customCategoryProvider: customCategoryProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Atur Catat Cepat'), findsOneWidget);
      expect(find.text('Tambah Pintasan'), findsOneWidget);
    });

    testWidgets('shows templates when available', (tester) async {
      final provider = TemplateProvider();
      final walletProvider = WalletProvider.forTesting();
      final customCategoryProvider = CustomCategoryProvider.forTesting();
      final tpl = TransactionTemplateModel(
        id: 'test-kopi',
        name: 'Kopi Susu',
        title: 'Beli Kopi Susu',
        amount: 18000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        emoji: '☕',
      );

      await tester.runAsync(() async {
        await provider.addTemplate(tpl);
        await walletProvider.loadWallets();
        await customCategoryProvider.loadCategories();
      });

      await tester.pumpWidget(createTestApp(
        templateProvider: provider,
        walletProvider: walletProvider,
        customCategoryProvider: customCategoryProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Kopi Susu'), findsOneWidget);
      expect(find.text('Beli Kopi Susu'), findsOneWidget);
    });
  });
}
