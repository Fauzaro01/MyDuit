import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:myduit/services/local_backup_service.dart';

/// Repro of the legacy repeating-key XOR cipher that older backup versions
/// (v1/v2) used, so we can hand-craft old-format backups and prove the new
/// AES-GCM code path can still read them (backward compatibility).
List<int> _legacyXor(List<int> bytes, String key) {
  final keyBytes = utf8.encode(key);
  final out = List<int>.filled(bytes.length, 0);
  for (int i = 0; i < bytes.length; i++) {
    out[i] = bytes[i] ^ keyBytes[i % keyBytes.length];
  }
  return out;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LocalBackupService v3 (AES-GCM)', () {
    test('export produces a v3 payload with salt/nonce, readable with the right password', () async {
      final json = await LocalBackupService.exportToJsonString(password: 'rahasia123');
      final parsed = jsonDecode(json) as Map<String, dynamic>;

      expect(parsed['version'], 3);
      expect(parsed['encrypted'], true);
      expect(parsed.containsKey('salt'), isTrue);
      expect(parsed.containsKey('nonce'), isTrue);
      expect(parsed.containsKey('payload'), isTrue);

      final preview = await LocalBackupService.previewFromJsonString(
        json,
        password: 'rahasia123',
      );
      expect(preview.isEncrypted, isTrue);
      expect(preview.walletCount, 1); // DatabaseService seeds one default wallet on create
    });

    test('a PIN-derived key (arbitrary 64-char hex string) works as a password', () async {
      const pinKey = 'a1b2c3d4e5f60718293a4b5c6d7e8f901234567890abcdef1234567890abcd';
      final json = await LocalBackupService.exportToJsonString(password: pinKey);

      final preview = await LocalBackupService.previewFromJsonString(json, password: pinKey);
      expect(preview.isEncrypted, isTrue);
    });

    test('wrong password is rejected with the expected error', () async {
      final json = await LocalBackupService.exportToJsonString(password: 'rahasia123');

      expect(
        () => LocalBackupService.previewFromJsonString(json, password: 'password-salah'),
        throwsA(
          predicate(
            (e) => e is Exception && e.toString().contains('Password salah'),
          ),
        ),
      );
    });
  });

  group('LocalBackupService backward compatibility', () {
    test('legacy v2 (gzip + XOR) backups can still be read', () async {
      const password = 'oldpass';
      final innerJson = jsonEncode({
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'encrypted': true,
        'compressed': true,
        'data': {'wallets': []},
      });
      final compressed = gzip.encode(utf8.encode(innerJson));
      final cipher = _legacyXor(compressed, password);
      final legacyBackup = jsonEncode({
        'version': 2,
        'compressed': true,
        'encrypted': true,
        'exportedAt': DateTime.now().toIso8601String(),
        'payload': base64Encode(cipher),
      });

      final preview = await LocalBackupService.previewFromJsonString(
        legacyBackup,
        password: password,
      );
      expect(preview.isEncrypted, isTrue);
      expect(preview.isCompressed, isTrue);
      expect(preview.walletCount, 0);
    });

    test('legacy v1 (uncompressed cipher) backups can still be read', () async {
      const password = 'oldpass';
      final innerJson = jsonEncode({
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'encrypted': true,
        'compressed': false,
        'data': {'wallets': []},
      });
      final cipher = _legacyXor(utf8.encode(innerJson), password);
      final legacyBackup = jsonEncode({
        'version': 1,
        'encrypted': true,
        'compressed': false,
        'exportedAt': DateTime.now().toIso8601String(),
        'cipher': base64Encode(cipher),
      });

      final preview = await LocalBackupService.previewFromJsonString(
        legacyBackup,
        password: password,
      );
      expect(preview.isEncrypted, isTrue);
      expect(preview.walletCount, 0);
    });
  });
}
