import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_model.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'transaction_provider.dart';

class SubscriptionProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<SubscriptionModel> _subscriptions = [];
  bool _isLoading = false;

  List<SubscriptionModel> get subscriptions => _subscriptions;
  List<SubscriptionModel> get activeSubscriptions =>
      _subscriptions.where((s) => s.isActive).toList();
  bool get isLoading => _isLoading;

  double get totalMonthlyCost {
    return _subscriptions
        .where((s) => s.isActive)
        .fold(0.0, (sum, s) => sum + s.monthlyCost);
  }

  Future<void> loadSubscriptions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _subscriptions = await _db.getAllSubscriptions();
    } catch (e) {
      debugPrint('Error loading subscriptions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSubscription(SubscriptionModel sub) async {
    await _db.insertSubscription(sub);
    _subscriptions.insert(0, sub);
    if (sub.isActive) {
      await NotificationService.scheduleSubscriptionReminder(sub);
    }
    notifyListeners();
  }

  Future<void> updateSubscription(SubscriptionModel sub) async {
    await _db.updateSubscription(sub);
    final idx = _subscriptions.indexWhere((s) => s.id == sub.id);
    if (idx != -1) {
      _subscriptions[idx] = sub;
      if (sub.isActive) {
        await NotificationService.scheduleSubscriptionReminder(sub);
      } else {
        await NotificationService.cancelSubscriptionReminder(sub.id);
      }
      notifyListeners();
    }
  }

  Future<void> deleteSubscription(String id) async {
    await _db.deleteSubscription(id);
    _subscriptions.removeWhere((s) => s.id == id);
    await NotificationService.cancelSubscriptionReminder(id);
    notifyListeners();
  }

  Future<void> toggleActive(SubscriptionModel sub) async {
    final updated = sub.copyWith(isActive: !sub.isActive);
    await updateSubscription(updated);
  }

  Future<void> paySubscription(
    SubscriptionModel sub, {
    required String walletId,
    required BuildContext context,
    String? note,
  }) async {
    final tx = TransactionModel(
      title: 'Langganan: ${sub.name}',
      amount: sub.amount,
      type: TransactionType.expense,
      category: sub.category,
      date: DateTime.now(),
      walletId: walletId,
      note: note ?? sub.notes ?? 'Pembayaran langganan ${sub.name}',
    );

    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    await txProvider.addTransaction(tx);
  }
}
