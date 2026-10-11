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

  group('AppLockProvider PIN hashing', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('setPin never persists the PIN in plaintext', () async {
      final provider = AppLockProvider();
      await provider.setPin('1234');

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('app_lock_pin');

      expect(stored, isNotNull);
      expect(stored, isNot('1234'));
      expect(stored, hasLength(64)); // SHA-256 hex digest
      expect(provider.verifyPin('1234'), isTrue);
    });

    test('migrates a legacy plaintext PIN to a hash on init()', () async {
      // Simulate a PIN stored in plaintext by an older app version.
      SharedPreferences.setMockInitialValues({
        'app_lock_pin': '4321',
        'app_lock_enabled': true,
      });

      final provider = AppLockProvider();
      await provider.init();

      // Still verifies correctly against the original plaintext PIN...
      expect(provider.verifyPin('4321'), isTrue);

      // ...but is no longer stored in plaintext afterwards.
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('app_lock_pin');
      expect(stored, isNot('4321'));
      expect(stored, hasLength(64));
    });
  });

  group('AppLockProvider Lockout & Security Questions', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('progressive failed attempts trigger lockout', () async {
      final provider = AppLockProvider();
      await provider.setPin('1234');
      expect(provider.isLockedOut, isFalse);

      // 4 fails - not locked out yet
      for (int i = 0; i < 4; i++) {
        expect(provider.verifyPin('0000'), isFalse);
        expect(provider.isLockedOut, isFalse);
      }

      // 5th fail - triggers 30s lockout
      expect(provider.verifyPin('0000'), isFalse);
      expect(provider.isLockedOut, isTrue);
      expect(provider.remainingLockoutSeconds, greaterThan(0));

      // Cannot verify even with correct pin while locked out
      expect(provider.verifyPin('1234'), isFalse);

      // Reset lockout
      provider.resetLockout();
      expect(provider.isLockedOut, isFalse);
      expect(provider.verifyPin('1234'), isTrue);
    });

    test('security question setup, verification and pin reset', () async {
      final provider = AppLockProvider();
      await provider.setPin('1111');
      await provider.setSecurityQuestion(
        question: 'Nama hewan peliharaan pertama?',
        answer: 'Mimi',
      );

      expect(provider.hasSecurityQuestion, isTrue);
      expect(provider.securityQuestion, 'Nama hewan peliharaan pertama?');

      // Case insensitive answer verification
      expect(provider.verifySecurityAnswer('mimi'), isTrue);
      expect(provider.verifySecurityAnswer('MIMI '), isTrue);
      expect(provider.verifySecurityAnswer('wrong'), isFalse);

      // Lockout occurs after 5 failed attempts
      for (int i = 0; i < 5; i++) {
        provider.verifyPin('9999');
      }
      expect(provider.isLockedOut, isTrue);

      // Reset PIN using security answer
      final success = await provider.resetPinWithSecurityAnswer(
        answer: 'mimi',
        newPin: '5678',
      );
      expect(success, isTrue);
      expect(provider.isLockedOut, isFalse);
      expect(provider.verifyPin('5678'), isTrue);
    });
  });
}
