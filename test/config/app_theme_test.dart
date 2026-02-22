import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myduit/config/app_theme.dart';

/// A mock HTTP client that returns an empty response for any request.
/// This prevents GoogleFonts from making real HTTP requests in tests.
class _FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return futures that resolve with empty responses for open/get calls
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
    // Immediately complete with empty data
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
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Use fake HTTP overrides so GoogleFonts doesn't make real network calls
    HttpOverrides.global = _FakeHttpOverrides();
    // Allow runtime fetching so it doesn't throw synchronous exceptions,
    // but the fake HTTP client will return empty responses
    GoogleFonts.config.allowRuntimeFetching = true;
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  group('AppColors', () {
    test('primary colors are defined', () {
      expect(AppColors.primaryLight, isA<Color>());
      expect(AppColors.primaryDark, isA<Color>());
      expect(AppColors.primaryLight, isNot(equals(AppColors.primaryDark)));
    });

    test('surface colors are defined', () {
      expect(AppColors.surfaceLight, isA<Color>());
      expect(AppColors.surfaceDark, isA<Color>());
    });

    test('card colors are defined', () {
      expect(AppColors.cardLight, isA<Color>());
      expect(AppColors.cardDark, isA<Color>());
      expect(AppColors.cardAltLight, isA<Color>());
      expect(AppColors.cardAltDark, isA<Color>());
    });

    test('text colors are defined', () {
      expect(AppColors.textPrimaryLight, isA<Color>());
      expect(AppColors.textPrimaryDark, isA<Color>());
      expect(AppColors.textSecondaryLight, isA<Color>());
      expect(AppColors.textSecondaryDark, isA<Color>());
    });

    test('semantic colors are defined', () {
      expect(AppColors.income, isA<Color>());
      expect(AppColors.expense, isA<Color>());
      expect(AppColors.incomeSoft, isA<Color>());
      expect(AppColors.expenseSoft, isA<Color>());
    });

    test('income and expense are different', () {
      expect(AppColors.income, isNot(equals(AppColors.expense)));
    });

    test('nav bar colors are defined', () {
      expect(AppColors.navBarLight, isA<Color>());
      expect(AppColors.navBarDark, isA<Color>());
    });
  });

  group('AppTheme', () {
    group('lightTheme', () {
      testWidgets('uses material 3', (tester) async {
        final theme = AppTheme.lightTheme();
        expect(theme.useMaterial3, isTrue);
      });

      testWidgets('has correct scaffold color', (tester) async {
        final theme = AppTheme.lightTheme();
        expect(theme.scaffoldBackgroundColor, AppColors.surfaceLight);
      });

      testWidgets('has light brightness color scheme', (tester) async {
        final theme = AppTheme.lightTheme();
        expect(theme.colorScheme.brightness, Brightness.light);
      });

      testWidgets('primary color is set', (tester) async {
        final theme = AppTheme.lightTheme();
        expect(theme.colorScheme.primary, AppColors.primaryLight);
      });

      testWidgets('error color is expense red', (tester) async {
        final theme = AppTheme.lightTheme();
        expect(theme.colorScheme.error, AppColors.expense);
      });

      testWidgets('card theme has no elevation', (tester) async {
        final theme = AppTheme.lightTheme();
        expect(theme.cardTheme.elevation, 0);
      });

      testWidgets('card theme has rounded corners', (tester) async {
        final theme = AppTheme.lightTheme();
        final shape = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(20));
      });

      testWidgets('app bar has no elevation', (tester) async {
        final theme = AppTheme.lightTheme();
        expect(theme.appBarTheme.elevation, 0);
      });

      testWidgets('text theme is defined', (tester) async {
        final theme = AppTheme.lightTheme();
        expect(theme.textTheme.headlineLarge, isNotNull);
        expect(theme.textTheme.headlineMedium, isNotNull);
        expect(theme.textTheme.titleLarge, isNotNull);
        expect(theme.textTheme.titleMedium, isNotNull);
        expect(theme.textTheme.bodyLarge, isNotNull);
        expect(theme.textTheme.bodyMedium, isNotNull);
        expect(theme.textTheme.labelLarge, isNotNull);
      });

      testWidgets('FAB has rounded corners', (tester) async {
        final theme = AppTheme.lightTheme();
        final shape =
            theme.floatingActionButtonTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(18));
      });
    });

    group('darkTheme', () {
      testWidgets('uses material 3', (tester) async {
        final theme = AppTheme.darkTheme();
        expect(theme.useMaterial3, isTrue);
      });

      testWidgets('has correct scaffold color', (tester) async {
        final theme = AppTheme.darkTheme();
        expect(theme.scaffoldBackgroundColor, AppColors.surfaceDark);
      });

      testWidgets('has dark brightness color scheme', (tester) async {
        final theme = AppTheme.darkTheme();
        expect(theme.colorScheme.brightness, Brightness.dark);
      });

      testWidgets('primary color is set', (tester) async {
        final theme = AppTheme.darkTheme();
        expect(theme.colorScheme.primary, AppColors.primaryDark);
      });

      testWidgets('text theme is defined', (tester) async {
        final theme = AppTheme.darkTheme();
        expect(theme.textTheme.headlineLarge, isNotNull);
        expect(theme.textTheme.headlineMedium, isNotNull);
      });

      testWidgets('card theme has dark background', (tester) async {
        final theme = AppTheme.darkTheme();
        expect(theme.cardTheme.color, AppColors.cardDark);
      });
    });

    group('theme consistency', () {
      testWidgets('light and dark themes have same structure', (tester) async {
        final light = AppTheme.lightTheme();
        final dark = AppTheme.darkTheme();

        // Both should have card theme
        expect(light.cardTheme, isNotNull);
        expect(dark.cardTheme, isNotNull);

        // Both should have app bar theme
        expect(light.appBarTheme, isNotNull);
        expect(dark.appBarTheme, isNotNull);

        // Both should have FAB theme
        expect(light.floatingActionButtonTheme, isNotNull);
        expect(dark.floatingActionButtonTheme, isNotNull);
      });

      testWidgets('different scaffold colors for light and dark', (
        tester,
      ) async {
        final light = AppTheme.lightTheme();
        final dark = AppTheme.darkTheme();
        expect(
          light.scaffoldBackgroundColor,
          isNot(dark.scaffoldBackgroundColor),
        );
      });
    });
  });
}
