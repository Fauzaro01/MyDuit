import 'package:flutter/foundation.dart';
import '../models/asset_model.dart';
import '../services/database_service.dart';

class AssetProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<AssetModel> _assets = [];
  bool _isLoading = false;

  List<AssetModel> get assets => _assets;
  bool get isLoading => _isLoading;

  double get totalAssetValue =>
      _assets.fold(0.0, (sum, a) => sum + a.amount);

  Map<AssetType, double> get assetBreakdown {
    final Map<AssetType, double> map = {};
    for (final a in _assets) {
      map[a.type] = (map[a.type] ?? 0.0) + a.amount;
    }
    return map;
  }

  Future<void> loadAssets() async {
    _isLoading = true;
    notifyListeners();
    try {
      _assets = await _db.getAllAssets();
    } catch (e) {
      debugPrint('Error loading assets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAsset(AssetModel asset) async {
    await _db.insertAsset(asset);
    _assets.insert(0, asset);
    notifyListeners();
  }

  Future<void> updateAsset(AssetModel asset) async {
    final updated = asset.copyWith(updatedAt: DateTime.now());
    await _db.updateAsset(updated);
    final idx = _assets.indexWhere((a) => a.id == updated.id);
    if (idx != -1) {
      _assets[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteAsset(String id) async {
    await _db.deleteAsset(id);
    _assets.removeWhere((a) => a.id == id);
    notifyListeners();
  }
}
