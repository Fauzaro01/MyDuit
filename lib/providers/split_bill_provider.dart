import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/split_bill_model.dart';
import '../models/debt_model.dart';
import '../services/database_service.dart';
import 'debt_provider.dart';

class SplitBillProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<SplitBillModel> _bills = [];
  bool _isLoading = false;

  List<SplitBillModel> get bills => _bills;
  bool get isLoading => _isLoading;

  List<SplitBillModel> get activeBills =>
      _bills.where((b) => !b.isSettled).toList();
  List<SplitBillModel> get settledBills =>
      _bills.where((b) => b.isSettled).toList();

  SplitBillProvider() {
    loadBills();
  }

  Future<void> loadBills() async {
    _isLoading = true;
    notifyListeners();

    _bills = await _dbService.getAllSplitBills();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addBill(SplitBillModel bill) async {
    await _dbService.insertSplitBill(bill);
    await loadBills();
  }

  Future<void> updateBill(SplitBillModel bill) async {
    await _dbService.updateSplitBill(bill);
    await loadBills();
  }

  Future<void> deleteBill(String id) async {
    await _dbService.deleteSplitBill(id);
    await loadBills();
  }

  Future<void> toggleParticipantPaid(
    String billId,
    String participantId,
  ) async {
    final billIndex = _bills.indexWhere((b) => b.id == billId);
    if (billIndex == -1) return;

    final bill = _bills[billIndex];
    final pIndex = bill.participants.indexWhere((p) => p.id == participantId);
    if (pIndex == -1) return;

    final currentPaid = bill.participants[pIndex].isPaid;
    final newPaid = !currentPaid;

    await _dbService.toggleSplitParticipantPaid(participantId, newPaid);

    // Check if all participants are now paid to auto-settle
    final updatedParticipants = bill.participants.map((p) {
      if (p.id == participantId) return p.copyWith(isPaid: newPaid);
      return p;
    }).toList();

    final allPaid = updatedParticipants.every((p) => p.isPaid);
    if (allPaid != bill.isSettled) {
      await _dbService.settleSplitBill(billId, allPaid);
    }

    await loadBills();
  }

  Future<void> toggleSettleBill(String billId) async {
    final bill = _bills.where((b) => b.id == billId).firstOrNull;
    if (bill == null) return;
    final newSettled = !bill.isSettled;
    await _dbService.settleSplitBill(billId, newSettled);
    await loadBills();
  }

  /// Syncs an unpaid participant to DebtProvider as a Piutang (owed to me)
  Future<void> recordAsDebt(
    BuildContext context, {
    required String billId,
    required SplitParticipant participant,
    required String billTitle,
  }) async {
    final debtProvider = Provider.of<DebtProvider?>(context, listen: false);
    if (debtProvider == null) return;

    final newDebt = DebtModel(
      personName: participant.name,
      amount: participant.amount,
      type: DebtType.owedToMe,
      note: 'Patungan: $billTitle',
      dueDate: DateTime.now().add(const Duration(days: 7)),
    );

    await debtProvider.addDebt(newDebt);
    await _dbService.updateSplitParticipantDebtId(participant.id, newDebt.id);
    await loadBills();
  }
}
