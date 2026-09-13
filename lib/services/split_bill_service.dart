import '../models/split_bill_model.dart';
import '../utils/formatters.dart';

class SplitBillService {
  /// Calculate equal split amounts among participants
  static List<SplitParticipant> calculateEqualSplit({
    required String billId,
    required double totalAmount,
    required List<String> participantNames,
    double taxPercent = 0.0,
    double servicePercent = 0.0,
  }) {
    if (participantNames.isEmpty) return [];

    final rawGrandTotal = totalAmount * (1 + (taxPercent + servicePercent) / 100);
    final grandTotal = double.parse(rawGrandTotal.toStringAsFixed(2));
    final count = participantNames.length;
    final baseAmount = double.parse((grandTotal / count).toStringAsFixed(2));
    final totalAssigned = double.parse((baseAmount * count).toStringAsFixed(2));
    final remainder = double.parse((grandTotal - totalAssigned).toStringAsFixed(2));

    return List.generate(count, (index) {
      final amount = index == 0
          ? double.parse((baseAmount + remainder).toStringAsFixed(2))
          : baseAmount;
      return SplitParticipant(
        billId: billId,
        name: participantNames[index],
        amount: amount,
        isPaid: false,
      );
    });
  }

  /// Generate formatted summary string suitable for WhatsApp sharing
  static String generateShareSummary(SplitBillModel bill) {
    final buffer = StringBuffer();
    buffer.writeln('🧾 *RINGKASAN PATUNGAN: ${bill.title.toUpperCase()}*');
    buffer.writeln('📅 Tanggal: ${DateFormatter.fullDate(bill.date)}');
    buffer.writeln('💰 Total Tagihan: ${CurrencyFormatter.format(bill.totalAmount)}');

    if (bill.taxPercent > 0 || bill.servicePercent > 0) {
      final taxServiceStr = [
        if (bill.taxPercent > 0) 'Pajak ${bill.taxPercent.toStringAsFixed(0)}%',
        if (bill.servicePercent > 0)
          'Service ${bill.servicePercent.toStringAsFixed(0)}%',
      ].join(' + ');
      buffer.writeln('📌 Termasuk: $taxServiceStr');
    }

    buffer.writeln('\n👥 *Rincian Anggota:*');
    for (final p in bill.participants) {
      final status = p.isPaid ? '✅ (Lunas)' : '⏳ (Belum Lunas)';
      buffer.writeln('• ${p.name}: ${CurrencyFormatter.format(p.amount)} $status');
    }

    if (bill.note != null && bill.note!.isNotEmpty) {
      buffer.writeln('\n📝 *Catatan:*\n${bill.note}');
    }

    buffer.writeln('\n_Dibuat dengan MyDuit 💸_');
    return buffer.toString();
  }
}
