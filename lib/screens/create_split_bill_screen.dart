import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/split_bill_model.dart';
import '../providers/split_bill_provider.dart';
import '../services/split_bill_service.dart';
import '../utils/formatters.dart';

class CreateSplitBillScreen extends StatefulWidget {
  const CreateSplitBillScreen({super.key});

  @override
  State<CreateSplitBillScreen> createState() => _CreateSplitBillScreenState();
}

class _CreateSplitBillScreenState extends State<CreateSplitBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _totalController = TextEditingController();
  final _taxController = TextEditingController(text: '0');
  final _serviceController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  final _nameController = TextEditingController();

  final List<String> _participantNames = [];
  bool _isEqualSplit = true;
  final Map<String, TextEditingController> _customControllers = {};

  @override
  void dispose() {
    _titleController.dispose();
    _totalController.dispose();
    _taxController.dispose();
    _serviceController.dispose();
    _noteController.dispose();
    _nameController.dispose();
    for (final c in _customControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _addParticipant() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_participantNames.any((p) => p.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama sudah ada di daftar')),
      );
      return;
    }

    setState(() {
      _participantNames.add(name);
      _customControllers[name] = TextEditingController();
      _nameController.clear();
    });
  }

  void _removeParticipant(String name) {
    setState(() {
      _participantNames.remove(name);
      _customControllers[name]?.dispose();
      _customControllers.remove(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Patungan Tagihan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            // Title
            Text('Nama Acara / Tagihan', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Contoh: Makan Malam Bareng',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 20),

            // Total Amount
            Text('Total Nominal Tagihan', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _totalController,
              keyboardType: TextInputType.number,
              inputFormatters: CurrencyInputService.isFormatted
                  ? [RupiahInputFormatter()]
                  : null,
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nominal wajib diisi';
                if (RupiahInputFormatter.parse(v) <= 0) {
                  return 'Nominal harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Tax and Service
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pajak (%)', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _taxController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0',
                          suffixText: '%',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Service (%)', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _serviceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0',
                          suffixText: '%',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Participant Input
            Text('Anggota Patungan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Ketik nama teman...',
                    ),
                    onSubmitted: (_) => _addParticipant(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addParticipant,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  child: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Participant Chips
            if (_participantNames.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _participantNames.map((name) {
                  return Chip(
                    label: Text(name),
                    deleteIcon: const Icon(Icons.close_rounded, size: 18),
                    onDeleted: () => _removeParticipant(name),
                    backgroundColor:
                        isDark ? AppColors.cardDark : AppColors.cardAltLight,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Split Mode Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bagi Rata (Equal)', style: theme.textTheme.bodyMedium),
                  Switch(
                    value: _isEqualSplit,
                    onChanged: (val) => setState(() => _isEqualSplit = val),
                  ),
                ],
              ),
              if (!_isEqualSplit) ...[
                const SizedBox(height: 12),
                Text(
                  'Masukkan nominal per orang:',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                ..._participantNames.map((name) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            name,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _customControllers[name],
                            keyboardType: TextInputType.number,
                            inputFormatters: CurrencyInputService.isFormatted
                                ? [RupiahInputFormatter()]
                                : null,
                            decoration: const InputDecoration(
                              prefixText: 'Rp ',
                              hintText: '0',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardAltLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tambahkan minimal 1 orang teman untuk mulai membagi tagihan.',
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Note
            Text('Catatan Tambahan', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Contoh: Transfer ke BCA 1234567 a/n Fauzan',
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text(
                  'Simpan Patungan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_participantNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan anggota patungan terlebih dahulu')),
      );
      return;
    }

    final totalAmount = RupiahInputFormatter.parse(_totalController.text);
    final tax = double.tryParse(_taxController.text) ?? 0.0;
    final service = double.tryParse(_serviceController.text) ?? 0.0;

    final bill = SplitBillModel(
      title: _titleController.text.trim(),
      totalAmount: totalAmount,
      taxPercent: tax,
      servicePercent: service,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    List<SplitParticipant> participants = [];
    if (_isEqualSplit) {
      participants = SplitBillService.calculateEqualSplit(
        billId: bill.id,
        totalAmount: totalAmount,
        participantNames: _participantNames,
        taxPercent: tax,
        servicePercent: service,
      );
    } else {
      participants = _participantNames.map((name) {
        final customText = _customControllers[name]?.text ?? '0';
        final amt = RupiahInputFormatter.parse(customText);
        return SplitParticipant(
          billId: bill.id,
          name: name,
          amount: amt,
          isPaid: false,
        );
      }).toList();
    }

    final finalBill = bill.copyWith(participants: participants);
    await context.read<SplitBillProvider>().addBill(finalBill);

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
