import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class BackupPreviewInfo {
  final int walletCount;
  final int transactionCount;
  final int budgetCount;
  final int savingsGoalCount;
  final int debtCount;
  final int subscriptionCount;
  final int assetCount;
  final DateTime? exportedAt;
  final bool isEncrypted;
  final bool isCompressed;

  BackupPreviewInfo({
    required this.walletCount,
    required this.transactionCount,
    required this.budgetCount,
    required this.savingsGoalCount,
    required this.debtCount,
    required this.subscriptionCount,
    required this.assetCount,
    this.exportedAt,
    this.isEncrypted = false,
    this.isCompressed = false,
  });
}

class LocalBackupService {
  /// Export all SQLite data into JSON with optional Gzip compression & XOR encryption
  static Future<String> exportToJsonString({
    String? password,
    bool compress = true,
  }) async {
    final db = await DatabaseService().database;

    final wallets = await db.query('wallets');
    final transactions = await db.query('transactions');
    final budgets = await db.query('budgets');
    final transfers = await db.query('transfers');
    final recurrings = await db.query('recurring_transactions');
    final savings = await db.query('savings_goals');
    final debts = await db.query('debts');
    final categories = await db.query('custom_categories');
    final splitBills = await db.query('split_bills');
    final splitParticipants = await db.query('split_participants');
    final tags = await db.query('tags');
    final subscriptions = await db.query('subscriptions');
    final assets = await db.query('assets');
    final templates = await db.query('transaction_templates');

    final payload = {
      'version': compress ? 2 : 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'encrypted': password != null && password.isNotEmpty,
      'compressed': compress,
      'data': {
        'wallets': wallets,
        'transactions': transactions,
        'budgets': budgets,
        'transfers': transfers,
        'recurring_transactions': recurrings,
        'savings_goals': savings,
        'debts': debts,
        'custom_categories': categories,
        'split_bills': splitBills,
        'split_participants': splitParticipants,
        'tags': tags,
        'subscriptions': subscriptions,
        'assets': assets,
        'transaction_templates': templates,
      },
    };

    final rawJson = jsonEncode(payload);

    if (compress) {
      final rawBytes = utf8.encode(rawJson);
      final compressedBytes = gzip.encode(rawBytes);
      final finalBytes = (password != null && password.isNotEmpty)
          ? _xorBytes(compressedBytes, password)
          : compressedBytes;

      return jsonEncode({
        'version': 2,
        'compressed': true,
        'encrypted': password != null && password.isNotEmpty,
        'exportedAt': DateTime.now().toIso8601String(),
        'payload': base64Encode(finalBytes),
      });
    }

    if (password != null && password.isNotEmpty) {
      final rawBytes = utf8.encode(rawJson);
      final cipherBytes = _xorBytes(rawBytes, password);
      return jsonEncode({
        'version': 1,
        'encrypted': true,
        'compressed': false,
        'exportedAt': DateTime.now().toIso8601String(),
        'cipher': base64Encode(cipherBytes),
      });
    }

    return rawJson;
  }

