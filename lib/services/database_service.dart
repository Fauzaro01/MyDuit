import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/wallet_model.dart';
import '../models/transfer_model.dart';

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
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE wallets(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL DEFAULT '💰',
        colorValue INTEGER NOT NULL DEFAULT 855405427,
        isDefault INTEGER NOT NULL DEFAULT 0,
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
        UNIQUE(category, year, month)
      )
    ''');
    await db.execute('''
      CREATE TABLE transfers(
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

    // Seed default wallet
    await _seedDefaultWallet(db);
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
    if (defaultWallet != null && defaultWallet.id != id) {
      await db.update(
        'transactions',
        {'walletId': defaultWallet.id},
        where: 'walletId = ?',
        whereArgs: [id],
      );
    }
    await db.delete(
      'transfers',
      where: 'fromWalletId = ? OR toWalletId = ?',
      whereArgs: [id, id],
    );
    await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
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
      'SELECT SUM(amount) as total FROM transfers WHERE fromWalletId = ?',
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
      orderBy: 'date DESC',
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
      orderBy: 'date DESC',
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
      orderBy: 'date DESC',
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

  Future<List<Map<String, dynamic>>> getDailyTotals(
    TransactionType type,
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final db = await database;
    final result = await db.rawQuery(
      '''SELECT date, SUM(amount) as total 
         FROM transactions 
         WHERE type = ? AND date >= ? AND date <= ? 
         GROUP BY date / 86400000
         ORDER BY date ASC''',
      [type.index, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return result;
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
}
