import 'package:uuid/uuid.dart';
import 'transaction_model.dart';

class InstallmentModel {
  final String id;
  final String title;
  final double totalPrincipal; // Total harga barang / pokok pinjaman
  final double monthlyPayment;  // Cicilan per bulan
  final int totalTenorMonths;  // Durasi tenor (misal 3, 6, 12, 24)
  final int paidTenorMonths;   // Berapa bulan sudah terbayar (misal 4 dari 12)
  final double interestRatePercent; // Suku bunga total / flat (misal 0% atau 5%)
  final DateTime startDate;
  final int dueDay;            // Tanggal jatuh tempo per bulan (1-31)
  final String? walletId;
  final TransactionCategory category;
  final String? notes;

  InstallmentModel({
    String? id,
    required this.title,
    required this.totalPrincipal,
    required this.monthlyPayment,
    required this.totalTenorMonths,
    this.paidTenorMonths = 0,
    this.interestRatePercent = 0.0,
    DateTime? startDate,
    this.dueDay = 1,
    this.walletId,
    this.category = TransactionCategory.bills,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        startDate = startDate ?? DateTime.now();

  bool get isCompleted => paidTenorMonths >= totalTenorMonths;
  int get remainingTenorMonths => (totalTenorMonths - paidTenorMonths).clamp(0, totalTenorMonths);
  double get totalRemainingAmount => monthlyPayment * remainingTenorMonths;
  double get totalPaidAmount => monthlyPayment * paidTenorMonths;
  double get progressPercentage => totalTenorMonths > 0
      ? (paidTenorMonths / totalTenorMonths).clamp(0.0, 1.0)
      : 1.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'totalPrincipal': totalPrincipal,
      'monthlyPayment': monthlyPayment,
      'totalTenorMonths': totalTenorMonths,
      'paidTenorMonths': paidTenorMonths,
      'interestRatePercent': interestRatePercent,
      'startDate': startDate.millisecondsSinceEpoch,
      'dueDay': dueDay,
      'walletId': walletId,
      'category': category.index,
      'notes': notes,
    };
  }

  factory InstallmentModel.fromMap(Map<String, dynamic> map) {
    return InstallmentModel(
      id: map['id'] as String,
      title: map['title'] as String,
      totalPrincipal: (map['totalPrincipal'] as num).toDouble(),
      monthlyPayment: (map['monthlyPayment'] as num).toDouble(),
      totalTenorMonths: map['totalTenorMonths'] as int,
      paidTenorMonths: map['paidTenorMonths'] as int? ?? 0,
      interestRatePercent: (map['interestRatePercent'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.fromMillisecondsSinceEpoch(
        map['startDate'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      dueDay: map['dueDay'] as int? ?? 1,
      walletId: map['walletId'] as String?,
      category: TransactionCategory.values[
          map['category'] as int? ?? TransactionCategory.bills.index],
      notes: map['notes'] as String?,
    );
  }

  InstallmentModel copyWith({
    String? id,
    String? title,
    double? totalPrincipal,
    double? monthlyPayment,
    int? totalTenorMonths,
    int? paidTenorMonths,
    double? interestRatePercent,
    DateTime? startDate,
    int? dueDay,
    String? walletId,
    TransactionCategory? category,
    String? notes,
  }) {
    return InstallmentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      totalPrincipal: totalPrincipal ?? this.totalPrincipal,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      totalTenorMonths: totalTenorMonths ?? this.totalTenorMonths,
      paidTenorMonths: paidTenorMonths ?? this.paidTenorMonths,
      interestRatePercent: interestRatePercent ?? this.interestRatePercent,
      startDate: startDate ?? this.startDate,
      dueDay: dueDay ?? this.dueDay,
      walletId: walletId ?? this.walletId,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }
}
