import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/transfer_model.dart';

void main() {
  group('TransferModel', () {
    late TransferModel transfer;
    final testDate = DateTime(2026, 3, 15);

    setUp(() {
      transfer = TransferModel(
        id: 'transfer-1',
        fromWalletId: 'wallet-a',
        toWalletId: 'wallet-b',
        amount: 500000,
        note: 'Transfer bulanan',
        date: testDate,
      );
    });

    test('creates instance with provided values', () {
      expect(transfer.id, 'transfer-1');
      expect(transfer.fromWalletId, 'wallet-a');
      expect(transfer.toWalletId, 'wallet-b');
      expect(transfer.amount, 500000);
      expect(transfer.note, 'Transfer bulanan');
      expect(transfer.date, testDate);
    });

    test('generates UUID if id not provided', () {
      final t = TransferModel(
        fromWalletId: 'w1',
        toWalletId: 'w2',
        amount: 100000,
      );
      expect(t.id, isNotEmpty);
      expect(t.id.length, greaterThan(10));
    });

    test('note is nullable', () {
      final t = TransferModel(
        fromWalletId: 'w1',
        toWalletId: 'w2',
        amount: 100000,
      );
      expect(t.note, isNull);
    });

    test('date defaults to now if not provided', () {
      final t = TransferModel(
        fromWalletId: 'w1',
        toWalletId: 'w2',
        amount: 100000,
      );
      expect(t.date, isNotNull);
      expect(t.date.difference(DateTime.now()).inSeconds.abs(), lessThan(5));
    });

    group('toMap', () {
      test('converts to map correctly', () {
        final map = transfer.toMap();
        expect(map['id'], 'transfer-1');
        expect(map['fromWalletId'], 'wallet-a');
        expect(map['toWalletId'], 'wallet-b');
        expect(map['amount'], 500000);
        expect(map['note'], 'Transfer bulanan');
        expect(map['date'], testDate.millisecondsSinceEpoch);
      });

      test('stores null note correctly', () {
        final t = TransferModel(
          id: 't2',
          fromWalletId: 'w1',
          toWalletId: 'w2',
          amount: 100000,
          date: testDate,
        );
        expect(t.toMap()['note'], isNull);
      });
    });

    group('fromMap', () {
      test('creates instance from map correctly', () {
        final map = {
          'id': 'map-transfer',
          'fromWalletId': 'from-w',
          'toWalletId': 'to-w',
          'amount': 250000.0,
          'note': 'Test note',
          'date': testDate.millisecondsSinceEpoch,
        };
        final t = TransferModel.fromMap(map);
        expect(t.id, 'map-transfer');
        expect(t.fromWalletId, 'from-w');
        expect(t.toWalletId, 'to-w');
        expect(t.amount, 250000.0);
        expect(t.note, 'Test note');
        expect(t.date, testDate);
      });

      test('handles null note from map', () {
        final map = {
          'id': 'id',
          'fromWalletId': 'w1',
          'toWalletId': 'w2',
          'amount': 100000,
          'note': null,
          'date': testDate.millisecondsSinceEpoch,
        };
        final t = TransferModel.fromMap(map);
        expect(t.note, isNull);
      });

      test('handles int amount from map', () {
        final map = {
          'id': 'id',
          'fromWalletId': 'w1',
          'toWalletId': 'w2',
          'amount': 100000,
          'note': null,
          'date': testDate.millisecondsSinceEpoch,
        };
        final t = TransferModel.fromMap(map);
        expect(t.amount, 100000.0);
        expect(t.amount, isA<double>());
      });
    });

    group('toMap/fromMap round-trip', () {
      test('preserves all data through serialization', () {
        final map = transfer.toMap();
        final restored = TransferModel.fromMap(map);
        expect(restored.id, transfer.id);
        expect(restored.fromWalletId, transfer.fromWalletId);
        expect(restored.toWalletId, transfer.toWalletId);
        expect(restored.amount, transfer.amount);
        expect(restored.note, transfer.note);
        expect(restored.date, transfer.date);
      });

      test('preserves null note through round-trip', () {
        final t = TransferModel(
          id: 'rt-1',
          fromWalletId: 'w1',
          toWalletId: 'w2',
          amount: 50000,
          date: testDate,
        );
        final restored = TransferModel.fromMap(t.toMap());
        expect(restored.note, isNull);
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        final copy = transfer.copyWith();
        expect(copy.id, transfer.id);
        expect(copy.fromWalletId, transfer.fromWalletId);
        expect(copy.toWalletId, transfer.toWalletId);
        expect(copy.amount, transfer.amount);
        expect(copy.note, transfer.note);
        expect(copy.date, transfer.date);
      });

      test('copies with changed fromWalletId', () {
        final copy = transfer.copyWith(fromWalletId: 'wallet-c');
        expect(copy.fromWalletId, 'wallet-c');
        expect(copy.toWalletId, transfer.toWalletId);
      });

      test('copies with changed toWalletId', () {
        final copy = transfer.copyWith(toWalletId: 'wallet-d');
        expect(copy.toWalletId, 'wallet-d');
        expect(copy.fromWalletId, transfer.fromWalletId);
      });

      test('copies with changed amount', () {
        final copy = transfer.copyWith(amount: 750000);
        expect(copy.amount, 750000);
      });

      test('copies with changed note', () {
        final copy = transfer.copyWith(note: 'Updated note');
        expect(copy.note, 'Updated note');
      });

      test('copies with changed date', () {
        final newDate = DateTime(2026, 4, 1);
        final copy = transfer.copyWith(date: newDate);
        expect(copy.date, newDate);
      });

      test('copies with multiple changes', () {
        final copy = transfer.copyWith(
          fromWalletId: 'new-from',
          toWalletId: 'new-to',
          amount: 999000,
        );
        expect(copy.fromWalletId, 'new-from');
        expect(copy.toWalletId, 'new-to');
        expect(copy.amount, 999000);
        expect(copy.id, transfer.id);
        expect(copy.note, transfer.note);
      });
    });
  });
}
