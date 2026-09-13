import 'package:flutter/foundation.dart';
import '../models/subscription_model.dart';
import '../services/database_service.dart';

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
    notifyListeners();
  }

  Future<void> updateSubscription(SubscriptionModel sub) async {
    await _db.updateSubscription(sub);
    final idx = _subscriptions.indexWhere((s) => s.id == sub.id);
    if (idx != -1) {
      _subscriptions[idx] = sub;
      notifyListeners();
    }
  }

  Future<void> deleteSubscription(String id) async {
    await _db.deleteSubscription(id);
    _subscriptions.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<void> toggleActive(SubscriptionModel sub) async {
    final updated = sub.copyWith(isActive: !sub.isActive);
    await updateSubscription(updated);
  }
}
