import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:myduit/models/asset_model.dart';
import 'package:myduit/providers/asset_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AssetProvider', () {
    test('loadAssets populates assets from the database', () async {
      final provider = AssetProvider();
      expect(provider.assets, isEmpty);

      await provider.addAsset(AssetModel(name: 'Antam 10gr', type: AssetType.gold, amount: 10000000));

      final reloaded = AssetProvider();
      await reloaded.loadAssets();
      expect(reloaded.assets.any((a) => a.name == 'Antam 10gr'), isTrue);
    });

    test('addAsset inserts at the front and updates totals', () async {
      final provider = AssetProvider();
      await provider.loadAssets();
      final before = provider.totalAssetValue;

      await provider.addAsset(AssetModel(name: 'BBCA', type: AssetType.stock, amount: 5000000));

      expect(provider.assets.first.name, 'BBCA');
      expect(provider.totalAssetValue, before + 5000000);
    });

    test('assetBreakdown groups totals by type', () async {
      final provider = AssetProvider();
      await provider.loadAssets();
      for (final a in List.of(provider.assets)) {
        await provider.deleteAsset(a.id);
      }

      await provider.addAsset(AssetModel(name: 'Gold A', type: AssetType.gold, amount: 1000000));
      await provider.addAsset(AssetModel(name: 'Gold B', type: AssetType.gold, amount: 2000000));
      await provider.addAsset(AssetModel(name: 'Stock A', type: AssetType.stock, amount: 3000000));

      final breakdown = provider.assetBreakdown;
      expect(breakdown[AssetType.gold], 3000000);
      expect(breakdown[AssetType.stock], 3000000);
    });

    test('updateAsset changes name, type and amount in place', () async {
      final provider = AssetProvider();
      await provider.loadAssets();
      final asset = await _addAndGet(provider, name: 'Reksadana X', amount: 1000000);

      await provider.updateAsset(asset.copyWith(name: 'Reksadana Y', amount: 1500000, type: AssetType.mutualFund));

      final updated = provider.assets.firstWhere((a) => a.id == asset.id);
      expect(updated.name, 'Reksadana Y');
      expect(updated.amount, 1500000);
      expect(updated.type, AssetType.mutualFund);
    });

    test('deleteAsset removes it from the list', () async {
      final provider = AssetProvider();
      await provider.loadAssets();
      final asset = await _addAndGet(provider, name: 'To Delete', amount: 100000);

      await provider.deleteAsset(asset.id);

      expect(provider.assets.any((a) => a.id == asset.id), isFalse);
    });
  });
}

Future<AssetModel> _addAndGet(
  AssetProvider provider, {
  required String name,
  required double amount,
}) async {
  final asset = AssetModel(name: name, type: AssetType.other, amount: amount);
  await provider.addAsset(asset);
  return asset;
}
