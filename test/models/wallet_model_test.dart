import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/wallet_model.dart';

void main() {
  group('WalletModel', () {
    late WalletModel wallet;
    final testDate = DateTime(2026, 3, 1);

    setUp(() {
      wallet = WalletModel(
        id: 'wallet-1',
        name: 'Dompet Utama',
        emoji: '💰',
        colorValue: 0xFF0D9373,
        isDefault: true,
        createdAt: testDate,
      );
    });

    test('creates instance with provided values', () {
      expect(wallet.id, 'wallet-1');
      expect(wallet.name, 'Dompet Utama');
      expect(wallet.emoji, '💰');
      expect(wallet.colorValue, 0xFF0D9373);
      expect(wallet.isDefault, isTrue);
      expect(wallet.createdAt, testDate);
    });

    test('generates UUID if id not provided', () {
      final w = WalletModel(name: 'Test Wallet');
      expect(w.id, isNotEmpty);
      expect(w.id.length, greaterThan(10));
    });

    test('has correct default values', () {
      final w = WalletModel(name: 'Simple');
      expect(w.emoji, '💰');
      expect(w.colorValue, 0xFF0D9373);
      expect(w.isDefault, isFalse);
      expect(w.createdAt, isNotNull);
    });

    group('toMap', () {
      test('converts to map correctly', () {
        final map = wallet.toMap();
        expect(map['id'], 'wallet-1');
        expect(map['name'], 'Dompet Utama');
        expect(map['emoji'], '💰');
        expect(map['colorValue'], 0xFF0D9373);
        expect(map['isDefault'], 1);
        expect(map['createdAt'], testDate.millisecondsSinceEpoch);
      });

      test('stores isDefault false as 0', () {
        final w = WalletModel(
          id: 'w2',
          name: 'Secondary',
          isDefault: false,
          createdAt: testDate,
        );
        expect(w.toMap()['isDefault'], 0);
      });
    });

    group('fromMap', () {
      test('creates instance from map correctly', () {
        final map = {
          'id': 'map-wallet',
          'name': 'From Map',
          'emoji': '💳',
          'colorValue': 0xFF3B82F6,
          'isDefault': 1,
          'createdAt': testDate.millisecondsSinceEpoch,
        };
        final w = WalletModel.fromMap(map);
        expect(w.id, 'map-wallet');
        expect(w.name, 'From Map');
        expect(w.emoji, '💳');
        expect(w.colorValue, 0xFF3B82F6);
        expect(w.isDefault, isTrue);
        expect(w.createdAt, testDate);
      });

      test('handles null emoji with default', () {
        final map = {
          'id': 'w',
          'name': 'Test',
          'emoji': null,
          'colorValue': 0xFF0D9373,
          'isDefault': 0,
          'createdAt': testDate.millisecondsSinceEpoch,
        };
        final w = WalletModel.fromMap(map);
        expect(w.emoji, '💰');
      });

      test('handles null colorValue with default', () {
        final map = {
          'id': 'w',
          'name': 'Test',
          'emoji': '💰',
          'colorValue': null,
          'isDefault': 0,
          'createdAt': testDate.millisecondsSinceEpoch,
        };
        final w = WalletModel.fromMap(map);
        expect(w.colorValue, 0xFF0D9373);
      });

      test('handles null isDefault as false', () {
        final map = {
          'id': 'w',
          'name': 'Test',
          'emoji': '💰',
          'colorValue': 0xFF0D9373,
          'isDefault': null,
          'createdAt': testDate.millisecondsSinceEpoch,
        };
        final w = WalletModel.fromMap(map);
        expect(w.isDefault, isFalse);
      });

      test('handles null createdAt with current time', () {
        final map = {
          'id': 'w',
          'name': 'Test',
          'emoji': '💰',
          'colorValue': 0xFF0D9373,
          'isDefault': 0,
          'createdAt': null,
        };
        final w = WalletModel.fromMap(map);
        expect(w.createdAt, isNotNull);
        // Should be close to now
        expect(
          w.createdAt.difference(DateTime.now()).inSeconds.abs(),
          lessThan(5),
        );
      });
    });

    group('toMap/fromMap round-trip', () {
      test('preserves all data through serialization', () {
        final map = wallet.toMap();
        final restored = WalletModel.fromMap(map);
        expect(restored.id, wallet.id);
        expect(restored.name, wallet.name);
        expect(restored.emoji, wallet.emoji);
        expect(restored.colorValue, wallet.colorValue);
        expect(restored.isDefault, wallet.isDefault);
        expect(restored.createdAt, wallet.createdAt);
      });

      test('round-trip with isDefault false', () {
        final w = WalletModel(
          id: 'rt-1',
          name: 'Round Trip',
          isDefault: false,
          createdAt: testDate,
        );
        final restored = WalletModel.fromMap(w.toMap());
        expect(restored.isDefault, isFalse);
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        final copy = wallet.copyWith();
        expect(copy.id, wallet.id);
        expect(copy.name, wallet.name);
        expect(copy.emoji, wallet.emoji);
        expect(copy.colorValue, wallet.colorValue);
        expect(copy.isDefault, wallet.isDefault);
        expect(copy.createdAt, wallet.createdAt);
      });

      test('copies with changed name', () {
        final copy = wallet.copyWith(name: 'Dompet Baru');
        expect(copy.name, 'Dompet Baru');
        expect(copy.id, wallet.id);
      });

      test('copies with changed emoji', () {
        final copy = wallet.copyWith(emoji: '💳');
        expect(copy.emoji, '💳');
      });

      test('copies with changed colorValue', () {
        final copy = wallet.copyWith(colorValue: 0xFF3B82F6);
        expect(copy.colorValue, 0xFF3B82F6);
      });

      test('copies with changed isDefault', () {
        final copy = wallet.copyWith(isDefault: false);
        expect(copy.isDefault, isFalse);
      });

      test('copies with changed createdAt', () {
        final newDate = DateTime(2027, 1, 1);
        final copy = wallet.copyWith(createdAt: newDate);
        expect(copy.createdAt, newDate);
      });

      test('copies with multiple changes', () {
        final copy = wallet.copyWith(
          name: 'Updated',
          emoji: '🏦',
          colorValue: 0xFFEF4444,
        );
        expect(copy.name, 'Updated');
        expect(copy.emoji, '🏦');
        expect(copy.colorValue, 0xFFEF4444);
        expect(copy.id, wallet.id);
        expect(copy.isDefault, wallet.isDefault);
      });
    });

    group('presetColors', () {
      test('has 8 preset colors', () {
        expect(WalletModel.presetColors.length, 8);
      });

      test('all colors are valid ARGB values', () {
        for (final color in WalletModel.presetColors) {
          expect(color, greaterThan(0));
          // ARGB values should be in 0xFF000000 range
          expect(color & 0xFF000000, greaterThanOrEqualTo(0x06000000));
        }
      });

      test('default color is in preset list', () {
        expect(WalletModel.presetColors, contains(0xFF0D9373));
      });
    });

    group('presetEmojis', () {
      test('has 16 preset emojis', () {
        expect(WalletModel.presetEmojis.length, 16);
      });

      test('all emojis are non-empty strings', () {
        for (final emoji in WalletModel.presetEmojis) {
          expect(emoji, isNotEmpty);
        }
      });

      test('default emoji is in preset list', () {
        expect(WalletModel.presetEmojis, contains('💰'));
      });

      test('contains common wallet emojis', () {
        expect(WalletModel.presetEmojis, contains('💳'));
        expect(WalletModel.presetEmojis, contains('🏦'));
        expect(WalletModel.presetEmojis, contains('💵'));
      });
    });
  });
}
