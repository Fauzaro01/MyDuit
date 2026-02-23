import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/main_navigation.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Global Flutter error handler
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        if (kReleaseMode) {
          debugPrint('FlutterError: ${details.exceptionAsString()}');
        }
      };

      bool onboardingComplete = false;
      late WalletProvider walletProvider;
      late TransactionProvider transactionProvider;

      try {
        await initializeDateFormatting('id_ID', null);
      } catch (_) {
        // Non-fatal: date formatting will fall back to defaults
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      } catch (_) {
        // Non-fatal: default to showing onboarding
      }

      try {
        walletProvider = WalletProvider();
        transactionProvider = TransactionProvider();
        transactionProvider.setWalletProvider(walletProvider);
      } catch (e) {
        debugPrint('Provider init error: $e');
        walletProvider = WalletProvider();
        transactionProvider = TransactionProvider();
      }

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider.value(value: walletProvider),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: MyDuitApp(showOnboarding: !onboardingComplete),
        ),
      );
    },
    (error, stackTrace) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stackTrace');
    },
  );
}

class MyDuitApp extends StatelessWidget {
  final bool showOnboarding;

  const MyDuitApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'MyDuit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeProvider.themeMode,
      home: SplashScreen(
        nextScreen: showOnboarding
            ? const OnboardingScreen()
            : const MainNavigation(),
      ),
    );
  }
}
