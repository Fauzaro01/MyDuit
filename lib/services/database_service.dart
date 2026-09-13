import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/wallet_model.dart';
import '../models/transfer_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/savings_goal_model.dart';
import '../models/debt_model.dart';
import '../models/custom_category_model.dart';
import '../models/split_bill_model.dart';
import '../models/tag_model.dart';
import '../models/subscription_model.dart';
import '../models/asset_model.dart';
import '../models/transaction_template_model.dart';
import '../models/debt_payment_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  Future<Database>? _initFuture;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _initFuture ??= _initDatabase();
    _database = await _initFuture!;
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'myduit.db');

    return await openDatabase(
      path,
      version: 10,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      _initFuture = null;
    }
  }

  Future<void> checkpointWal() async {
    if (_database != null && _database!.isOpen) {
      try {
        await _database!.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
      } catch (_) {}
    }
  }

  Future<bool> integrityCheck() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      if (result.isNotEmpty && result.first.values.isNotEmpty) {
        final val = result.first.values.first.toString().toLowerCase();
        return val == 'ok';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE wallets(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL DEFAULT '💰',
        colorValue INTEGER NOT NULL DEFAULT 855405427,
        isDefault INTEGER NOT NULL DEFAULT 0,
        currencyCode TEXT NOT NULL DEFAULT 'IDR',
        createdAt INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type INTEGER NOT NULL,
        category INTEGER NOT NULL,
        date INTEGER NOT NULL,
        note TEXT,
        walletId TEXT,
        customCategoryId TEXT,
        tags TEXT,
        isPinned INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (walletId) REFERENCES wallets(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE budgets(
        id TEXT PRIMARY KEY,
        category INTEGER NOT NULL,
        monthlyLimit REAL NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        customCategoryId TEXT,
        UNIQUE(category, year, month)
      )
    ''');
    await db.execute('''
      CREATE TABLE transfers(
        id TEXT PRIMARY KEY,
        fromWalletId TEXT NOT NULL,
        toWalletId TEXT NOT NULL,
        amount REAL NOT NULL,
        adminFee REAL NOT NULL DEFAULT 0.0,
        note TEXT,
        date INTEGER NOT NULL,
        FOREIGN KEY (fromWalletId) REFERENCES wallets(id),
        FOREIGN KEY (toWalletId) REFERENCES wallets(id)
      )
    ''');

    await _createV4Tables(db);
    await _createV5Tables(db);
    await _createV7Tables(db);
    await _createV8Tables(db);
    await _createV9Tables(db);
    await _createV10Tables(db);

    // Seed default wallet
    await _seedDefaultWallet(db);
  }

  Future<void> _createV4Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurring_transactions(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type INTEGER NOT NULL,
        category INTEGER NOT NULL,
        frequency INTEGER NOT NULL,
        startDate INTEGER NOT NULL,
        endDate INTEGER,
        note TEXT,
        walletId TEXT,
        customCategoryId TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        lastGeneratedDate INTEGER,
        FOREIGN KEY (walletId) REFERENCES wallets(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS savings_goals(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        emoji TEXT NOT NULL DEFAULT '🎯',
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        targetDate INTEGER,
        isCompleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS debts(
        id TEXT PRIMARY KEY,
        personName TEXT NOT NULL,
        amount REAL NOT NULL,
        paidAmount REAL NOT NULL DEFAULT 0,
        type INTEGER NOT NULL,
        note TEXT,
        createdAt INTEGER NOT NULL,
        dueDate INTEGER,
        isSettled INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createV5Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_categories(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL DEFAULT '📌',
        isIncome INTEGER NOT NULL DEFAULT 0,
        colorValue INTEGER NOT NULL DEFAULT 855405427,
        createdAt INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createV7Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS split_bills(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        date INTEGER NOT NULL,
        isSettled INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        taxPercent REAL NOT NULL DEFAULT 0,
        servicePercent REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS split_participants(
        id TEXT PRIMARY KEY,
        billId TEXT NOT NULL,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        isPaid INTEGER NOT NULL DEFAULT 0,
        debtId TEXT,
        FOREIGN KEY (billId) REFERENCES split_bills(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createV8Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tags(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        colorValue INTEGER NOT NULL DEFAULT 855405427,
        createdAt INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subscriptions(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        billingCycle TEXT NOT NULL DEFAULT 'monthly',
        dueDay INTEGER NOT NULL,
        walletId TEXT,
        category INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        reminderDaysBefore INTEGER NOT NULL DEFAULT 2,
        notes TEXT,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (walletId) REFERENCES wallets(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS assets(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        notes TEXT,
        updatedAt INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createV9Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_templates(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type INTEGER NOT NULL,
        category INTEGER NOT NULL,
        customCategoryId TEXT,
        walletId TEXT,
        note TEXT,
        tags TEXT,
        emoji TEXT NOT NULL DEFAULT '⚡',
        FOREIGN KEY (walletId) REFERENCES wallets(id)
      )
    ''');
  }

  Future<void> _createV10Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debt_payments(
        id TEXT PRIMARY KEY,
        debtId TEXT NOT NULL,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY (debtId) REFERENCES debts(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets(
          id TEXT PRIMARY KEY,
          category INTEGER NOT NULL,
          monthlyLimit REAL NOT NULL,
          year INTEGER NOT NULL,
          month INTEGER NOT NULL,
          UNIQUE(category, year, month)
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS wallets(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          emoji TEXT NOT NULL DEFAULT '💰',
          colorValue INTEGER NOT NULL DEFAULT 855405427,
          isDefault INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transfers(
          id TEXT PRIMARY KEY,
          fromWalletId TEXT NOT NULL,
          toWalletId TEXT NOT NULL,
          amount REAL NOT NULL,
          note TEXT,
          date INTEGER NOT NULL,
          FOREIGN KEY (fromWalletId) REFERENCES wallets(id),
          FOREIGN KEY (toWalletId) REFERENCES wallets(id)
        )
      ''');
      await db.execute('ALTER TABLE transactions ADD COLUMN walletId TEXT');
      final defaultWalletId = await _seedDefaultWallet(db);
      await db.execute(
        'UPDATE transactions SET walletId = ? WHERE walletId IS NULL',
        [defaultWalletId],
      );
    }
    if (oldVersion < 4) {
      await _createV4Tables(db);
    }
    if (oldVersion < 5) {
      await _createV5Tables(db);
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE transactions ADD COLUMN customCategoryId TEXT');
      await db.execute('ALTER TABLE budgets ADD COLUMN customCategoryId TEXT');
      await db.execute('ALTER TABLE recurring_transactions ADD COLUMN customCategoryId TEXT');
    }
    if (oldVersion < 7) {
      await _createV7Tables(db);
      try {
        await db.execute("ALTER TABLE wallets ADD COLUMN currencyCode TEXT NOT NULL DEFAULT 'IDR'");
      } catch (_) {}
    }
    if (oldVersion < 8) {
      await _createV8Tables(db);
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN tags TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE budgets ADD COLUMN isRollover INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}
    }
    if (oldVersion < 9) {
      await _createV9Tables(db);
    }
    if (oldVersion < 10) {
      await _createV10Tables(db);
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN isPinned INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE transfers ADD COLUMN adminFee REAL NOT NULL DEFAULT 0.0');
      } catch (_) {}
    }
  }

  Future<String> _seedDefaultWallet(Database db) async {
    const defaultId = 'default-wallet';
    final existing = await db.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [defaultId],
    );
    if (existing.isEmpty) {
      await db.insert('wallets', {
        'id': defaultId,
        'name': 'Dompet Utama',
        'emoji': '💰',
        'colorValue': 0xFF0D9373,
        'isDefault': 1,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
    return defaultId;
  }

  // ── Wallet CRUD ───────────────────────────────────────────
  Future<void> insertWallet(WalletModel wallet) async {
    final db = await database;
    await db.insert(
      'wallets',
      wallet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateWallet(WalletModel wallet) async {
    final db = await database;
    await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  Future<void> deleteWallet(String id) async {
    final db = await database;
    final defaultWallet = await getDefaultWallet();
    await db.transaction((txn) async {
      if (defaultWallet != null && defaultWallet.id != id) {
        await txn.update(
          'transactions',
          {'walletId': defaultWallet.id},
          where: 'walletId = ?',
          whereArgs: [id],
        );
        await txn.update(
          'recurring_transactions',
          {'walletId': defaultWallet.id},
          where: 'walletId = ?',
          whereArgs: [id],
        );
      }
      await txn.delete(
        'transfers',
        where: 'fromWalletId = ? OR toWalletId = ?',
        whereArgs: [id, id],
      );
      await txn.delete('wallets', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<WalletModel>> getAllWallets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wallets',
      orderBy: 'isDefault DESC, createdAt ASC',
    );
    return List.generate(maps.length, (i) => WalletModel.fromMap(maps[i]));
  }

  Future<WalletModel?> getDefaultWallet() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wallets',
      where: 'isDefault = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return WalletModel.fromMap(maps.first);
  }

  Future<WalletModel?> getWalletById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return WalletModel.fromMap(maps.first);
  }

  Future<double> getWalletBalance(String walletId) async {
    final db = await database;
    final incomeResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE walletId = ? AND type = ?',
      [walletId, TransactionType.income.index],
    );
    final income = (incomeResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final expenseResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE walletId = ? AND type = ?',
      [walletId, TransactionType.expense.index],
    );
    final expense = (expenseResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final transferInResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transfers WHERE toWalletId = ?',
      [walletId],
    );
    final transferIn =
        (transferInResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final transferOutResult = await db.rawQuery(
      'SELECT SUM(amount + adminFee) as total FROM transfers WHERE fromWalletId = ?',
      [walletId],
    );
    final transferOut =
        (transferOutResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return income - expense + transferIn - transferOut;
  }

  // ── Transfer CRUD ─────────────────────────────────────────
  Future<void> insertTransfer(TransferModel transfer) async {
    final db = await database;
    await db.insert(
      'transfers',
      transfer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTransfer(String id) async {
    final db = await database;
    await db.delete('transfers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TransferModel>> getAllTransfers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transfers',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => TransferModel.fromMap(maps[i]));
  }

  Future<List<TransferModel>> getTransfersByWallet(String walletId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transfers',
      where: 'fromWalletId = ? OR toWalletId = ?',
      whereArgs: [walletId, walletId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => TransferModel.fromMap(maps[i]));
  }

  Future<List<TransferModel>> getTransfersByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transfers',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => TransferModel.fromMap(maps[i]));
  }

  // ── Transaction CRUD ──────────────────────────────────────
  Future<void> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'isPinned DESC, date DESC',
    );
    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  Future<List<TransactionModel>> getTransactionsByType(
    TransactionType type,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type.index],
      orderBy: 'isPinned DESC, date DESC',
    );
    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'isPinned DESC, date DESC',
    );
    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  Future<List<TransactionModel>> getTransactionsByMonth(
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return getTransactionsByDateRange(start, end);
  }

  Future<List<TransactionModel>> getTransactionsByWalletAndMonth(
    String walletId,
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'walletId = ? AND date >= ? AND date <= ?',
      whereArgs: [
        walletId,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<double> getTotalByType(TransactionType type) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      [type.index],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalByTypeAndMonth(
    TransactionType type,
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
      [type.index, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalByTypeWalletAndMonth(
    TransactionType type,
    String walletId,
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND walletId = ? AND date >= ? AND date <= ?',
      [
        type.index,
        walletId,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<TransactionCategory, double>> getCategoryTotals(
    TransactionType type,
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final db = await database;
    final result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ? GROUP BY category',
      [type.index, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );

    final Map<TransactionCategory, double> categoryTotals = {};
    for (final row in result) {
      final category = TransactionCategory.values[row['category'] as int];
      categoryTotals[category] = (row['total'] as num).toDouble();
    }
    return categoryTotals;
  }

  Future<Map<String, double>> getCustomCategoryTotals(
    TransactionType type,
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final db = await database;
    final result = await db.rawQuery(
      'SELECT customCategoryId, SUM(amount) as total FROM transactions WHERE type = ? AND customCategoryId IS NOT NULL AND date >= ? AND date <= ? GROUP BY customCategoryId',
      [type.index, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );

    final Map<String, double> customTotals = {};
    for (final row in result) {
      final customId = row['customCategoryId'] as String;
      customTotals[customId] = (row['total'] as num).toDouble();
    }
    return customTotals;
  }

  Future<List<Map<String, dynamic>>> getDailyTotals(
    TransactionType type,
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final db = await database;
    final result = await db.query(
      'transactions',
      columns: ['date', 'amount'],
      where: 'type = ? AND date >= ? AND date <= ?',
      whereArgs: [
        type.index,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'date ASC',
    );

    // Group by local day of month (1..31)
    final Map<int, double> dailyMap = {};
    for (final row in result) {
      final dt = DateTime.fromMillisecondsSinceEpoch(row['date'] as int);
      final day = dt.day;
      final amt = (row['amount'] as num).toDouble();
      dailyMap[day] = (dailyMap[day] ?? 0.0) + amt;
    }

    final sortedDays = dailyMap.keys.toList()..sort();
    return sortedDays.map((day) {
      final representativeDate = DateTime(year, month, day);
      return {
        'day': day,
        'date': representativeDate.millisecondsSinceEpoch,
        'total': dailyMap[day]!,
      };
    }).toList();
  }

  // ── Search ────────────────────────────────────────────────
  Future<List<TransactionModel>> searchTransactions(
    String query,
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: '(title LIKE ? OR note LIKE ?) AND date >= ? AND date <= ?',
      whereArgs: [
        '%$query%',
        '%$query%',
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  // ── Budget CRUD ───────────────────────────────────────────
  Future<void> upsertBudget(BudgetModel budget) async {
    final db = await database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBudget(String id) async {
    final db = await database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BudgetModel>> getBudgets(int year, int month) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );
    return List.generate(maps.length, (i) => BudgetModel.fromMap(maps[i]));
  }

  // ── Recurring Transaction CRUD ────────────────────────────
  Future<void> insertRecurringTransaction(
    RecurringTransactionModel recurring,
  ) async {
    final db = await database;
    await db.insert(
      'recurring_transactions',
      recurring.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateRecurringTransaction(
    RecurringTransactionModel recurring,
  ) async {
    final db = await database;
    await db.update(
      'recurring_transactions',
      recurring.toMap(),
      where: 'id = ?',
      whereArgs: [recurring.id],
    );
  }

  Future<void> deleteRecurringTransaction(String id) async {
    final db = await database;
    await db.delete('recurring_transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<RecurringTransactionModel>> getAllRecurringTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recurring_transactions',
      orderBy: 'startDate DESC',
    );
    return List.generate(
      maps.length,
      (i) => RecurringTransactionModel.fromMap(maps[i]),
    );
  }

  Future<List<RecurringTransactionModel>>
  getActiveRecurringTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recurring_transactions',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'startDate ASC',
    );
    return List.generate(
      maps.length,
      (i) => RecurringTransactionModel.fromMap(maps[i]),
    );
  }

  /// Generate pending recurring transactions up to today
  Future<List<TransactionModel>> generatePendingRecurringTransactions() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activeRecurrings = await getActiveRecurringTransactions();
    final List<TransactionModel> allGenerated = [];

    for (final recurring in activeRecurrings) {
      // Skip if end date has passed
      if (recurring.endDate != null && recurring.endDate!.isBefore(today)) {
        await updateRecurringTransaction(recurring.copyWith(isActive: false));
        continue;
      }

      DateTime nextDate = recurring.lastGeneratedDate != null
          ? recurring.nextOccurrence(recurring.lastGeneratedDate!)
          : recurring.startDate;

      final List<TransactionModel> itemGenerated = [];
      DateTime? latestDate;

      while (!nextDate.isAfter(today)) {
        if (recurring.endDate != null && nextDate.isAfter(recurring.endDate!)) {
          break;
        }

        final transaction = TransactionModel(
          title: recurring.title,
          amount: recurring.amount,
          type: recurring.type,
          category: recurring.category,
          date: nextDate,
          note: recurring.note != null && recurring.note!.isNotEmpty
              ? '${recurring.note} (otomatis)'
              : '(transaksi otomatis)',
          walletId: recurring.walletId,
          customCategoryId: recurring.customCategoryId,
        );
        await insertTransaction(transaction);
        itemGenerated.add(transaction);
        allGenerated.add(transaction);
        latestDate = nextDate;
        nextDate = recurring.nextOccurrence(nextDate);
      }

      // Update lastGeneratedDate only if this item actually generated transactions
      if (itemGenerated.isNotEmpty && latestDate != null) {
        await updateRecurringTransaction(
          recurring.copyWith(lastGeneratedDate: latestDate),
        );
      }
    }
    return allGenerated;
  }

  // ── Savings Goal CRUD ─────────────────────────────────────
  Future<void> insertSavingsGoal(SavingsGoalModel goal) async {
    final db = await database;
    await db.insert(
      'savings_goals',
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSavingsGoal(SavingsGoalModel goal) async {
    final db = await database;
    await db.update(
      'savings_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> deleteSavingsGoal(String id) async {
    final db = await database;
    await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SavingsGoalModel>> getAllSavingsGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'savings_goals',
      orderBy: 'isCompleted ASC, createdAt DESC',
    );
    return List.generate(maps.length, (i) => SavingsGoalModel.fromMap(maps[i]));
  }

  Future<void> addToSavingsGoal(String goalId, double amount) async {
    if (amount <= 0) return;
    final db = await database;
    await db.rawUpdate(
      'UPDATE savings_goals SET currentAmount = currentAmount + ? WHERE id = ?',
      [amount, goalId],
    );
    // Check if goal is reached
    final result = await db.query(
      'savings_goals',
      where: 'id = ?',
      whereArgs: [goalId],
    );
    if (result.isNotEmpty) {
      final goal = SavingsGoalModel.fromMap(result.first);
      if (goal.isReached && !goal.isCompleted) {
        await db.update(
          'savings_goals',
          {'isCompleted': 1},
          where: 'id = ?',
          whereArgs: [goalId],
        );
      }
    }
  }

  // ── Debt CRUD ─────────────────────────────────────────────
  Future<void> insertDebt(DebtModel debt) async {
    final db = await database;
    await db.insert(
      'debts',
      debt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDebt(DebtModel debt) async {
    final db = await database;
    await db.update(
      'debts',
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<void> deleteDebt(String id) async {
    final db = await database;
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DebtModel>> getAllDebts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'debts',
      orderBy: 'isSettled ASC, dueDate ASC, createdAt DESC',
    );
    return List.generate(maps.length, (i) => DebtModel.fromMap(maps[i]));
  }

  Future<List<DebtModel>> getDebtsByType(DebtType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'debts',
      where: 'type = ?',
      whereArgs: [type.index],
      orderBy: 'isSettled ASC, dueDate ASC, createdAt DESC',
    );
    return List.generate(maps.length, (i) => DebtModel.fromMap(maps[i]));
  }

  Future<void> addDebtPayment(
    String debtId,
    double amount, {
    String? note,
    DateTime? date,
  }) async {
    if (amount <= 0) return;
    final db = await database;
    final existing = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [debtId],
    );
    if (existing.isEmpty) return;
    final debt = DebtModel.fromMap(existing.first);
    final remaining = (debt.amount - debt.paidAmount).clamp(0.0, double.infinity);
    final paymentToApply = amount > remaining ? remaining : amount;

    await db.insert('debt_payments', {
      'id': const Uuid().v4(),
      'debtId': debtId,
      'amount': paymentToApply,
      'date': (date ?? DateTime.now()).millisecondsSinceEpoch,
      'note': note,
    });

    await db.rawUpdate(
      'UPDATE debts SET paidAmount = paidAmount + ? WHERE id = ?',
      [paymentToApply, debtId],
    );
    final result = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [debtId],
    );
    if (result.isNotEmpty) {
      final updatedDebt = DebtModel.fromMap(result.first);
      if (updatedDebt.isFullyPaid && !updatedDebt.isSettled) {
        await db.update(
          'debts',
          {'isSettled': 1},
          where: 'id = ?',
          whereArgs: [debtId],
        );
      }
    }
  }

  Future<List<DebtPaymentModel>> getDebtPayments(String debtId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'debt_payments',
      where: 'debtId = ?',
      whereArgs: [debtId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => DebtPaymentModel.fromMap(maps[i]));
  }

  Future<double> getTotalDebtAmount(
    DebtType type, {
    bool settledOnly = false,
  }) async {
    final db = await database;
    final where = settledOnly
        ? 'type = ? AND isSettled = 1'
        : 'type = ? AND isSettled = 0';
    final result = await db.rawQuery(
      'SELECT SUM(amount - paidAmount) as total FROM debts WHERE $where',
      [type.index],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ── Custom Category CRUD ──────────────────────────────────
  Future<void> insertCustomCategory(CustomCategoryModel category) async {
    final db = await database;
    await db.insert(
      'custom_categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCustomCategory(CustomCategoryModel category) async {
    final db = await database;
    await db.update(
      'custom_categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCustomCategory(String id) async {
    final db = await database;
    await db.delete('custom_categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CustomCategoryModel>> getAllCustomCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'custom_categories',
      orderBy: 'createdAt ASC',
    );
    return List.generate(
      maps.length,
      (i) => CustomCategoryModel.fromMap(maps[i]),
    );
  }

  // ── Split Bill CRUD ───────────────────────────────────────
  Future<void> insertSplitBill(SplitBillModel bill) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'split_bills',
        bill.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final p in bill.participants) {
        await txn.insert(
          'split_participants',
          p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> updateSplitBill(SplitBillModel bill) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'split_bills',
        bill.toMap(),
        where: 'id = ?',
        whereArgs: [bill.id],
      );
      await txn.delete(
        'split_participants',
        where: 'billId = ?',
        whereArgs: [bill.id],
      );
      for (final p in bill.participants) {
        await txn.insert(
          'split_participants',
          p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> deleteSplitBill(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'split_participants',
        where: 'billId = ?',
        whereArgs: [id],
      );
      await txn.delete('split_bills', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<SplitBillModel>> getAllSplitBills() async {
    final db = await database;
    final List<Map<String, dynamic>> billMaps = await db.query(
      'split_bills',
      orderBy: 'isSettled ASC, date DESC',
    );

    final List<SplitBillModel> result = [];
    for (final bMap in billMaps) {
      final billId = bMap['id'] as String;
      final List<Map<String, dynamic>> pMaps = await db.query(
        'split_participants',
        where: 'billId = ?',
        whereArgs: [billId],
      );
      final participants = pMaps.map((p) => SplitParticipant.fromMap(p)).toList();
      result.add(SplitBillModel.fromMap(bMap, participants: participants));
    }
    return result;
  }

  Future<void> toggleSplitParticipantPaid(
    String participantId,
    bool isPaid,
  ) async {
    final db = await database;
    await db.update(
      'split_participants',
      {'isPaid': isPaid ? 1 : 0},
      where: 'id = ?',
      whereArgs: [participantId],
    );
  }

  Future<void> updateSplitParticipantDebtId(
    String participantId,
    String? debtId,
  ) async {
    final db = await database;
    await db.update(
      'split_participants',
      {'debtId': debtId},
      where: 'id = ?',
      whereArgs: [participantId],
    );
  }

  Future<void> settleSplitBill(String billId, bool isSettled) async {
    final db = await database;
    await db.update(
      'split_bills',
      {'isSettled': isSettled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [billId],
    );
  }

  // ── Tag CRUD ──────────────────────────────────────────────
  Future<void> insertTag(TagModel tag) async {
    final db = await database;
    await db.insert(
      'tags',
      tag.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTag(TagModel tag) async {
    final db = await database;
    await db.update(
      'tags',
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  Future<void> deleteTag(String id) async {
    final db = await database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TagModel>> getAllTags() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      orderBy: 'createdAt ASC',
    );
    return List.generate(maps.length, (i) => TagModel.fromMap(maps[i]));
  }

  // ── Subscription CRUD ─────────────────────────────────────
  Future<void> insertSubscription(SubscriptionModel sub) async {
    final db = await database;
    await db.insert(
      'subscriptions',
      sub.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSubscription(SubscriptionModel sub) async {
    final db = await database;
    await db.update(
      'subscriptions',
      sub.toMap(),
      where: 'id = ?',
      whereArgs: [sub.id],
    );
  }

  Future<void> deleteSubscription(String id) async {
    final db = await database;
    await db.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SubscriptionModel>> getAllSubscriptions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subscriptions',
      orderBy: 'isActive DESC, dueDay ASC',
    );
    return List.generate(maps.length, (i) => SubscriptionModel.fromMap(maps[i]));
  }

  // ── Asset CRUD ────────────────────────────────────────────
  Future<void> insertAsset(AssetModel asset) async {
    final db = await database;
    await db.insert(
      'assets',
      asset.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAsset(AssetModel asset) async {
    final db = await database;
    await db.update(
      'assets',
      asset.toMap(),
      where: 'id = ?',
      whereArgs: [asset.id],
    );
  }

  Future<void> deleteAsset(String id) async {
    final db = await database;
    await db.delete('assets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<AssetModel>> getAllAssets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assets',
      orderBy: 'updatedAt DESC',
    );
    return List.generate(maps.length, (i) => AssetModel.fromMap(maps[i]));
  }

  // ── Transaction Template CRUD ─────────────────────────────
  Future<void> insertTemplate(TransactionTemplateModel template) async {
    final db = await database;
    await db.insert(
      'transaction_templates',
      template.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTemplate(TransactionTemplateModel template) async {
    final db = await database;
    await db.update(
      'transaction_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<void> deleteTemplate(String id) async {
    final db = await database;
    await db.delete('transaction_templates', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TransactionTemplateModel>> getAllTemplates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaction_templates',
    );
    if (maps.isEmpty) {
      // Seed default templates
      for (final tpl in TransactionTemplateModel.defaultTemplates) {
        await insertTemplate(tpl);
      }
      final List<Map<String, dynamic>> seeded = await db.query(
        'transaction_templates',
      );
      return List.generate(seeded.length, (i) => TransactionTemplateModel.fromMap(seeded[i]));
    }
    return List.generate(maps.length, (i) => TransactionTemplateModel.fromMap(maps[i]));
  }

  // ── Selective Data Reset ─────────────────────────────────
  Future<void> clearTransactions() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('transfers');
    });
  }

  Future<void> clearDebts() async {
    final db = await database;
    await db.delete('debts');
  }

  Future<void> clearSavingsGoals() async {
    final db = await database;
    await db.delete('savings_goals');
  }

  Future<void> clearSubscriptions() async {
    final db = await database;
    await db.delete('subscriptions');
  }

  Future<void> clearAssets() async {
    final db = await database;
    await db.delete('assets');
  }

  Future<void> clearSplitBills() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('split_participants');
      await txn.delete('split_bills');
    });
  }
}
