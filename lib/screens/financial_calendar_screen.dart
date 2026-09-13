import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/transaction_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/financial_calendar_service.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../widgets/transaction_detail_sheet.dart';

class FinancialCalendarScreen extends StatefulWidget {
  const FinancialCalendarScreen({super.key});

  @override
  State<FinancialCalendarScreen> createState() =>
      _FinancialCalendarScreenState();
}

class _FinancialCalendarScreenState extends State<FinancialCalendarScreen> {
  late int _selectedYear;
  late int _selectedMonth;
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    final txProvider = context.read<TransactionProvider>();
    _selectedYear = txProvider.selectedYear;
    _selectedMonth = txProvider.selectedMonth;
    final now = DateTime.now();
    _selectedDay = (_selectedYear == now.year && _selectedMonth == now.month)
        ? now.day
        : 1;
  }

  void _prevMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
      _selectedDay = 1;
    });
    context.read<TransactionProvider>().setMonth(_selectedYear, _selectedMonth);
  }

  void _nextMonth() {
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
      _selectedDay = 1;
    });
    context.read<TransactionProvider>().setMonth(_selectedYear, _selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final debtProvider = Provider.of<DebtProvider?>(context);
    final recProvider = Provider.of<RecurringProvider?>(context);
    final subProvider = Provider.of<SubscriptionProvider?>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final summaries = FinancialCalendarService.generateMonthSummary(
      year: _selectedYear,
      month: _selectedMonth,
      transactions: txProvider.transactions,
      debts: debtProvider?.debts ?? [],
      recurrings: recProvider?.activeRecurrings ?? [],
      subscriptions: subProvider?.activeSubscriptions ?? [],
    );

    final selectedSummary =
        _selectedDay != null ? summaries[_selectedDay!] : null;

    final firstDayOfWeek =
        DateTime(_selectedYear, _selectedMonth, 1).weekday; // 1 = Mon, 7 = Sun
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Finansial & Heatmap'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                DateFormatter.monthYear(_selectedYear, _selectedMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Day headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _DayHeader('Sen'),
              _DayHeader('Sel'),
              _DayHeader('Rab'),
              _DayHeader('Kam'),
              _DayHeader('Jum'),
              _DayHeader('Sab'),
              _DayHeader('Min'),
            ],
          ),
          const SizedBox(height: 8),

          // Heatmap grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayOffset = index - (firstDayOfWeek - 1);
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return const SizedBox.shrink();
              }

              final day = dayOffset + 1;
              final summary = summaries[day];
              final isSelected = _selectedDay == day;

              Color cellColor;
              switch (summary?.heatLevel ?? 0) {
                case 4:
                  cellColor = const Color(0xFFEF4444).withValues(alpha: 0.85);
                  break;
                case 3:
                  cellColor = const Color(0xFFF97316).withValues(alpha: 0.75);
                  break;
                case 2:
                  cellColor = const Color(0xFFFBBF24).withValues(alpha: 0.65);
                  break;
                case 1:
                  cellColor = const Color(0xFF10B981).withValues(alpha: 0.45);
                  break;
                default:
                  cellColor = isDark ? Colors.grey[850]! : Colors.grey[100]!;
              }

              return InkWell(
                onTap: () => setState(() => _selectedDay = day),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: (summary?.heatLevel ?? 0) >= 2
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                      if (summary?.hasEvents == true)
                        Positioned(
                          top: 3,
                          right: 3,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Heatmap legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Rendah ', style: TextStyle(fontSize: 10, color: Colors.grey)),
              _buildLegendBox(Colors.grey[300]!),
              _buildLegendBox(const Color(0xFF10B981).withValues(alpha: 0.45)),
              _buildLegendBox(const Color(0xFFFBBF24).withValues(alpha: 0.65)),
              _buildLegendBox(const Color(0xFFF97316).withValues(alpha: 0.75)),
              _buildLegendBox(const Color(0xFFEF4444).withValues(alpha: 0.85)),
              const Text(' Tinggi', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 20),

          // Detail selected day
          if (selectedDayDetails(selectedSummary, isDark) != null)
            selectedDayDetails(selectedSummary, isDark)!,
        ],
      ),
    );
  }

  Widget? selectedDayDetails(CalendarDaySummary? summary, bool isDark) {
    if (summary == null) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aktivitas ${DateFormatter.fullDate(summary.date)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pemasukan', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(summary.totalIncome),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.income,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pengeluaran', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(summary.totalExpense),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (summary.transactions.isEmpty &&
            summary.debtsDue.isEmpty &&
            summary.recurringsDue.isEmpty &&
            summary.subscriptionsDue.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Tidak ada transaksi atau tagihan pada tanggal ini.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ),

        ...summary.transactions.map((tx) {
          return TransactionTile(
            transaction: tx,
            onTap: () {
              showTransactionDetail(context, tx);
            },
          );
        }),
      ],
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String text;
  const _DayHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
      ),
    );
  }
}
