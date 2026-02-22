import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/models/budget_model.dart';

/// We test the database logic directly instead of through DatabaseService
/// since DatabaseService is a singleton. We replicate the schema and queries.
void main() {
  late Database db;

  sqfliteFfiInit();

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 2,
      onCreate: (db, version) async {
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
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  TransactionModel _createTransaction({
    String? id,
    String title = 'Test',
    double amount = 50000,
    TransactionType type = TransactionType.expense,
    TransactionCategory category = TransactionCategory.food,
    DateTime? date,
    String? note,
  }) {
    return TransactionModel(
      id: id ?? 'tx-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      amount: amount,
      type: type,
      category: category,
      date: date ?? DateTime(2026, 2, 15),
      note: note,
    );
  }

  group('Transaction CRUD', () {
    test('insert and retrieve transaction', () async {
      final tx = _createTransaction(id: 'tx-1', title: 'Makan Siang');

      await db.insert(
        'transactions',
        tx.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final maps = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: ['tx-1'],
      );
      expect(maps.length, 1);

      final restored = TransactionModel.fromMap(maps.first);
      expect(restored.id, 'tx-1');
      expect(restored.title, 'Makan Siang');
      expect(restored.amount, 50000);
    });

    test('update transaction', () async {
      final tx = _createTransaction(id: 'tx-2', title: 'Original');
      await db.insert('transactions', tx.toMap());

      final updated = tx.copyWith(title: 'Updated', amount: 75000);
      await db.update(
        'transactions',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [updated.id],
      );

      final maps = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: ['tx-2'],
      );
      final restored = TransactionModel.fromMap(maps.first);
      expect(restored.title, 'Updated');
      expect(restored.amount, 75000);
    });

    test('delete transaction', () async {
      final tx = _createTransaction(id: 'tx-3');
      await db.insert('transactions', tx.toMap());

      await db.delete('transactions', where: 'id = ?', whereArgs: ['tx-3']);

      final maps = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: ['tx-3'],
      );
      expect(maps, isEmpty);
    });

    test('retrieve all transactions ordered by date DESC', () async {
      final tx1 = _createTransaction(
        id: 'tx-a',
        title: 'Older',
        date: DateTime(2026, 2, 10),
      );
      final tx2 = _createTransaction(
        id: 'tx-b',
        title: 'Newer',
        date: DateTime(2026, 2, 20),
      );

      await db.insert('transactions', tx1.toMap());
      await db.insert('transactions', tx2.toMap());

      final maps = await db.query('transactions', orderBy: 'date DESC');
      expect(maps.length, 2);
      expect(maps[0]['title'], 'Newer');
      expect(maps[1]['title'], 'Older');
    });
  });

  group('Transaction queries by month', () {
    setUp(() async {
      // Insert transactions for Feb 2026
      final txFeb1 = _createTransaction(
        id: 'feb-1',
        title: 'Feb Food',
        amount: 30000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime(2026, 2, 5),
      );
      final txFeb2 = _createTransaction(
        id: 'feb-2',
        title: 'Feb Salary',
        amount: 5000000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        date: DateTime(2026, 2, 10),
      );
      // Insert transaction for Jan 2026
      final txJan = _createTransaction(
        id: 'jan-1',
        title: 'Jan Shopping',
        amount: 100000,
        type: TransactionType.expense,
        category: TransactionCategory.shopping,
        date: DateTime(2026, 1, 15),
      );

      await db.insert('transactions', txFeb1.toMap());
      await db.insert('transactions', txFeb2.toMap());
      await db.insert('transactions', txJan.toMap());
    });

    test('getTransactionsByMonth returns only for specified month', () async {
      final start = DateTime(2026, 2, 1);
      final end = DateTime(2026, 3, 0, 23, 59, 59);

      final maps = await db.query(
        'transactions',
        where: 'date >= ? AND date <= ?',
        whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
        orderBy: 'date DESC',
      );

      expect(maps.length, 2);
      final titles = maps.map((m) => m['title']).toSet();
      expect(titles, contains('Feb Food'));
      expect(titles, contains('Feb Salary'));
      expect(titles, isNot(contains('Jan Shopping')));
    });

    test('getTotalByTypeAndMonth returns correct sum', () async {
      final start = DateTime(2026, 2, 1);
      final end = DateTime(2026, 3, 0, 23, 59, 59);

      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
        [
          TransactionType.expense.index,
          start.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
        ],
      );

      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      expect(total, 30000);
    });

    test('getTotalByTypeAndMonth income returns correct sum', () async {
      final start = DateTime(2026, 2, 1);
      final end = DateTime(2026, 3, 0, 23, 59, 59);

      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
        [
          TransactionType.income.index,
          start.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
        ],
      );

      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      expect(total, 5000000);
    });

    test('getTotalByTypeAndMonth returns 0 for empty month', () async {
      final start = DateTime(2026, 3, 1);
      final end = DateTime(2026, 4, 0, 23, 59, 59);

      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
        [
          TransactionType.expense.index,
          start.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
        ],
      );

      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      expect(total, 0.0);
    });

    test('getCategoryTotals returns grouped data', () async {
      // Add another food expense in Feb
      final txFeb3 = _createTransaction(
        id: 'feb-3',
        title: 'Feb Food 2',
        amount: 20000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime(2026, 2, 12),
      );
      await db.insert('transactions', txFeb3.toMap());

      final start = DateTime(2026, 2, 1);
      final end = DateTime(2026, 3, 0, 23, 59, 59);

      final result = await db.rawQuery(
        'SELECT category, SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ? GROUP BY category',
        [
          TransactionType.expense.index,
          start.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
        ],
      );

      final Map<TransactionCategory, double> categoryTotals = {};
      for (final row in result) {
        final category = TransactionCategory.values[row['category'] as int];
        categoryTotals[category] = (row['total'] as num).toDouble();
      }

      expect(categoryTotals[TransactionCategory.food], 50000); // 30k + 20k
      expect(categoryTotals.containsKey(TransactionCategory.shopping), isFalse);
    });
  });

  group('Search transactions', () {
    setUp(() async {
      final txs = [
        _createTransaction(
          id: 'search-1',
          title: 'Makan Siang di Warteg',
          date: DateTime(2026, 2, 5),
          note: 'Nasi padang',
        ),
        _createTransaction(
          id: 'search-2',
          title: 'Beli Kopi',
          date: DateTime(2026, 2, 10),
          note: 'Starbucks',
        ),
        _createTransaction(
          id: 'search-3',
          title: 'Belanja Bulanan',
          date: DateTime(2026, 2, 15),
          note: 'Indomaret',
        ),
      ];
      for (final tx in txs) {
        await db.insert('transactions', tx.toMap());
      }
    });

    test('searches by title', () async {
      final start = DateTime(2026, 2, 1);
      final end = DateTime(2026, 3, 0, 23, 59, 59);
      final query = 'Makan';

      final maps = await db.query(
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

      expect(maps.length, 1);
      expect(maps.first['title'], 'Makan Siang di Warteg');
    });

    test('searches by note', () async {
      final start = DateTime(2026, 2, 1);
      final end = DateTime(2026, 3, 0, 23, 59, 59);
      final query = 'Starbucks';

      final maps = await db.query(
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

      expect(maps.length, 1);
      expect(maps.first['title'], 'Beli Kopi');
    });

    test('search is case-insensitive (SQLite default)', () async {
      final start = DateTime(2026, 2, 1);
      final end = DateTime(2026, 3, 0, 23, 59, 59);
      final query = 'makan';

      final maps = await db.query(
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

      expect(maps.length, 1);
    });

    test('returns empty for non-matching query', () async {
      final start = DateTime(2026, 2, 1);
      final end = DateTime(2026, 3, 0, 23, 59, 59);
      final query = 'nonexistent';

      final maps = await db.query(
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

      expect(maps, isEmpty);
    });

    test('returns multiple matches', () async {
      final start = DateTime(2026, 2, 1);
      final end = DateTime(2026, 3, 0, 23, 59, 59);
      final query = 'Bel'; // matches "Beli Kopi" and "Belanja Bulanan"

      final maps = await db.query(
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

      expect(maps.length, 2);
    });
  });

  group('Budget CRUD', () {
    test('insert and retrieve budget', () async {
      final budget = BudgetModel(
        id: 'bud-1',
        category: TransactionCategory.food,
        monthlyLimit: 1500000,
        year: 2026,
        month: 2,
      );

      await db.insert(
        'budgets',
        budget.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final maps = await db.query(
        'budgets',
        where: 'year = ? AND month = ?',
        whereArgs: [2026, 2],
      );

      expect(maps.length, 1);
      final restored = BudgetModel.fromMap(maps.first);
      expect(restored.id, 'bud-1');
      expect(restored.category, TransactionCategory.food);
      expect(restored.monthlyLimit, 1500000);
    });

    test('upsert replaces existing budget for same category/year/month', () async {
      final budget1 = BudgetModel(
        id: 'bud-2',
        category: TransactionCategory.food,
        monthlyLimit: 1000000,
        year: 2026,
        month: 2,
      );
      await db.insert(
        'budgets',
        budget1.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Upsert with same category, year, month but different limit
      final budget2 = BudgetModel(
        id: 'bud-2-updated',
        category: TransactionCategory.food,
        monthlyLimit: 2000000,
        year: 2026,
        month: 2,
      );
      await db.insert(
        'budgets',
        budget2.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final maps = await db.query(
        'budgets',
        where: 'year = ? AND month = ?',
        whereArgs: [2026, 2],
      );

      // Should have at most 2 entries (different ids), but category+year+month unique constraint
      // means the second insert replaces if same unique key
      final foodBudgets = maps
          .where((m) => m['category'] == TransactionCategory.food.index)
          .toList();

      // With UNIQUE constraint and REPLACE, the second insert replaces the first
      expect(foodBudgets.length, 1);
      expect(foodBudgets.first['monthlyLimit'], 2000000);
    });

    test('delete budget', () async {
      final budget = BudgetModel(
        id: 'bud-3',
        category: TransactionCategory.transport,
        monthlyLimit: 500000,
        year: 2026,
        month: 2,
      );
      await db.insert('budgets', budget.toMap());

      await db.delete('budgets', where: 'id = ?', whereArgs: ['bud-3']);

      final maps = await db.query(
        'budgets',
        where: 'id = ?',
        whereArgs: ['bud-3'],
      );
      expect(maps, isEmpty);
    });

    test('getBudgets returns only for specified month', () async {
      final budFeb = BudgetModel(
        id: 'bud-feb',
        category: TransactionCategory.food,
        monthlyLimit: 1000000,
        year: 2026,
        month: 2,
      );
      final budMar = BudgetModel(
        id: 'bud-mar',
        category: TransactionCategory.food,
        monthlyLimit: 1200000,
        year: 2026,
        month: 3,
      );

      await db.insert('budgets', budFeb.toMap());
      await db.insert('budgets', budMar.toMap());

      final maps = await db.query(
        'budgets',
        where: 'year = ? AND month = ?',
        whereArgs: [2026, 2],
      );

      expect(maps.length, 1);
      expect(BudgetModel.fromMap(maps.first).monthlyLimit, 1000000);
    });

    test('multiple budgets for different categories in same month', () async {
      final budFood = BudgetModel(
        id: 'bud-food',
        category: TransactionCategory.food,
        monthlyLimit: 1000000,
        year: 2026,
        month: 2,
      );
      final budTransport = BudgetModel(
        id: 'bud-transport',
        category: TransactionCategory.transport,
        monthlyLimit: 500000,
        year: 2026,
        month: 2,
      );

      await db.insert('budgets', budFood.toMap());
      await db.insert('budgets', budTransport.toMap());

      final maps = await db.query(
        'budgets',
        where: 'year = ? AND month = ?',
        whereArgs: [2026, 2],
      );

      expect(maps.length, 2);
    });
  });

  group('Daily totals', () {
    test('getDailyTotals groups by day', () async {
      // Two expense on same day, one on different day
      final tx1 = _createTransaction(
        id: 'daily-1',
        amount: 20000,
        date: DateTime(2026, 2, 10, 8, 0),
      );
      final tx2 = _createTransaction(
        id: 'daily-2',
        amount: 30000,
        date: DateTime(2026, 2, 10, 12, 0),
      );
      final tx3 = _createTransaction(
        id: 'daily-3',
        amount: 50000,
        date: DateTime(2026, 2, 11, 9, 0),
      );

      await db.insert('transactions', tx1.toMap());
      await db.insert('transactions', tx2.toMap());
      await db.insert('transactions', tx3.toMap());

      final start = DateTime(2026, 2, 1);
      final end = DateTime(2026, 3, 0, 23, 59, 59);

      final result = await db.rawQuery(
        '''SELECT date, SUM(amount) as total 
           FROM transactions 
           WHERE type = ? AND date >= ? AND date <= ? 
           GROUP BY date / 86400000
           ORDER BY date ASC''',
        [
          TransactionType.expense.index,
          start.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
        ],
      );

      expect(result.length, 2);
      // First group (Feb 10): 20k + 30k = 50k
      expect((result[0]['total'] as num).toDouble(), 50000);
      // Second group (Feb 11): 50k
      expect((result[1]['total'] as num).toDouble(), 50000);
    });
  });

  group('Schema upgrade', () {
    test('v1 to v2 adds budgets table', () async {
      // Use a unique named in-memory database for isolation
      final dbPath =
          'schema_upgrade_test_${DateTime.now().millisecondsSinceEpoch}.db';

      // Simulate v1 database (single connection that stays open for upgrade)
      final v1db = await openDatabase(
        dbPath,
        version: 1,
        singleInstance: false,
        onCreate: (db, version) async {
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
        },
      );

      // Verify budgets table doesn't exist in v1
      final tables = await v1db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='budgets'",
      );
      expect(tables, isEmpty);
      await v1db.close();

      // Simulate upgrade to v2
      final v2db = await openDatabase(
        dbPath,
        version: 2,
        singleInstance: false,
        onCreate: (db, version) async {
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
        },
        onUpgrade: (db, oldVersion, newVersion) async {
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
        },
      );

      // Verify budgets table exists after upgrade
      final tablesV2 = await v2db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='budgets'",
      );
      expect(tablesV2.length, 1);
      await v2db.close();

      // Clean up
      await deleteDatabase(dbPath);
    });
  });
}
