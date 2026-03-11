import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/models/budget_model.dart';
import 'package:myduit/models/wallet_model.dart';
import 'package:myduit/models/transfer_model.dart';

/// We test the database logic directly instead of through DatabaseService
/// since DatabaseService is a singleton. We replicate the schema and queries.
void main() {
  late Database db;

  sqfliteFfiInit();

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 3,
      onCreate: (db, version) async {
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
        await db.insert('wallets', {
          'id': 'default-wallet',
          'name': 'Dompet Utama',
          'emoji': '💰',
          'colorValue': 0xFF0D9373,
          'isDefault': 1,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  TransactionModel createTransaction({
    String? id,
    String title = 'Test',
    double amount = 50000,
    TransactionType type = TransactionType.expense,
    TransactionCategory category = TransactionCategory.food,
    DateTime? date,
    String? note,
    String? walletId = 'default-wallet',
  }) {
    return TransactionModel(
      id: id ?? 'tx-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      amount: amount,
      type: type,
      category: category,
      date: date ?? DateTime(2026, 2, 15),
      note: note,
      walletId: walletId,
    );
  }

  group('Transaction CRUD', () {
    test('insert and retrieve transaction', () async {
      final tx = createTransaction(id: 'tx-1', title: 'Makan Siang');

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
      final tx = createTransaction(id: 'tx-2', title: 'Original');
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
      final tx = createTransaction(id: 'tx-3');
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
      final tx1 = createTransaction(
        id: 'tx-a',
        title: 'Older',
        date: DateTime(2026, 2, 10),
      );
      final tx2 = createTransaction(
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
      final txFeb1 = createTransaction(
        id: 'feb-1',
        title: 'Feb Food',
        amount: 30000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime(2026, 2, 5),
      );
      final txFeb2 = createTransaction(
        id: 'feb-2',
        title: 'Feb Salary',
        amount: 5000000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        date: DateTime(2026, 2, 10),
      );
      // Insert transaction for Jan 2026
      final txJan = createTransaction(
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
      final txFeb3 = createTransaction(
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
        createTransaction(
          id: 'search-1',
          title: 'Makan Siang di Warteg',
          date: DateTime(2026, 2, 5),
          note: 'Nasi padang',
        ),
        createTransaction(
          id: 'search-2',
          title: 'Beli Kopi',
          date: DateTime(2026, 2, 10),
          note: 'Starbucks',
        ),
        createTransaction(
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
      final tx1 = createTransaction(
        id: 'daily-1',
        amount: 20000,
        date: DateTime(2026, 2, 10, 8, 0),
      );
      final tx2 = createTransaction(
        id: 'daily-2',
        amount: 30000,
        date: DateTime(2026, 2, 10, 12, 0),
      );
      final tx3 = createTransaction(
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

    test('v2 to v3 adds wallets, transfers tables and walletId column', () async {
      final dbPath =
          'schema_upgrade_v3_test_${DateTime.now().millisecondsSinceEpoch}.db';

      // Create a v2 database
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
      );

      // Insert a transaction without walletId
      await v2db.insert('transactions', {
        'id': 'old-tx',
        'title': 'Old Transaction',
        'amount': 50000.0,
        'type': 0,
        'category': 4,
        'date': DateTime(2026, 2, 15).millisecondsSinceEpoch,
        'note': null,
      });

      // Verify no wallets table in v2
      final walletTables = await v2db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='wallets'",
      );
      expect(walletTables, isEmpty);
      await v2db.close();

      // Upgrade to v3
      final v3db = await openDatabase(
        dbPath,
        version: 3,
        singleInstance: false,
        onCreate: (db, version) async {
          // Full v3 schema (won't be called during upgrade)
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
            await db.execute(
              'ALTER TABLE transactions ADD COLUMN walletId TEXT',
            );
            // Seed default wallet
            await db.insert('wallets', {
              'id': 'default-wallet',
              'name': 'Dompet Utama',
              'emoji': '💰',
              'colorValue': 0xFF0D9373,
              'isDefault': 1,
              'createdAt': DateTime.now().millisecondsSinceEpoch,
            });
            await db.execute(
              'UPDATE transactions SET walletId = ? WHERE walletId IS NULL',
              ['default-wallet'],
            );
          }
        },
      );

      // Verify wallets table exists
      final walletsTable = await v3db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='wallets'",
      );
      expect(walletsTable.length, 1);

      // Verify transfers table exists
      final transfersTable = await v3db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='transfers'",
      );
      expect(transfersTable.length, 1);

      // Verify default wallet was seeded
      final wallets = await v3db.query('wallets');
      expect(wallets.length, 1);
      expect(wallets.first['id'], 'default-wallet');
      expect(wallets.first['isDefault'], 1);

      // Verify old transactions now have walletId
      final txs = await v3db.query('transactions');
      expect(txs.length, 1);
      expect(txs.first['walletId'], 'default-wallet');

      await v3db.close();
      await deleteDatabase(dbPath);
    });
  });

  // ── Wallet CRUD ──────────────────────────────────────────
  group('Wallet CRUD', () {
    test('default wallet is seeded on creation', () async {
      final wallets = await db.query('wallets');
      expect(wallets.length, 1);
      expect(wallets.first['id'], 'default-wallet');
      expect(wallets.first['name'], 'Dompet Utama');
      expect(wallets.first['isDefault'], 1);
    });

    test('insert and retrieve wallet', () async {
      final wallet = WalletModel(
        id: 'wallet-2',
        name: 'Tabungan',
        emoji: '🏦',
        colorValue: 0xFF3B82F6,
        isDefault: false,
        createdAt: DateTime(2026, 3, 1),
      );
      await db.insert(
        'wallets',
        wallet.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final maps = await db.query(
        'wallets',
        where: 'id = ?',
        whereArgs: ['wallet-2'],
      );
      expect(maps.length, 1);
      final restored = WalletModel.fromMap(maps.first);
      expect(restored.id, 'wallet-2');
      expect(restored.name, 'Tabungan');
      expect(restored.emoji, '🏦');
      expect(restored.colorValue, 0xFF3B82F6);
      expect(restored.isDefault, isFalse);
    });

    test('update wallet', () async {
      // Update the default wallet name
      await db.update(
        'wallets',
        {'name': 'Dompet Harian'},
        where: 'id = ?',
        whereArgs: ['default-wallet'],
      );
      final maps = await db.query(
        'wallets',
        where: 'id = ?',
        whereArgs: ['default-wallet'],
      );
      expect(maps.first['name'], 'Dompet Harian');
    });

    test('delete wallet', () async {
      // Add a wallet then delete it
      final wallet = WalletModel(
        id: 'wallet-del',
        name: 'To Delete',
        createdAt: DateTime(2026, 3, 1),
      );
      await db.insert('wallets', wallet.toMap());
      await db.delete('wallets', where: 'id = ?', whereArgs: ['wallet-del']);
      final maps = await db.query(
        'wallets',
        where: 'id = ?',
        whereArgs: ['wallet-del'],
      );
      expect(maps, isEmpty);
    });

    test('getAllWallets returns ordered list (default first)', () async {
      final w2 = WalletModel(
        id: 'wallet-extra',
        name: 'Extra',
        isDefault: false,
        createdAt: DateTime(2026, 3, 1),
      );
      await db.insert('wallets', w2.toMap());
      final maps = await db.query(
        'wallets',
        orderBy: 'isDefault DESC, createdAt ASC',
      );
      expect(maps.length, 2);
      expect(maps[0]['id'], 'default-wallet');
      expect(maps[1]['id'], 'wallet-extra');
    });

    test('getDefaultWallet returns default wallet', () async {
      final maps = await db.query(
        'wallets',
        where: 'isDefault = ?',
        whereArgs: [1],
        limit: 1,
      );
      expect(maps.length, 1);
      expect(maps.first['id'], 'default-wallet');
    });

    test('getWalletById returns correct wallet', () async {
      final maps = await db.query(
        'wallets',
        where: 'id = ?',
        whereArgs: ['default-wallet'],
        limit: 1,
      );
      expect(maps.length, 1);
      expect(maps.first['name'], 'Dompet Utama');
    });

    test('getWalletById returns empty for non-existent wallet', () async {
      final maps = await db.query(
        'wallets',
        where: 'id = ?',
        whereArgs: ['non-existent'],
        limit: 1,
      );
      expect(maps, isEmpty);
    });
  });

  // ── Wallet Balance ──────────────────────────────────────
  group('Wallet Balance', () {
    setUp(() async {
      // Add a second wallet
      await db.insert('wallets', {
        'id': 'wallet-b',
        'name': 'Tabungan',
        'emoji': '🏦',
        'colorValue': 0xFF3B82F6,
        'isDefault': 0,
        'createdAt': DateTime(2026, 3, 1).millisecondsSinceEpoch,
      });
    });

    test('getWalletBalance returns 0 for empty wallet', () async {
      final incomeResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE walletId = ? AND type = ?',
        ['wallet-b', TransactionType.income.index],
      );
      final income = (incomeResult.first['total'] as num?)?.toDouble() ?? 0.0;
      final expenseResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE walletId = ? AND type = ?',
        ['wallet-b', TransactionType.expense.index],
      );
      final expense = (expenseResult.first['total'] as num?)?.toDouble() ?? 0.0;
      expect(income - expense, 0.0);
    });

    test('getWalletBalance calculates income - expense correctly', () async {
      // Add income to default-wallet
      final inc = createTransaction(
        id: 'bal-inc',
        title: 'Gaji',
        amount: 5000000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        walletId: 'default-wallet',
      );
      await db.insert('transactions', inc.toMap());

      // Add expense to default-wallet
      final exp = createTransaction(
        id: 'bal-exp',
        title: 'Makan',
        amount: 200000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        walletId: 'default-wallet',
      );
      await db.insert('transactions', exp.toMap());

      final incResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE walletId = ? AND type = ?',
        ['default-wallet', TransactionType.income.index],
      );
      final income = (incResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final expResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE walletId = ? AND type = ?',
        ['default-wallet', TransactionType.expense.index],
      );
      final expense = (expResult.first['total'] as num?)?.toDouble() ?? 0.0;

      expect(income - expense, 4800000);
    });

    test('getWalletBalance includes transfer in/out', () async {
      // Add income to default-wallet
      final inc = createTransaction(
        id: 'trf-inc',
        title: 'Gaji',
        amount: 1000000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        walletId: 'default-wallet',
      );
      await db.insert('transactions', inc.toMap());

      // Transfer 300k from default to wallet-b
      await db.insert('transfers', {
        'id': 'trf-1',
        'fromWalletId': 'default-wallet',
        'toWalletId': 'wallet-b',
        'amount': 300000.0,
        'note': null,
        'date': DateTime(2026, 2, 15).millisecondsSinceEpoch,
      });

      // Default wallet balance = 1000000 (income) - 300000 (transferOut) = 700000
      final incResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE walletId = ? AND type = ?',
        ['default-wallet', TransactionType.income.index],
      );
      final income = (incResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final expResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE walletId = ? AND type = ?',
        ['default-wallet', TransactionType.expense.index],
      );
      final expense = (expResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final trfOutResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transfers WHERE fromWalletId = ?',
        ['default-wallet'],
      );
      final trfOut = (trfOutResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final trfInResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transfers WHERE toWalletId = ?',
        ['default-wallet'],
      );
      final trfIn = (trfInResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final defaultBalance = income - expense + trfIn - trfOut;
      expect(defaultBalance, 700000);

      // Wallet-B balance = 0 (no transactions) + 300000 (transferIn) = 300000
      final incBResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE walletId = ? AND type = ?',
        ['wallet-b', TransactionType.income.index],
      );
      final incB = (incBResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final expBResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE walletId = ? AND type = ?',
        ['wallet-b', TransactionType.expense.index],
      );
      final expB = (expBResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final trfInBResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transfers WHERE toWalletId = ?',
        ['wallet-b'],
      );
      final trfInB = (trfInBResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final trfOutBResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transfers WHERE fromWalletId = ?',
        ['wallet-b'],
      );
      final trfOutB = (trfOutBResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final walletBBalance = incB - expB + trfInB - trfOutB;
      expect(walletBBalance, 300000);
    });
  });

  // ── Transfer CRUD ────────────────────────────────────────
  group('Transfer CRUD', () {
    setUp(() async {
      await db.insert('wallets', {
        'id': 'wallet-b',
        'name': 'Tabungan',
        'emoji': '🏦',
        'colorValue': 0xFF3B82F6,
        'isDefault': 0,
        'createdAt': DateTime(2026, 3, 1).millisecondsSinceEpoch,
      });
    });

    test('insert and retrieve transfer', () async {
      final transfer = TransferModel(
        id: 'xfer-1',
        fromWalletId: 'default-wallet',
        toWalletId: 'wallet-b',
        amount: 500000,
        note: 'Tabungan bulanan',
        date: DateTime(2026, 3, 15),
      );
      await db.insert(
        'transfers',
        transfer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final maps = await db.query(
        'transfers',
        where: 'id = ?',
        whereArgs: ['xfer-1'],
      );
      expect(maps.length, 1);
      final restored = TransferModel.fromMap(maps.first);
      expect(restored.id, 'xfer-1');
      expect(restored.fromWalletId, 'default-wallet');
      expect(restored.toWalletId, 'wallet-b');
      expect(restored.amount, 500000);
      expect(restored.note, 'Tabungan bulanan');
    });

    test('delete transfer', () async {
      final transfer = TransferModel(
        id: 'xfer-del',
        fromWalletId: 'default-wallet',
        toWalletId: 'wallet-b',
        amount: 100000,
        date: DateTime(2026, 3, 15),
      );
      await db.insert('transfers', transfer.toMap());
      await db.delete('transfers', where: 'id = ?', whereArgs: ['xfer-del']);
      final maps = await db.query(
        'transfers',
        where: 'id = ?',
        whereArgs: ['xfer-del'],
      );
      expect(maps, isEmpty);
    });

    test('getTransfersByWallet returns matching transfers', () async {
      final xfer1 = TransferModel(
        id: 'xfer-w1',
        fromWalletId: 'default-wallet',
        toWalletId: 'wallet-b',
        amount: 100000,
        date: DateTime(2026, 3, 10),
      );
      final xfer2 = TransferModel(
        id: 'xfer-w2',
        fromWalletId: 'wallet-b',
        toWalletId: 'default-wallet',
        amount: 50000,
        date: DateTime(2026, 3, 15),
      );
      await db.insert('transfers', xfer1.toMap());
      await db.insert('transfers', xfer2.toMap());

      final maps = await db.query(
        'transfers',
        where: 'fromWalletId = ? OR toWalletId = ?',
        whereArgs: ['default-wallet', 'default-wallet'],
        orderBy: 'date DESC',
      );
      expect(maps.length, 2);
    });

    test('getTransfersByMonth returns only transfers in range', () async {
      final xferMar = TransferModel(
        id: 'xfer-mar',
        fromWalletId: 'default-wallet',
        toWalletId: 'wallet-b',
        amount: 200000,
        date: DateTime(2026, 3, 15),
      );
      final xferFeb = TransferModel(
        id: 'xfer-feb',
        fromWalletId: 'default-wallet',
        toWalletId: 'wallet-b',
        amount: 100000,
        date: DateTime(2026, 2, 10),
      );
      await db.insert('transfers', xferMar.toMap());
      await db.insert('transfers', xferFeb.toMap());

      final start = DateTime(2026, 3, 1);
      final end = DateTime(2026, 4, 0, 23, 59, 59);
      final maps = await db.query(
        'transfers',
        where: 'date >= ? AND date <= ?',
        whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
        orderBy: 'date DESC',
      );
      expect(maps.length, 1);
      expect(maps.first['id'], 'xfer-mar');
    });

    test('deleting wallet deletes related transfers', () async {
      final xfer = TransferModel(
        id: 'xfer-cascade',
        fromWalletId: 'wallet-b',
        toWalletId: 'default-wallet',
        amount: 50000,
        date: DateTime(2026, 3, 15),
      );
      await db.insert('transfers', xfer.toMap());

      // Simulate deleteWallet logic: delete transfers then wallet
      await db.delete(
        'transfers',
        where: 'fromWalletId = ? OR toWalletId = ?',
        whereArgs: ['wallet-b', 'wallet-b'],
      );
      await db.delete('wallets', where: 'id = ?', whereArgs: ['wallet-b']);

      final transfers = await db.query('transfers');
      expect(transfers, isEmpty);
      final wallets = await db.query(
        'wallets',
        where: 'id = ?',
        whereArgs: ['wallet-b'],
      );
      expect(wallets, isEmpty);
    });
  });

  // ── Wallet-based Transaction queries ─────────────────────
  group('Wallet-based Transaction queries', () {
    setUp(() async {
      // Add second wallet
      await db.insert('wallets', {
        'id': 'wallet-b',
        'name': 'Tabungan',
        'emoji': '🏦',
        'colorValue': 0xFF3B82F6,
        'isDefault': 0,
        'createdAt': DateTime(2026, 3, 1).millisecondsSinceEpoch,
      });

      // Transactions in default wallet
      final tx1 = createTransaction(
        id: 'wtx-1',
        title: 'Gaji',
        amount: 5000000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        date: DateTime(2026, 3, 5),
        walletId: 'default-wallet',
      );
      final tx2 = createTransaction(
        id: 'wtx-2',
        title: 'Makan',
        amount: 50000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: DateTime(2026, 3, 10),
        walletId: 'default-wallet',
      );

      // Transaction in wallet-b
      final tx3 = createTransaction(
        id: 'wtx-3',
        title: 'Investasi',
        amount: 1000000,
        type: TransactionType.income,
        category: TransactionCategory.investment,
        date: DateTime(2026, 3, 15),
        walletId: 'wallet-b',
      );

      await db.insert('transactions', tx1.toMap());
      await db.insert('transactions', tx2.toMap());
      await db.insert('transactions', tx3.toMap());
    });

    test('getTransactionsByWalletAndMonth filters by wallet', () async {
      final start = DateTime(2026, 3, 1);
      final end = DateTime(2026, 4, 0, 23, 59, 59);
      final maps = await db.query(
        'transactions',
        where: 'walletId = ? AND date >= ? AND date <= ?',
        whereArgs: [
          'default-wallet',
          start.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
        ],
        orderBy: 'date DESC',
      );
      expect(maps.length, 2);
      final titles = maps.map((m) => m['title']).toSet();
      expect(titles, contains('Gaji'));
      expect(titles, contains('Makan'));
      expect(titles, isNot(contains('Investasi')));
    });

    test('getTransactionsByWalletAndMonth for second wallet', () async {
      final start = DateTime(2026, 3, 1);
      final end = DateTime(2026, 4, 0, 23, 59, 59);
      final maps = await db.query(
        'transactions',
        where: 'walletId = ? AND date >= ? AND date <= ?',
        whereArgs: [
          'wallet-b',
          start.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
        ],
        orderBy: 'date DESC',
      );
      expect(maps.length, 1);
      expect(maps.first['title'], 'Investasi');
    });

    test('getTotalByTypeWalletAndMonth returns correct sum', () async {
      final start = DateTime(2026, 3, 1);
      final end = DateTime(2026, 4, 0, 23, 59, 59);
      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND walletId = ? AND date >= ? AND date <= ?',
        [
          TransactionType.income.index,
          'default-wallet',
          start.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
        ],
      );
      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      expect(total, 5000000);
    });

    test('deleting wallet moves transactions to default', () async {
      // Simulate deleteWallet logic
      final defaultWallet = await db.query(
        'wallets',
        where: 'isDefault = ?',
        whereArgs: [1],
        limit: 1,
      );
      final defaultId = defaultWallet.first['id'] as String;

      // Move transactions from wallet-b to default
      await db.update(
        'transactions',
        {'walletId': defaultId},
        where: 'walletId = ?',
        whereArgs: ['wallet-b'],
      );

      // Delete transfers related to wallet-b
      await db.delete(
        'transfers',
        where: 'fromWalletId = ? OR toWalletId = ?',
        whereArgs: ['wallet-b', 'wallet-b'],
      );

      // Delete wallet
      await db.delete('wallets', where: 'id = ?', whereArgs: ['wallet-b']);

      // All transactions should now be in default wallet
      final txs = await db.query(
        'transactions',
        where: 'walletId = ?',
        whereArgs: ['default-wallet'],
      );
      expect(txs.length, 3); // all 3 transactions

      // No transactions in wallet-b
      final txsB = await db.query(
        'transactions',
        where: 'walletId = ?',
        whereArgs: ['wallet-b'],
      );
      expect(txsB, isEmpty);
    });
  });
}