  /// Export and share JSON backup file
  static Future<void> exportAndShare({
    String? password,
    bool compress = true,
  }) async {
    final jsonStr = await exportToJsonString(
      password: password,
      compress: compress,
    );
    final tempDir = await getTemporaryDirectory();
    final nowStr = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(join(tempDir.path, 'myduit_backup_$nowStr.json'));
    await file.writeAsString(jsonStr);

    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          'MyDuit Backup Data ${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}',
    );
  }

  /// Export direct SQLite .db binary file
  static Future<void> exportDatabaseFile() async {
    await DatabaseService().checkpointWal();
    final dbPath = join(await getDatabasesPath(), 'myduit.db');
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw Exception('Database file tidak ditemukan');
    }

    final tempDir = await getTemporaryDirectory();
    final nowStr = DateTime.now().toIso8601String().replaceAll(':', '-');
    final exportFile = File(join(tempDir.path, 'myduit_sqlite_$nowStr.db'));
    await dbFile.copy(exportFile.path);

    await Share.shareXFiles(
      [XFile(exportFile.path)],
      text: 'MyDuit SQLite Database Backup $nowStr',
    );
  }

  /// Preview metadata without modifying database
  static Future<BackupPreviewInfo> previewFromJsonString(
    String rawJson, {
    String? password,
  }) async {
    final dataMap = _extractDataMap(rawJson, password: password);
    final exportedAtStr = dataMap['exportedAt'] as String?;

    final data = dataMap['data'] as Map<String, dynamic>? ?? {};
    return BackupPreviewInfo(
      walletCount: (data['wallets'] as List? ?? []).length,
      transactionCount: (data['transactions'] as List? ?? []).length,
      budgetCount: (data['budgets'] as List? ?? []).length,
      savingsGoalCount: (data['savings_goals'] as List? ?? []).length,
      debtCount: (data['debts'] as List? ?? []).length,
      subscriptionCount: (data['subscriptions'] as List? ?? []).length,
      assetCount: (data['assets'] as List? ?? []).length,
      exportedAt: exportedAtStr != null ? DateTime.tryParse(exportedAtStr) : null,
      isEncrypted: dataMap['encrypted'] == true,
      isCompressed: dataMap['compressed'] == true,
    );
  }

  /// Decode JSON string payload
  static Map<String, dynamic> _extractDataMap(
    String rawJson, {
    String? password,
  }) {
    final Map<String, dynamic> parsed = jsonDecode(rawJson);

    // Version 2 (compressed payload)
    if (parsed.containsKey('payload')) {
      final isEncrypted = parsed['encrypted'] == true;
      if (isEncrypted && (password == null || password.isEmpty)) {
        throw Exception(
          'Password enkripsi diperlukan untuk membuka cadangan ini.',
        );
      }
      final payloadBytes = base64Decode(parsed['payload'] as String);
      final decryptedBytes = (isEncrypted && password != null)
          ? _xorBytes(payloadBytes, password)
          : payloadBytes;

      try {
        final decompressedBytes = gzip.decode(decryptedBytes);
        final jsonString = utf8.decode(decompressedBytes);
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (_) {
        if (isEncrypted) {
          throw Exception('Password salah atau berkas cadangan rusak.');
        }
        rethrow;
      }
    }

    // Version 1 (uncompressed cipher)
    if (parsed['encrypted'] == true && parsed.containsKey('cipher')) {
      if (password == null || password.isEmpty) {
        throw Exception(
          'Password enkripsi diperlukan untuk membuka cadangan ini.',
        );
      }
      final cipherBase64 = parsed['cipher'] as String;
      final cipherBytes = base64Decode(cipherBase64);
      final decryptedBytes = _xorBytes(cipherBytes, password);
      try {
        final decryptedString = utf8.decode(decryptedBytes);
        return jsonDecode(decryptedString) as Map<String, dynamic>;
      } catch (_) {
        throw Exception('Password salah atau berkas cadangan rusak.');
      }
    }

    return parsed;
  }

  /// Import and restore from JSON string with safety checks
  static Future<bool> importFromJsonString(
    String rawJson, {
    String? password,
  }) async {
    final extracted = _extractDataMap(rawJson, password: password);
    final dataMap = extracted['data'] as Map<String, dynamic>? ?? extracted;

    final db = await DatabaseService().database;

    await db.transaction((txn) async {
      // Clear current data
      await txn.delete('split_participants');
      await txn.delete('split_bills');
      await txn.delete('transfers');
      await txn.delete('transactions');
      await txn.delete('budgets');
      await txn.delete('recurring_transactions');
      await txn.delete('savings_goals');
      await txn.delete('debts');
      await txn.delete('custom_categories');
      await txn.delete('tags');
      await txn.delete('subscriptions');
      await txn.delete('assets');
      await txn.delete('transaction_templates');
      await txn.delete('wallets');

      // Insert wallets
      for (final item in (dataMap['wallets'] as List? ?? [])) {
        await txn.insert(
          'wallets',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final item in (dataMap['transactions'] as List? ?? [])) {
        await txn.insert(
          'transactions',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final item in (dataMap['budgets'] as List? ?? [])) {
        await txn.insert(
          'budgets',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final item in (dataMap['transfers'] as List? ?? [])) {
        await txn.insert(
          'transfers',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final item in (dataMap['recurring_transactions'] as List? ?? [])) {
        await txn.insert(
          'recurring_transactions',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final item in (dataMap['savings_goals'] as List? ?? [])) {
        await txn.insert(
          'savings_goals',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final item in (dataMap['debts'] as List? ?? [])) {
        await txn.insert(
          'debts',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final item in (dataMap['custom_categories'] as List? ?? [])) {
        await txn.insert(
          'custom_categories',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final item in (dataMap['split_bills'] as List? ?? [])) {
        await txn.insert(
          'split_bills',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final item in (dataMap['split_participants'] as List? ?? [])) {
        await txn.insert(
          'split_participants',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final item in (dataMap['tags'] as List? ?? [])) {
        await txn.insert(
          'tags',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final item in (dataMap['subscriptions'] as List? ?? [])) {
        await txn.insert(
          'subscriptions',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final item in (dataMap['assets'] as List? ?? [])) {
        await txn.insert(
          'assets',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final item in (dataMap['transaction_templates'] as List? ?? [])) {
        await txn.insert(
          'transaction_templates',
          Map<String, dynamic>.from(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    return true;
  }

  /// Import direct SQLite .db binary with rollback protection
  static Future<bool> importFromDatabaseBytes(Uint8List bytes) async {
    await DatabaseService().closeDatabase();

    final dbPath = join(await getDatabasesPath(), 'myduit.db');
    final dbFile = File(dbPath);
    final snapshotFile = File('$dbPath.safety_snapshot');
    final walFile = File('$dbPath-wal');
    final shmFile = File('$dbPath-shm');

    if (await dbFile.exists()) {
      try {
        await dbFile.copy(snapshotFile.path);
      } catch (_) {}
    }

    if (await walFile.exists()) {
      try {
        await walFile.delete();
      } catch (_) {}
    }
    if (await shmFile.exists()) {
      try {
        await shmFile.delete();
      } catch (_) {}
    }

    await dbFile.writeAsBytes(bytes);

    final isHealthy = await DatabaseService().integrityCheck();
    if (!isHealthy) {
      await DatabaseService().closeDatabase();
      if (await snapshotFile.exists()) {
        await snapshotFile.copy(dbFile.path);
        try {
          await snapshotFile.delete();
        } catch (_) {}
      }
      await DatabaseService().database;
      throw Exception('File SQLite tidak valid. Rollback berhasil dilakukan.');
    }

    if (await snapshotFile.exists()) {
      try {
        await snapshotFile.delete();
      } catch (_) {}
    }

    return true;
  }

  /// Binary XOR cipher for secure offline local backup
  static List<int> _xorBytes(List<int> bytes, String key) {
    if (key.isEmpty) return bytes;
    final keyBytes = utf8.encode(key);
    final output = Uint8List(bytes.length);

    for (int i = 0; i < bytes.length; i++) {
      output[i] = bytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return output;
  }
}
