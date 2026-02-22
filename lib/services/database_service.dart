import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'myduit.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type INTEGER NOT NULL,
        category INTEGER NOT NULL,
        date INTEGER NOT NULL,
        note TEXT
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
  }

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
