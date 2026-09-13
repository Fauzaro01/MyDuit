import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../services/financial_advisor_service.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../widgets/transaction_detail_sheet.dart';

class FinancialAdvisorScreen extends StatefulWidget {
  const FinancialAdvisorScreen({super.key});

  @override
  State<FinancialAdvisorScreen> createState() =>
      _FinancialAdvisorScreenState();
}

class _FinancialAdvisorScreenState extends State<FinancialAdvisorScreen> {
  final TextEditingController _queryController = TextEditingController();
  String _activeQuery = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;

    final prevTransactions = txProvider.transactions.where((t) {
      return t.date.year == prevYear && t.date.month == prevMonth;
    }).toList();

    final insights = FinancialAdvisorService.analyze(
      currentMonthTransactions: txProvider.transactions,
      previousMonthTransactions: prevTransactions,
      budgets: txProvider.budgets,
      monthlyIncome: txProvider.totalIncome,
      monthlyExpense: txProvider.totalExpense,
    );

    final queryResults = _activeQuery.isNotEmpty
        ? FinancialAdvisorService.queryTransactions(
            transactions: txProvider.transactions,
            query: _activeQuery,
          )
        : <TransactionModel>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Financial Advisor & Insights'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFF6366F1), const Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 36),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI ASISTEN KEUANGAN',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Analisis anomali belanja & rekomendasi penghematan cerdas.',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Natural Query search bar
          Text('Tanya Pengeluaran Cepat', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _queryController,
            decoration: InputDecoration(
              hintText: 'Cari cepat: "makan", "kopi", "hari ini", "minggu ini"',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _activeQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _queryController.clear();
                        setState(() => _activeQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onSubmitted: (val) => setState(() => _activeQuery = val.trim()),
            onChanged: (val) => setState(() => _activeQuery = val.trim()),
          ),
          const SizedBox(height: 12),

          // Quick prompt chips
          Wrap(
            spacing: 8,
            children: [
              _buildPromptChip('hari ini'),
              _buildPromptChip('kemarin'),
              _buildPromptChip('minggu ini'),
              _buildPromptChip('makan'),
              _buildPromptChip('belanja'),
            ],
          ),
          const SizedBox(height: 20),

          if (_activeQuery.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hasil Pencarian (${queryResults.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total: ${CurrencyFormatter.format(queryResults.fold(0.0, (s, t) => s + t.amount))}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.income),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (queryResults.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Tidak ditemukan transaksi yang cocok.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...queryResults.map((tx) {
                return TransactionTile(
                  transaction: tx,
                  onTap: () => showTransactionDetail(context, tx),
                );
              }),
            const SizedBox(height: 24),
          ],

          // Insights & Anomalies
          Text('Analisis & Insight Otomatis', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          ...insights.map((ins) {
            Color accentColor;
            IconData icon;
            switch (ins.type) {
              case InsightType.anomaly:
                accentColor = const Color(0xFFEF4444);
                icon = Icons.trending_up_rounded;
                break;
              case InsightType.warning:
                accentColor = const Color(0xFFF59E0B);
                icon = Icons.warning_amber_rounded;
                break;
              case InsightType.praise:
                accentColor = const Color(0xFF10B981);
                icon = Icons.check_circle_outline_rounded;
                break;
              case InsightType.suggestion:
                accentColor = const Color(0xFF6366F1);
                icon = Icons.lightbulb_outline_rounded;
                break;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ins.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ins.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (ins.impactAmount != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '+ ${CurrencyFormatter.format(ins.impactAmount!)}',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String query) {
    return ActionChip(
      label: Text(query, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        _queryController.text = query;
        setState(() => _activeQuery = query);
      },
    );
  }
}
