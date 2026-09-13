import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myduit/models/split_bill_model.dart';
import 'package:myduit/services/split_bill_service.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('SplitBillService', () {
    test('calculateEqualSplit divides total evenly with tax and service', () {
      // 100,000 + 10% tax + 5% service = 115,000 / 2 people = 57,500 each
      final participants = SplitBillService.calculateEqualSplit(
        billId: 'bill-1',
        totalAmount: 100000,
        participantNames: ['Fauzan', 'Budi'],
        taxPercent: 10,
        servicePercent: 5,
      );

      expect(participants.length, 2);
      expect(participants[0].name, 'Fauzan');
      expect(participants[0].amount, 57500.0);
      expect(participants[1].name, 'Budi');
      expect(participants[1].amount, 57500.0);
      expect(participants[0].isPaid, false);
    });

    test('generateShareSummary outputs clean WhatsApp markdown message', () {
      final bill = SplitBillModel(
        title: 'Makan Bareng',
        totalAmount: 100000,
        taxPercent: 10,
        participants: [
          SplitParticipant(
            billId: 'bill-1',
            name: 'Fauzan',
            amount: 55000,
            isPaid: true,
          ),
          SplitParticipant(
            billId: 'bill-1',
            name: 'Budi',
            amount: 55000,
            isPaid: false,
          ),
        ],
      );

      final summary = SplitBillService.generateShareSummary(bill);
      expect(summary, contains('RINGKASAN PATUNGAN: MAKAN BARENG'));
      expect(summary, contains('Fauzan: Rp 55.000 ✅ (Lunas)'));
      expect(summary, contains('Budi: Rp 55.000 ⏳ (Belum Lunas)'));
    });
  });
}
