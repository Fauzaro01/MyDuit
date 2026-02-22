import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:myduit/config/app_theme.dart';
import 'package:myduit/screens/splash_screen.dart';

void main() {
  setUp(() {
    // Disable animations in test to avoid pending timer issues
    Animate.restartOnHotReload = false;
  });

  group('SplashScreen', () {
    testWidgets('displays app logo and name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: SplashScreen(nextScreen: Container()),
        ),
      );

      // Initial render
      await tester.pump();

      expect(find.text('💸'), findsOneWidget);
      expect(find.text('MyDuit'), findsOneWidget);

      // Advance past all timers to avoid pending timer assertion
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('displays subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: SplashScreen(nextScreen: Container()),
        ),
      );
      await tester.pump();

      expect(find.text('Kelola keuanganmu dengan mudah'), findsOneWidget);

      // Advance past all timers
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('navigates to next screen after delay', (tester) async {
      final nextScreen = Container(key: const Key('next-screen'));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: SplashScreen(nextScreen: nextScreen),
        ),
      );
      await tester.pump();

      // Before delay, still on splash
      expect(find.text('MyDuit'), findsOneWidget);

      // Advance time past the delay (2400ms + transition 600ms)
      await tester.pump(const Duration(milliseconds: 3100));
      await tester.pumpAndSettle();

      // Should have navigated to next screen
      expect(find.byKey(const Key('next-screen')), findsOneWidget);
    });
  });
}
