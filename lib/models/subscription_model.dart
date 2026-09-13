import 'package:uuid/uuid.dart';
import 'transaction_model.dart';

enum BillingCycle {
  monthly,
  yearly,
  weekly,
}

extension BillingCycleExtension on BillingCycle {
  String get label {
    switch (this) {
      case BillingCycle.monthly:
        return 'Bulanan';
      case BillingCycle.yearly:
        return 'Tahunan';
      case BillingCycle.weekly:
        return 'Mingguan';
    }
  }
}

class SubscriptionModel {
  final String id;
  final String name;
  final double amount;
  final BillingCycle billingCycle;
  final int dueDay; // 1 - 31 or weekday 1-7
  final String? walletId;
  final TransactionCategory category;
  final bool isActive;
  final int reminderDaysBefore;
  final String? notes;
  final DateTime createdAt;

  SubscriptionModel({
    String? id,
    required this.name,
    required this.amount,
    this.billingCycle = BillingCycle.monthly,
    required this.dueDay,
    this.walletId,
    this.category = TransactionCategory.bills,
    this.isActive = true,
    this.reminderDaysBefore = 2,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get monthlyCost {
    switch (billingCycle) {
      case BillingCycle.monthly:
        return amount;
      case BillingCycle.yearly:
        return amount / 12.0;
      case BillingCycle.weekly:
        return amount * 4.33;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'billingCycle': billingCycle.name,
      'dueDay': dueDay,
      'walletId': walletId,
      'category': category.index,
      'isActive': isActive ? 1 : 0,
      'reminderDaysBefore': reminderDaysBefore,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      billingCycle: BillingCycle.values.firstWhere(
        (c) => c.name == (map['billingCycle'] as String? ?? 'monthly'),
        orElse: () => BillingCycle.monthly,
      ),
      dueDay: map['dueDay'] as int? ?? 1,
      walletId: map['walletId'] as String?,
      category: TransactionCategory.values[map['category'] as int? ?? TransactionCategory.bills.index],
      isActive: (map['isActive'] as int? ?? 1) == 1,
      reminderDaysBefore: map['reminderDaysBefore'] as int? ?? 2,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  SubscriptionModel copyWith({
    String? id,
    String? name,
    double? amount,
    BillingCycle? billingCycle,
    int? dueDay,
    String? walletId,
    TransactionCategory? category,
    bool? isActive,
    int? reminderDaysBefore,
    String? notes,
    DateTime? createdAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      billingCycle: billingCycle ?? this.billingCycle,
      dueDay: dueDay ?? this.dueDay,
      walletId: walletId ?? this.walletId,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
