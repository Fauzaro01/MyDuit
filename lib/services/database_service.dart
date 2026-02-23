import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/wallet_model.dart';
import '../models/transfer_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/savings_goal_model.dart';
import '../models/debt_model.dart';
import '../models/custom_category_model.dart';

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
      version: 5,
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

    await _createV4Tables(db);
    await _createV5Tables(db);

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
    final List<TransactionModel> generated = [];

    for (final recurring in activeRecurrings) {
      // Skip if end date has passed
      if (recurring.endDate != null && recurring.endDate!.isBefore(today)) {
        await updateRecurringTransaction(recurring.copyWith(isActive: false));
        continue;
      }

      DateTime nextDate = recurring.lastGeneratedDate != null
          ? recurring.nextOccurrence(recurring.lastGeneratedDate!)
          : recurring.startDate;

      while (!nextDate.isAfter(today)) {
        final transaction = TransactionModel(
          title: recurring.title,
          amount: recurring.amount,
          type: recurring.type,
          category: recurring.category,
          date: nextDate,
          note: recurring.note != null
              ? '${recurring.note} (otomatis)'
              : '(transaksi otomatis)',
          walletId: recurring.walletId,
        );
        await insertTransaction(transaction);
        generated.add(transaction);
        nextDate = recurring.nextOccurrence(nextDate);
      }

      // Update lastGeneratedDate
      if (generated.isNotEmpty) {
        await updateRecurringTransaction(
          recurring.copyWith(lastGeneratedDate: today),
        );
      }
    }
    return generated;
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

  Future<void> addDebtPayment(String debtId, double amount) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE debts SET paidAmount = paidAmount + ? WHERE id = ?',
      [amount, debtId],
    );
    final result = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [debtId],
    );
    if (result.isNotEmpty) {
      final debt = DebtModel.fromMap(result.first);
      if (debt.isFullyPaid && !debt.isSettled) {
        await db.update(
          'debts',
          {'isSettled': 1},
          where: 'id = ?',
          whereArgs: [debtId],
        );
      }
    }
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
}
