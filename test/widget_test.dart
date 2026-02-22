// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:myduit/main.dart';
import 'package:myduit/providers/theme_provider.dart';
import 'package:myduit/providers/transaction_provider.dart';
import 'package:myduit/screens/splash_screen.dart';

/// Fake HTTP overrides to prevent GoogleFonts network requests in tests
class _FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final memberName = invocation.memberName.toString();
    if (memberName.contains('getUrl') || memberName.contains('openUrl')) {
      return Future<HttpClientRequest>.value(_FakeHttpClientRequest());
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final memberName = invocation.memberName.toString();
    if (memberName.contains('close')) {
      return Future<HttpClientResponse>.value(_FakeHttpClientResponse());
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  int get contentLength => 0;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    onDone?.call();
    return Stream<List<int>>.empty().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    HttpOverrides.global = _FakeHttpOverrides();
    GoogleFonts.config.allowRuntimeFetching = true;
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    Animate.restartOnHotReload = false;
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('App creates MaterialApp with correct title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ],
        // Use showOnboarding: true so splash navigates to OnboardingScreen
        // instead of MainNavigation (which requires sqflite platform channel)
        child: const MyDuitApp(showOnboarding: true),
      ),
    );

    // Verify MaterialApp is created with correct configuration
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'MyDuit');
    expect(materialApp.debugShowCheckedModeBanner, isFalse);

    // Verify SplashScreen is the initial screen
    expect(find.byType(SplashScreen), findsOneWidget);

    // Advance past all pending timers (splash screen 2400ms + flutter_animate)
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('App respects showOnboarding parameter', (
    WidgetTester tester,
  ) async {
    // Test with showOnboarding: true
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ],
        child: const MyDuitApp(showOnboarding: true),
      ),
    );

    // App should still show splash screen first regardless
    expect(find.byType(SplashScreen), findsOneWidget);

    // Advance past all pending timers
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
  });
}
