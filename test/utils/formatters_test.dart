import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myduit/utils/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('CurrencyFormatter', () {
    group('format', () {
      test('formats zero', () {
        final result = CurrencyFormatter.format(0);
        expect(result, contains('Rp'));
        expect(result, contains('0'));
      });

      test('formats thousands with separator', () {
        final result = CurrencyFormatter.format(50000);
        expect(result, contains('Rp'));
        expect(result, contains('50'));
      });

      test('formats millions', () {
        final result = CurrencyFormatter.format(5000000);
        expect(result, contains('Rp'));
        expect(result, contains('5'));
      });

      test('formats without decimals (no comma decimal)', () {
        final result = CurrencyFormatter.format(1234.56);
        // decimalDigits: 0, so no decimal comma/point after amount
        // In id_ID locale, "." is thousand separator, "," is decimal
        // With 0 decimal digits, there should be no comma
        expect(result, isNot(contains(',')));
      });

      test('formats negative amounts', () {
        final result = CurrencyFormatter.format(-50000);
        expect(result, contains('Rp'));
      });
    });

    group('formatCompact', () {
      test('formats billions with M suffix', () {
        final result = CurrencyFormatter.formatCompact(1500000000);
        expect(result, 'Rp 1.5M');
      });

      test('formats millions with Jt suffix', () {
        final result = CurrencyFormatter.formatCompact(2500000);
        expect(result, 'Rp 2.5Jt');
      });

      test('formats thousands with Rb suffix', () {
        final result = CurrencyFormatter.formatCompact(7500);
        expect(result, 'Rp 7.5Rb');
      });

      test('formats below 1000 with full format', () {
        final result = CurrencyFormatter.formatCompact(500);
        expect(result, contains('Rp'));
        expect(result, contains('500'));
      });

      test('formats exactly 1 million', () {
        final result = CurrencyFormatter.formatCompact(1000000);
        expect(result, 'Rp 1.0Jt');
      });

      test('formats exactly 1 billion', () {
        final result = CurrencyFormatter.formatCompact(1000000000);
        expect(result, 'Rp 1.0M');
      });

      test('formats exactly 1 thousand', () {
        final result = CurrencyFormatter.formatCompact(1000);
        expect(result, 'Rp 1.0Rb');
      });
    });
  });

  group('DateFormatter', () {
    group('monthYear', () {
      test('formats February 2026 in Indonesian', () {
        final result = DateFormatter.monthYear(2026, 2);
        expect(result.toLowerCase(), contains('februari'));
        expect(result, contains('2026'));
      });

      test('formats January 2026', () {
        final result = DateFormatter.monthYear(2026, 1);
        expect(result.toLowerCase(), contains('januari'));
      });

      test('formats December 2025', () {
        final result = DateFormatter.monthYear(2025, 12);
        expect(result.toLowerCase(), contains('desember'));
        expect(result, contains('2025'));
      });
    });

    group('fullDate', () {
      test('formats full date in Indonesian', () {
        final date = DateTime(2026, 2, 15);
        final result = DateFormatter.fullDate(date);
        expect(result, contains('15'));
        expect(result.toLowerCase(), contains('februari'));
        expect(result, contains('2026'));
      });

      test('formats first day of month', () {
        final date = DateTime(2026, 1, 1);
        final result = DateFormatter.fullDate(date);
        expect(result, contains('01'));
      });
    });

    group('shortDate', () {
      test('formats short date', () {
        final date = DateTime(2026, 2, 15);
        final result = DateFormatter.shortDate(date);
        expect(result, contains('15'));
        // Short month name in id_ID
        expect(result.toLowerCase(), contains('feb'));
      });
    });

    group('dayMonth', () {
      test('formats as dd/MM', () {
        final date = DateTime(2026, 2, 5);
        final result = DateFormatter.dayMonth(date);
        expect(result, '05/02');
      });

      test('formats double-digit day and month', () {
        final date = DateTime(2026, 12, 25);
        final result = DateFormatter.dayMonth(date);
        expect(result, '25/12');
      });
    });

    group('relative', () {
      test('returns "Hari ini" for today', () {
        final today = DateTime.now();
        final result = DateFormatter.relative(today);
        expect(result, 'Hari ini');
      });

      test('returns "Kemarin" for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final result = DateFormatter.relative(yesterday);
        expect(result, 'Kemarin');
      });

      test('returns "X hari lalu" for 2-6 days ago', () {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        final result = DateFormatter.relative(threeDaysAgo);
        expect(result, '3 hari lalu');
      });

      test('returns "6 hari lalu" for 6 days ago', () {
        final sixDaysAgo = DateTime.now().subtract(const Duration(days: 6));
        final result = DateFormatter.relative(sixDaysAgo);
        expect(result, '6 hari lalu');
      });

      test('returns formatted date for 7+ days ago', () {
        final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
        final result = DateFormatter.relative(twoWeeksAgo);
        // Should not be "X hari lalu"
        expect(result, isNot(contains('hari lalu')));
        expect(result, isNot('Hari ini'));
        expect(result, isNot('Kemarin'));
      });
    });

    group('time', () {
      test('formats time as HH:mm', () {
        final date = DateTime(2026, 2, 15, 14, 30);
        final result = DateFormatter.time(date);
        expect(result, '14:30');
      });

      test('formats midnight', () {
        final date = DateTime(2026, 2, 15, 0, 0);
        final result = DateFormatter.time(date);
        expect(result, '00:00');
      });

      test('formats with leading zeros', () {
        final date = DateTime(2026, 2, 15, 9, 5);
        final result = DateFormatter.time(date);
        expect(result, '09:05');
      });
    });
  });
}
