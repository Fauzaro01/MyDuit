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

  Widget createTestApp({required TemplateProvider templateProvider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TemplateProvider>.value(value: templateProvider),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => CustomCategoryProvider()),
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
      await tester.pumpWidget(createTestApp(templateProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Atur Catat Cepat'), findsOneWidget);
      expect(find.text('Tambah Pintasan'), findsOneWidget);
    });

    testWidgets('shows templates when available', (tester) async {
      final provider = TemplateProvider();
      // Add a test template
      final tpl = TransactionTemplateModel(
        id: 'test-kopi',
        name: 'Kopi Susu',
        title: 'Beli Kopi Susu',
        amount: 18000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        emoji: '☕',
      );
      await provider.addTemplate(tpl);

      await tester.pumpWidget(createTestApp(templateProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Kopi Susu'), findsOneWidget);
      expect(find.text('Beli Kopi Susu'), findsOneWidget);
    });
  });
}
