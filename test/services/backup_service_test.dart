import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/services/google_drive_service.dart';
import 'package:myduit/services/local_backup_service.dart';

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

    test('preserves fileName and description', () {
      final info = DriveBackupInfo(
        fileId: 'test-123',
        fileName: 'myduit_backup_20260914.db',
        modifiedTime: DateTime(2026, 9, 14),
        sizeBytes: 1024,
        description: 'Auto snapshot',
      );
      expect(info.fileName, 'myduit_backup_20260914.db');
      expect(info.description, 'Auto snapshot');
    });
  });

  group('LocalBackup GZip & XOR Compression Tests', () {
    test('XOR encryption and decryption produces original string', () {
      const originalText = '{"data":{"wallets":[{"name":"Dompet Utama"}]}}';
      const password = 'SecretPassword123!';

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

    test('GZip compression reduces large JSON size significantly', () {
      final sampleData = {
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'data': {
          'wallets': List.generate(
            10,
            (i) => {'id': 'w-$i', 'name': 'Wallet $i', 'balance': 1000000},
          ),
          'transactions': List.generate(
            50,
            (i) => {
              'id': 'tx-$i',
              'title': 'Coffee Purchase $i',
              'amount': 25000,
              'category': 'Food',
            },
          ),
        },
      };

      final jsonStr = jsonEncode(sampleData);
      final uncompressedBytes = utf8.encode(jsonStr);
      final compressedBytes = gzip.encode(uncompressedBytes);

      expect(compressedBytes.length, lessThan(uncompressedBytes.length));

      final decompressedBytes = gzip.decode(compressedBytes);
      expect(utf8.decode(decompressedBytes), equals(jsonStr));
    });

    test('previewFromJsonString parses uncompressed metadata correctly', () async {
      final sampleData = {
        'version': 1,
        'exportedAt': '2026-09-14T10:00:00.000',
        'encrypted': false,
        'compressed': false,
        'data': {
          'wallets': [{'id': '1'}],
          'transactions': [{'id': '1'}, {'id': '2'}],
          'budgets': [{'id': '1'}],
          'savings_goals': [],
          'debts': [{'id': '1'}],
          'subscriptions': [],
          'assets': [],
        },
      };

      final preview = await LocalBackupService.previewFromJsonString(
        jsonEncode(sampleData),
      );

      expect(preview.walletCount, 1);
      expect(preview.transactionCount, 2);
      expect(preview.budgetCount, 1);
      expect(preview.debtCount, 1);
      expect(preview.savingsGoalCount, 0);
      expect(preview.isEncrypted, false);
      expect(preview.isCompressed, false);
    });

    test('previewFromJsonString handles compressed & encrypted payload', () async {
      const password = 'MyPassword123';
      final innerData = {
        'version': 2,
        'exportedAt': '2026-09-14T10:00:00.000',
        'encrypted': true,
        'compressed': true,
        'data': {
          'wallets': [{'id': 'w1'}, {'id': 'w2'}],
          'transactions': [{'id': 't1'}],
          'budgets': [],
          'savings_goals': [{'id': 's1'}],
          'debts': [],
          'subscriptions': [],
          'assets': [],
        },
      };

      final rawBytes = utf8.encode(jsonEncode(innerData));
      final compressedBytes = gzip.encode(rawBytes);

      // XOR
      final keyBytes = utf8.encode(password);
      final cipherBytes = List<int>.generate(
        compressedBytes.length,
        (i) => compressedBytes[i] ^ keyBytes[i % keyBytes.length],
      );

      final payloadJson = jsonEncode({
        'version': 2,
        'compressed': true,
        'encrypted': true,
        'exportedAt': '2026-09-14T10:00:00.000',
        'payload': base64Encode(cipherBytes),
      });

      final preview = await LocalBackupService.previewFromJsonString(
        payloadJson,
        password: password,
      );

      expect(preview.walletCount, 2);
      expect(preview.transactionCount, 1);
      expect(preview.savingsGoalCount, 1);
      expect(preview.isEncrypted, true);
      expect(preview.isCompressed, true);
    });

    test('previewFromJsonString throws on wrong password', () async {
      final payloadJson = jsonEncode({
        'version': 2,
        'compressed': true,
        'encrypted': true,
        'exportedAt': '2026-09-14T10:00:00.000',
        'payload': base64Encode([1, 2, 3, 4, 5]),
      });

      expect(
        () => LocalBackupService.previewFromJsonString(
          payloadJson,
          password: 'WrongPassword',
        ),
        throwsException,
      );
    });
  });
}
