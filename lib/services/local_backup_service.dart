import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class LocalBackupService {
  /// Export all SQLite data into JSON with optional XOR-based passphrase obfuscation/encryption
  static Future<String> exportToJsonString({String? password}) async {
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
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'encrypted': password != null && password.isNotEmpty,
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

    if (password != null && password.isNotEmpty) {
      final cipherText = _cipher(rawJson, password);
      return jsonEncode({
        'version': 1,
        'encrypted': true,
        'exportedAt': DateTime.now().toIso8601String(),
        'cipher': base64Encode(utf8.encode(cipherText)),
      });
    }

    return rawJson;
  }

  /// Export and share JSON backup file
  static Future<void> exportAndShare({String? password}) async {
    final jsonStr = await exportToJsonString(password: password);
    final tempDir = await getTemporaryDirectory();
    final nowStr = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(join(tempDir.path, 'myduit_backup_$nowStr.json'));
    await file.writeAsString(jsonStr);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'MyDuit Backup Data ${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}',
    );
  }

  /// Import and restore from JSON string
  static Future<bool> importFromJsonString(String rawJson, {String? password}) async {
    final Map<String, dynamic> parsed = jsonDecode(rawJson);
    Map<String, dynamic> dataMap;

    if (parsed['encrypted'] == true) {
      if (password == null || password.isEmpty) {
        throw Exception('Password diperlukan untuk membuka file cadangan terenkripsi.');
      }
      final cipherBase64 = parsed['cipher'] as String;
      final cipherText = utf8.decode(base64Decode(cipherBase64));
      final decrypted = _cipher(cipherText, password);
      final Map<String, dynamic> decryptedJson = jsonDecode(decrypted);
      dataMap = decryptedJson['data'] as Map<String, dynamic>;
    } else {
      dataMap = parsed['data'] as Map<String, dynamic>;
    }

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
        await txn.insert('wallets', Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final item in (dataMap['transactions'] as List? ?? [])) {
        await txn.insert('transactions', Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final item in (dataMap['budgets'] as List? ?? [])) {
        await txn.insert('budgets', Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final item in (dataMap['transfers'] as List? ?? [])) {
        await txn.insert('transfers', Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final item in (dataMap['recurring_transactions'] as List? ?? [])) {
        await txn.insert('recurring_transactions', Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final item in (dataMap['savings_goals'] as List? ?? [])) {
        await txn.insert('savings_goals', Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final item in (dataMap['debts'] as List? ?? [])) {
        await txn.insert('debts', Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final item in (dataMap['custom_categories'] as List? ?? [])) {
        await txn.insert('custom_categories', Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final item in (dataMap['split_bills'] as List? ?? [])) {
        await txn.insert('split_bills', Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final item in (dataMap['split_participants'] as List? ?? [])) {
        await txn.insert('split_participants', Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final item in (dataMap['tags'] as List? ?? [])) {
        await txn.insert('tags', Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final item in (dataMap['subscriptions'] as List? ?? [])) {
        await txn.insert('subscriptions', Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final item in (dataMap['assets'] as List? ?? [])) {
        await txn.insert('assets', Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final item in (dataMap['transaction_templates'] as List? ?? [])) {
        await txn.insert('transaction_templates', Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });

    return true;
  }

  /// Simple reversible symmetric cipher for local offline backup
  static String _cipher(String text, String key) {
    if (key.isEmpty) return text;
    final textBytes = utf8.encode(text);
    final keyBytes = utf8.encode(key);
    final output = <int>[];

    for (int i = 0; i < textBytes.length; i++) {
      output.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    return String.fromCharCodes(output);
  }
}
