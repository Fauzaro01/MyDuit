import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/transaction_model.dart';

void main() {
  group('TransactionType', () {
    test('has income and expense values', () {
      expect(TransactionType.values.length, 2);
      expect(TransactionType.values, contains(TransactionType.income));
      expect(TransactionType.values, contains(TransactionType.expense));
    });
  });

  group('TransactionCategory', () {
    test('has 13 categories', () {
      expect(TransactionCategory.values.length, 13);
    });

    test('label returns correct Indonesian label', () {
      expect(TransactionCategory.salary.label, 'Gaji');
      expect(TransactionCategory.food.label, 'Makanan');
      expect(TransactionCategory.transport.label, 'Transportasi');
      expect(TransactionCategory.shopping.label, 'Belanja');
      expect(TransactionCategory.bills.label, 'Tagihan');
      expect(TransactionCategory.entertainment.label, 'Hiburan');
      expect(TransactionCategory.health.label, 'Kesehatan');
      expect(TransactionCategory.education.label, 'Pendidikan');
      expect(TransactionCategory.travel.label, 'Perjalanan');
      expect(TransactionCategory.other.label, 'Lainnya');
      expect(TransactionCategory.freelance.label, 'Freelance');
      expect(TransactionCategory.investment.label, 'Investasi');
      expect(TransactionCategory.gift.label, 'Hadiah');
    });

    test('icon returns emoji string for each category', () {
      for (final cat in TransactionCategory.values) {
        expect(cat.icon, isNotEmpty);
      }
      expect(TransactionCategory.salary.icon, '💰');
      expect(TransactionCategory.food.icon, '🍔');
      expect(TransactionCategory.transport.icon, '🚗');
    });

    test('isIncomeCategory returns true for income-related categories', () {
      expect(TransactionCategory.salary.isIncomeCategory, isTrue);
      expect(TransactionCategory.freelance.isIncomeCategory, isTrue);
      expect(TransactionCategory.investment.isIncomeCategory, isTrue);
      expect(TransactionCategory.gift.isIncomeCategory, isTrue);
    });

    test('isIncomeCategory returns false for expense-related categories', () {
      expect(TransactionCategory.food.isIncomeCategory, isFalse);
      expect(TransactionCategory.transport.isIncomeCategory, isFalse);
      expect(TransactionCategory.shopping.isIncomeCategory, isFalse);
      expect(TransactionCategory.bills.isIncomeCategory, isFalse);
      expect(TransactionCategory.entertainment.isIncomeCategory, isFalse);
      expect(TransactionCategory.health.isIncomeCategory, isFalse);
      expect(TransactionCategory.education.isIncomeCategory, isFalse);
      expect(TransactionCategory.travel.isIncomeCategory, isFalse);
      expect(TransactionCategory.other.isIncomeCategory, isFalse);
    });
  });

  group('TransactionModel', () {
    late TransactionModel transaction;
    final testDate = DateTime(2026, 2, 15);

    setUp(() {
      transaction = TransactionModel(
        id: 'test-id-123',
        title: 'Makan Siang',
        amount: 50000,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        date: testDate,
        note: 'Di warteg',
        walletId: 'wallet-1',
      );
    });

    test('creates instance with provided values', () {
      expect(transaction.id, 'test-id-123');
      expect(transaction.title, 'Makan Siang');
      expect(transaction.amount, 50000);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.category, TransactionCategory.food);
      expect(transaction.date, testDate);
      expect(transaction.note, 'Di warteg');
      expect(transaction.walletId, 'wallet-1');
    });

    test('generates UUID if id not provided', () {
      final tx = TransactionModel(
        title: 'Test',
        amount: 1000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        date: testDate,
      );
      expect(tx.id, isNotEmpty);
      expect(tx.id.length, greaterThan(10));
    });

    test('note is nullable', () {
      final tx = TransactionModel(
        title: 'Test',
        amount: 1000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        date: testDate,
      );
      expect(tx.note, isNull);
    });

    test('walletId is nullable', () {
      final tx = TransactionModel(
        title: 'Test',
        amount: 1000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        date: testDate,
      );
      expect(tx.walletId, isNull);
    });

    test('walletId can be set', () {
      final tx = TransactionModel(
        title: 'Test',
        amount: 1000,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        date: testDate,
        walletId: 'my-wallet',
      );
      expect(tx.walletId, 'my-wallet');
    });

    group('toMap', () {
      test('converts to map correctly', () {
        final map = transaction.toMap();

        expect(map['id'], 'test-id-123');
        expect(map['title'], 'Makan Siang');
        expect(map['amount'], 50000);
        expect(map['type'], TransactionType.expense.index);
        expect(map['category'], TransactionCategory.food.index);
        expect(map['date'], testDate.millisecondsSinceEpoch);
        expect(map['note'], 'Di warteg');
        expect(map['walletId'], 'wallet-1');
      });

      test('stores null walletId correctly', () {
        final tx = TransactionModel(
          id: 'id',
          title: 'Test',
          amount: 100,
          type: TransactionType.income,
          category: TransactionCategory.salary,
          date: testDate,
        );
        expect(tx.toMap()['walletId'], isNull);
      });

      test('stores null note correctly', () {
        final tx = TransactionModel(
          id: 'id',
          title: 'Test',
          amount: 100,
          type: TransactionType.income,
          category: TransactionCategory.salary,
          date: testDate,
        );
        expect(tx.toMap()['note'], isNull);
      });
    });

    group('fromMap', () {
      test('creates instance from map correctly', () {
        final map = {
          'id': 'map-id',
          'title': 'Gaji Bulanan',
          'amount': 5000000.0,
          'type': TransactionType.income.index,
          'category': TransactionCategory.salary.index,
          'date': testDate.millisecondsSinceEpoch,
          'note': 'Gaji Februari',
          'walletId': 'wallet-x',
        };

        final tx = TransactionModel.fromMap(map);

        expect(tx.id, 'map-id');
        expect(tx.title, 'Gaji Bulanan');
        expect(tx.amount, 5000000.0);
        expect(tx.type, TransactionType.income);
        expect(tx.category, TransactionCategory.salary);
        expect(tx.date, testDate);
        expect(tx.note, 'Gaji Februari');
        expect(tx.walletId, 'wallet-x');
      });

      test('handles null walletId from map', () {
        final map = {
          'id': 'id',
          'title': 'Test',
          'amount': 100,
          'type': 0,
          'category': 0,
          'date': testDate.millisecondsSinceEpoch,
          'note': null,
          'walletId': null,
        };
        final tx = TransactionModel.fromMap(map);
        expect(tx.walletId, isNull);
      });

      test('handles null note from map', () {
        final map = {
          'id': 'id',
          'title': 'Test',
          'amount': 100,
          'type': 0,
          'category': 0,
          'date': testDate.millisecondsSinceEpoch,
          'note': null,
        };

        final tx = TransactionModel.fromMap(map);
        expect(tx.note, isNull);
      });

      test('handles int amount from map', () {
        final map = {
          'id': 'id',
          'title': 'Test',
          'amount': 5000,
          'type': 0,
          'category': 0,
          'date': testDate.millisecondsSinceEpoch,
          'note': null,
        };

        final tx = TransactionModel.fromMap(map);
        expect(tx.amount, 5000.0);
        expect(tx.amount, isA<double>());
      });
    });

    group('toMap/fromMap round-trip', () {
      test('preserves all data through serialization', () {
        final map = transaction.toMap();
        final restored = TransactionModel.fromMap(map);

        expect(restored.id, transaction.id);
        expect(restored.title, transaction.title);
        expect(restored.amount, transaction.amount);
        expect(restored.type, transaction.type);
        expect(restored.category, transaction.category);
        expect(restored.date, transaction.date);
        expect(restored.note, transaction.note);
        expect(restored.walletId, transaction.walletId);
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        final copy = transaction.copyWith();

        expect(copy.id, transaction.id);
        expect(copy.title, transaction.title);
        expect(copy.amount, transaction.amount);
        expect(copy.type, transaction.type);
        expect(copy.category, transaction.category);
        expect(copy.date, transaction.date);
        expect(copy.note, transaction.note);
        expect(copy.walletId, transaction.walletId);
      });

      test('copies with changed title', () {
        final copy = transaction.copyWith(title: 'Makan Malam');
        expect(copy.title, 'Makan Malam');
        expect(copy.amount, transaction.amount);
      });

      test('copies with changed amount', () {
        final copy = transaction.copyWith(amount: 75000);
        expect(copy.amount, 75000);
        expect(copy.title, transaction.title);
      });

      test('copies with changed type', () {
        final copy = transaction.copyWith(type: TransactionType.income);
        expect(copy.type, TransactionType.income);
      });

      test('copies with changed category', () {
        final copy = transaction.copyWith(
          category: TransactionCategory.transport,
        );
        expect(copy.category, TransactionCategory.transport);
      });

      test('copies with changed date', () {
        final newDate = DateTime(2026, 3, 1);
        final copy = transaction.copyWith(date: newDate);
        expect(copy.date, newDate);
      });

      test('copies with changed note', () {
        final copy = transaction.copyWith(note: 'New note');
        expect(copy.note, 'New note');
      });

      test('copies with multiple changes at once', () {
        final copy = transaction.copyWith(
          title: 'Updated',
          amount: 99999,
          note: 'Updated note',
        );
        expect(copy.title, 'Updated');
        expect(copy.amount, 99999);
        expect(copy.note, 'Updated note');
        expect(copy.id, transaction.id);
      });

      test('copies with changed walletId', () {
        final copy = transaction.copyWith(walletId: 'wallet-2');
        expect(copy.walletId, 'wallet-2');
        expect(copy.title, transaction.title);
      });
    });
  });
}
