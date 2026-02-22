import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../models/transfer_model.dart';
import '../services/database_service.dart';

class WalletProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<WalletModel> _wallets = [];
  List<WalletModel> get wallets => _wallets;

  WalletModel? _activeWallet;
  WalletModel? get activeWallet => _activeWallet;

  Map<String, double> _walletBalances = {};
  Map<String, double> get walletBalances => _walletBalances;

  double get activeWalletBalance =>
      _activeWallet != null ? (_walletBalances[_activeWallet!.id] ?? 0.0) : 0.0;

  double get totalBalance => _walletBalances.values.fold(0.0, (a, b) => a + b);

  List<TransferModel> _transfers = [];
  List<TransferModel> get transfers => _transfers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _showAllWallets = true;
  bool get showAllWallets => _showAllWallets;

  WalletProvider() {
    loadWallets();
  }

  Future<void> loadWallets() async {
    _isLoading = true;
    notifyListeners();

    _wallets = await _dbService.getAllWallets();

    // Ensure there's a default wallet
    if (_wallets.isEmpty) {
      final defaultWallet = WalletModel(
        id: 'default-wallet',
        name: 'Dompet Utama',
        emoji: '💰',
        colorValue: 0xFF0D9373,
        isDefault: true,
      );
      await _dbService.insertWallet(defaultWallet);
      _wallets = [defaultWallet];
    }

    // Set active wallet if not set
    if (_activeWallet == null) {
      _activeWallet = _wallets.firstWhere(
        (w) => w.isDefault,
        orElse: () => _wallets.first,
      );
    }

    // Reload balances
    await _loadBalances();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadBalances() async {
    final balances = <String, double>{};
    for (final wallet in _wallets) {
      balances[wallet.id] = await _dbService.getWalletBalance(wallet.id);
    }
    _walletBalances = balances;
  }

  Future<void> loadTransfers(int year, int month) async {
    _transfers = await _dbService.getTransfersByMonth(year, month);
    notifyListeners();
  }

  // ── Active wallet ──
  void setActiveWallet(WalletModel wallet) {
    _activeWallet = wallet;
    _showAllWallets = false;
    notifyListeners();
  }

  void showAll() {
    _showAllWallets = true;
    notifyListeners();
  }

  // ── Wallet CRUD ──
  Future<void> addWallet(WalletModel wallet) async {
    await _dbService.insertWallet(wallet);
    await loadWallets();
  }

  Future<void> updateWallet(WalletModel wallet) async {
    await _dbService.updateWallet(wallet);
    // Update active wallet if it's the same
    if (_activeWallet?.id == wallet.id) {
      _activeWallet = wallet;
    }
    await loadWallets();
  }

  Future<void> deleteWallet(String id) async {
    if (_wallets.length <= 1) return; // Can't delete last wallet
    final wallet = _wallets.firstWhere((w) => w.id == id);
    if (wallet.isDefault) return; // Can't delete default wallet

    await _dbService.deleteWallet(id);
    if (_activeWallet?.id == id) {
      _activeWallet = null;
      _showAllWallets = true;
    }
    await loadWallets();
  }

  // ── Transfer ──
  Future<void> transferBetweenWallets(TransferModel transfer) async {
    await _dbService.insertTransfer(transfer);
    await _loadBalances();
    notifyListeners();
  }

  Future<void> deleteTransfer(String id) async {
    await _dbService.deleteTransfer(id);
    await _loadBalances();
    notifyListeners();
  }

  // ── Refresh balances (called after transaction changes) ──
  Future<void> refreshBalances() async {
    await _loadBalances();
    notifyListeners();
  }

  WalletModel? getWalletById(String id) {
    try {
      return _wallets.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }
}
