import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myduit/providers/app_lock_provider.dart';

void main() {
  group('AppLockProvider PIN hashing', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('setPin stores a hash, not the plaintext PIN', () async {
      final provider = AppLockProvider();
      await provider.setPin('5678');

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('app_lock_pin');

      expect(stored, isNot('5678'));
      expect(stored, hasLength(64)); // sha256 hex digest
      expect(provider.verifyPin('5678'), isTrue);
      expect(provider.verifyPin('0000'), isFalse);
    });

    test('legacy plaintext PIN is migrated to a hash on init()', () async {
      SharedPreferences.setMockInitialValues({'app_lock_pin': '1234'});

      final provider = AppLockProvider();
      await provider.init();

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('app_lock_pin');

      expect(stored, isNot('1234'));
      expect(stored, hasLength(64));
      expect(provider.verifyPin('1234'), isTrue);
    });
  });
}
