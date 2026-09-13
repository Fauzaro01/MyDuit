import 'dart:math' as math;
import 'package:uuid/uuid.dart';

enum AssetType {
  cash,
  gold,
  mutualFund,
  stock,
  deposit,
  property,
  crypto,
  other,
}

extension AssetTypeExtension on AssetType {
  String get label {
    switch (this) {
      case AssetType.cash:
        return 'Kas Tunai / Tabungan';
      case AssetType.gold:
        return 'Emas Logam Mulia';
      case AssetType.mutualFund:
        return 'Reksa Dana';
      case AssetType.stock:
        return 'Saham & Pasar Modal';
      case AssetType.deposit:
        return 'Deposito Berjangka';
      case AssetType.property:
        return 'Properti & Tanah';
      case AssetType.crypto:
        return 'Kripto';
      case AssetType.other:
        return 'Aset Lainnya';
    }
  }

  String get emoji {
    switch (this) {
      case AssetType.cash:
        return '💵';
      case AssetType.gold:
        return '🪙';
      case AssetType.mutualFund:
        return '📊';
      case AssetType.stock:
        return '📈';
      case AssetType.deposit:
        return '🏦';
      case AssetType.property:
        return '🏠';
      case AssetType.crypto:
        return '🪙';
      case AssetType.other:
        return '💎';
    }
  }
}

class AssetModel {
  final String id;
  final String name;
  final AssetType type;
  final double amount;
  final String? notes;
  final DateTime updatedAt;

  AssetModel({
    String? id,
    required this.name,
    required this.type,
    required this.amount,
    this.notes,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'amount': amount,
      'notes': notes,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory AssetModel.fromMap(Map<String, dynamic> map) {
    return AssetModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: AssetType.values.firstWhere(
        (t) => t.name == (map['type'] as String? ?? 'other'),
        orElse: () => AssetType.other,
      ),
      amount: (map['amount'] as num).toDouble(),
      notes: map['notes'] as String?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  AssetModel copyWith({
    String? id,
    String? name,
    AssetType? type,
    double? amount,
    String? notes,
    DateTime? updatedAt,
  }) {
    return AssetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Estimasi nilai aset setelah [years] tahun dengan tingkat tahunan [annualRatePercent] (negatif jika depresiasi)
  double estimateValuation({required int years, required double annualRatePercent}) {
    if (years <= 0) return amount;
    final rate = annualRatePercent / 100.0;
    final factor = math.pow(1 + rate, years).toDouble();
    return factor > 0 ? (amount * factor) : 0.0;
  }
}

class NetWorthSnapshot {
  final double totalWalletBalance;
  final double totalAssets;
  final double totalReceivables;
  final double totalDebts;
  final DateTime date;

  const NetWorthSnapshot({
    required this.totalWalletBalance,
    required this.totalAssets,
    required this.totalReceivables,
    required this.totalDebts,
    required this.date,
  });

  double get grossAssets => totalWalletBalance + totalAssets + totalReceivables;
  double get totalLiabilities => totalDebts;
  double get netWorth => grossAssets - totalLiabilities;
}
