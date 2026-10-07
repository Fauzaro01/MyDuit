import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myduit/providers/app_lock_provider.dart';

void main() {
  group('AppLockProvider.deriveBackupKey', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns null when no PIN is set', () {
      final provider = AppLockProvider();
      expect(provider.deriveBackupKey(), isNull);
    });

    test('returns a stable 64-char hex key for the same PIN', () async {
      final provider = AppLockProvider();
      await provider.setPin('1234');

      final key1 = provider.deriveBackupKey();
      final key2 = provider.deriveBackupKey();

      expect(key1, isNotNull);
      expect(key1, hasLength(64));
      expect(key1, key2);
    });

    test('different PINs derive different keys', () async {
      final providerA = AppLockProvider();
      await providerA.setPin('1234');

      final providerB = AppLockProvider();
      await providerB.setPin('5678');

      expect(providerA.deriveBackupKey(), isNot(providerB.deriveBackupKey()));
    });
  });
}
