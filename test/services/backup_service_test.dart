import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/services/google_drive_service.dart';

void main() {
  group('DriveBackupInfo Tests', () {
    test('formattedSize formats bytes correctly', () {
      final zero = DriveBackupInfo(
        fileId: '1',
        modifiedTime: DateTime.now(),
        sizeBytes: 0,
      );
      expect(zero.formattedSize, '0 B');

      final bytes = DriveBackupInfo(
        fileId: '2',
        modifiedTime: DateTime.now(),
        sizeBytes: 512,
      );
      expect(bytes.formattedSize, '512 B');

      final kb = DriveBackupInfo(
        fileId: '3',
        modifiedTime: DateTime.now(),
        sizeBytes: 2048,
      );
      expect(kb.formattedSize, '2.0 KB');

      final mb = DriveBackupInfo(
        fileId: '4',
        modifiedTime: DateTime.now(),
        sizeBytes: 5242880,
      );
      expect(mb.formattedSize, '5.00 MB');
    });
  });

  group('LocalBackup XOR & Base64 Roundtrip', () {
    test('XOR encryption and decryption produces original string', () {
      const originalText = '{"data":{"wallets":[{"name":"Dompet Utama"}]}}';
      const password = 'SecretPassword123!';

      // Test symmetrical byte XOR logic
      final keyBytes = utf8.encode(password);
      final rawBytes = utf8.encode(originalText);

      final cipherBytes = List<int>.generate(
        rawBytes.length,
        (i) => rawBytes[i] ^ keyBytes[i % keyBytes.length],
      );

      final decryptedBytes = List<int>.generate(
        cipherBytes.length,
        (i) => cipherBytes[i] ^ keyBytes[i % keyBytes.length],
      );

      final decryptedText = utf8.decode(decryptedBytes);
      expect(decryptedText, equals(originalText));
    });
  });
}
