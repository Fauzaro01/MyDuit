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
import 'providers/recurring_provider.dart';
import 'providers/savings_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/app_lock_provider.dart';
import 'providers/custom_category_provider.dart';
import 'services/notification_service.dart';
import 'services/google_drive_service.dart';
import 'screens/main_navigation.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pin_lock_screen.dart';

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
      late RecurringProvider recurringProvider;
      late SavingsProvider savingsProvider;
      late DebtProvider debtProvider;
      late AppLockProvider appLockProvider;
      late CustomCategoryProvider customCategoryProvider;

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
        recurringProvider = RecurringProvider();
        recurringProvider.setProviders(transactionProvider, walletProvider);
        savingsProvider = SavingsProvider();
        debtProvider = DebtProvider();
        appLockProvider = AppLockProvider();
        await appLockProvider.init();
        customCategoryProvider = CustomCategoryProvider();

        // Initialize notifications
        try {
          await NotificationService.init();
          await NotificationService.rescheduleIfEnabled();
        } catch (_) {
          // Non-fatal: notifications are optional
        }

        // Initialize Google Sign-In
        try {
          await GoogleDriveService.init();
          // Run scheduled auto-backup if due
          GoogleDriveService.runScheduledBackupIfNeeded();
        } catch (_) {
          // Non-fatal: Google Drive backup is optional
        }
      } catch (e) {
        debugPrint('Provider init error: $e');
        walletProvider = WalletProvider();
        transactionProvider = TransactionProvider();
        recurringProvider = RecurringProvider();
        savingsProvider = SavingsProvider();
        debtProvider = DebtProvider();
        appLockProvider = AppLockProvider();
        customCategoryProvider = CustomCategoryProvider();
      }

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider.value(value: walletProvider),
            ChangeNotifierProvider.value(value: transactionProvider),
            ChangeNotifierProvider.value(value: recurringProvider),
            ChangeNotifierProvider.value(value: savingsProvider),
            ChangeNotifierProvider.value(value: debtProvider),
            ChangeNotifierProvider.value(value: appLockProvider),
            ChangeNotifierProvider.value(value: customCategoryProvider),
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
            : const _AppEntryGate(),
      ),
    );
  }
}

/// Gate that checks PIN lock and generates recurring transactions
class _AppEntryGate extends StatefulWidget {
  const _AppEntryGate();

  @override
  State<_AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<_AppEntryGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final lockProvider = context.read<AppLockProvider>();
    final recurringProvider = context.read<RecurringProvider>();

    // Check PIN lock
    if (lockProvider.needsUnlock) {
      if (mounted) {
        final unlocked = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const PinLockScreen()),
        );
        if (unlocked != true) {
          // User didn't unlock, exit the app — or just keep showing the lock
          if (mounted) {
            _initialize(); // Retry
            return;
          }
        }
      }
    }

    // Generate pending recurring transactions
    try {
      await recurringProvider.loadRecurringTransactions();
      final count = await recurringProvider.generatePendingTransactions();
      if (count > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count transaksi otomatis telah ditambahkan'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Recurring generation error: $e');
    }

    if (mounted) {
      setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const MainNavigation();
  }
}
