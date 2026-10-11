import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../services/financial_calculator_service.dart';
import '../utils/formatters.dart';

/// Validates a Rupiah-formatted amount field (supports shorthand like
/// "5jt"). Returns an error message, or null if the value is usable.
String? _amountFieldError(String text) {
  if (text.trim().isEmpty) return 'Wajib diisi';
  if (RupiahInputFormatter.parse(text) <= 0) return 'Harus lebih dari 0';
  return null;
}

/// Validates a plain numeric field (percent, years, age — no Rupiah
/// grouping). [min] defaults to 0 and is exclusive.
String? _plainFieldError(String text, {double min = 0}) {
  if (text.trim().isEmpty) return 'Wajib diisi';
  final value = double.tryParse(text.trim());
  if (value == null) return 'Angka tidak valid';
  if (value <= min) return 'Harus > $min';
  return null;
}

class FinancialCalculatorScreen extends StatefulWidget {
  const FinancialCalculatorScreen({super.key});

  @override
  State<FinancialCalculatorScreen> createState() =>
      _FinancialCalculatorScreenState();
}

class _FinancialCalculatorScreenState extends State<FinancialCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator Finansial 🧮'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          unselectedLabelColor: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          indicatorColor:
              isDark ? AppColors.primaryDark : AppColors.primaryLight,
          tabs: const [
            Tab(text: '📈 Investasi'),
            Tab(text: '🏠 Pinjaman/KPR'),
            Tab(text: '🛡️ Dana Darurat'),
            Tab(text: '🏖️ Pensiun (FIRE)'),
            Tab(text: '📉 Inflasi & Daya Beli'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CompoundInterestTab(),
          _LoanCalculatorTab(),
          _EmergencyFundTab(),
          _RetirementTab(),
          _InflationCalculatorTab(),
        ],
      ),
    );
  }
}

// ── 1. COMPOUND INTEREST TAB ──────────────────────────────
class _CompoundInterestTab extends StatefulWidget {
  const _CompoundInterestTab();

  @override
  State<_CompoundInterestTab> createState() => _CompoundInterestTabState();
}

class _CompoundInterestTabState extends State<_CompoundInterestTab> {
  final _initialController = TextEditingController(text: '10000000');
  final _monthlyController = TextEditingController(text: '1000000');
  final _returnController = TextEditingController(text: '10');
  final _yearsController = TextEditingController(text: '10');

  CompoundInterestResult? _result;
  String? _initialError;
  String? _returnError;
  String? _yearsError;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    // Monthly deposit may legitimately be 0 (lump-sum only), so it has no
    // "> 0" requirement — only the initial deposit, rate and years do.
    _initialError = _amountFieldError(_initialController.text);
    _returnError = _plainFieldError(_returnController.text, min: -100);
    _yearsError = _plainFieldError(_yearsController.text);

    if (_initialError != null || _returnError != null || _yearsError != null) {
      setState(() => _result = null);
      return;
    }

    final initial = RupiahInputFormatter.parse(_initialController.text);
    final monthly = RupiahInputFormatter.parse(_monthlyController.text);
    final rate = double.parse(_returnController.text.trim());
    final years = double.parse(_yearsController.text.trim()).toInt();

    setState(() {
      _result = FinancialCalculatorService.calculateCompoundInterest(
        initialDeposit: initial,
        monthlyDeposit: monthly,
        annualInterestRatePercent: rate,
        years: years,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final res = _result;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInputField('Setoran Awal (Rp)', _initialController, errorText: _initialError),
        const SizedBox(height: 12),
        _buildInputField('Setoran Rutin Bulanan (Rp)', _monthlyController),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInputField('Imbal Hasil (%/Thn)', _returnController,
                  isPercent: true, errorText: _returnError),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInputField('Jangka Waktu (Tahun)', _yearsController,
                  isDigits: true, errorText: _yearsError),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (res == null) ...[
          Text(
            'Lengkapi input di atas untuk melihat hasil.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
        if (res != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFF0D9373), const Color(0xFF05614C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimasi Nilai Masa Depan',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.format(res.futureValue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ResultColumn(
                      label: 'Total Modal',
                      value: CurrencyFormatter.formatCompact(res.totalPrincipal),
                    ),
                    _ResultColumn(
                      label: 'Total Imbal Hasil',
                      value: CurrencyFormatter.formatCompact(res.totalInterest),
                      valueColor: const Color(0xFF34D399),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Proyeksi Pertumbuhan Tahunan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _YearlyGrowthChart(breakdown: res.yearlyBreakdown, isDark: isDark),
          const SizedBox(height: 16),
          ...res.yearlyBreakdown.map((yr) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardAltLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tahun ke-${yr.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(yr.balance),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Bunga: +${CurrencyFormatter.formatCompact(yr.interestEarned)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.income,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      {bool isPercent = false, bool isDigits = false, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: isPercent || isDigits
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : CurrencyInputService.isFormatted
                  ? [RupiahInputFormatter()]
                  : [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _calculate(),
          decoration: InputDecoration(isDense: true, errorText: errorText),
        ),
      ],
    );
  }
}

/// Stacked bar chart of yearly growth: principal deposited vs interest
/// earned, one bar per year.
class _YearlyGrowthChart extends StatelessWidget {
  final List<YearlyGrowth> breakdown;
  final bool isDark;

  const _YearlyGrowthChart({required this.breakdown, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) return const SizedBox.shrink();
    final maxBalance = breakdown.map((y) => y.balance).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxBalance * 1.15,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= breakdown.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Y${breakdown[idx].year}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final yr = breakdown[groupIndex];
                return BarTooltipItem(
                  'Tahun ${yr.year}\n${CurrencyFormatter.formatCompact(yr.totalDeposits)} modal\n+${CurrencyFormatter.formatCompact(yr.interestEarned)} bunga',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          barGroups: breakdown.asMap().entries.map((entry) {
            final yr = entry.value;
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: yr.balance,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                  rodStackItems: [
                    BarChartRodStackItem(0, yr.totalDeposits, const Color(0xFF0D9373)),
                    BarChartRodStackItem(yr.totalDeposits, yr.balance, const Color(0xFF34D399)),
                  ],
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── 2. LOAN / MORTGAGE TAB ────────────────────────────────
class _LoanCalculatorTab extends StatefulWidget {
  const _LoanCalculatorTab();

  @override
  State<_LoanCalculatorTab> createState() => _LoanCalculatorTabState();
}

class _LoanCalculatorTabState extends State<_LoanCalculatorTab> {
  final _principalController = TextEditingController(text: '300000000');
  final _rateController = TextEditingController(text: '8.5');
  final _tenureController = TextEditingController(text: '120'); // 10 years

  LoanCalculationResult? _result;
  List<AmortizationYear> _schedule = [];
  bool _showSchedule = false;
  String? _principalError;
  String? _rateError;
  String? _tenureError;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    _principalError = _amountFieldError(_principalController.text);
    _rateError = _plainFieldError(_rateController.text, min: -1);
    _tenureError = _plainFieldError(_tenureController.text);

    if (_principalError != null || _rateError != null || _tenureError != null) {
      setState(() {
        _result = null;
        _schedule = [];
      });
      return;
    }

    final principal = RupiahInputFormatter.parse(_principalController.text);
    final rate = double.parse(_rateController.text.trim());
    final months = double.parse(_tenureController.text.trim()).toInt();

    setState(() {
      _result = FinancialCalculatorService.calculateLoan(
        principal: principal,
        annualInterestRatePercent: rate,
        tenureMonths: months,
      );
      _schedule = FinancialCalculatorService.calculateAmortizationSchedule(
        principal: principal,
        annualInterestRatePercent: rate,
        tenureMonths: months,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final res = _result;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildField('Pokok Pinjaman (Rp)', _principalController, errorText: _principalError),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildField('Suku Bunga (%/Thn)', _rateController,
                  isDecimal: true, errorText: _rateError),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField('Tenor (Bulan)', _tenureController,
                  isDigits: true, errorText: _tenureError),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (res == null) ...[
          Text(
            'Lengkapi input di atas untuk melihat hasil.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
        if (res != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardAltLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cicilan Bulanan',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.format(res.monthlyPayment),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.expense,
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ResultColumn(
                      label: 'Total Bunga',
                      value: CurrencyFormatter.formatCompact(res.totalInterest),
                      valueColor: Colors.orange,
                    ),
                    _ResultColumn(
                      label: 'Total Pembayaran',
                      value: CurrencyFormatter.formatCompact(res.totalPayment),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => setState(() => _showSchedule = !_showSchedule),
            icon: Icon(_showSchedule ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            label: Text(_showSchedule ? 'Sembunyikan Rincian per Tahun' : 'Lihat Rincian per Tahun'),
          ),
          if (_showSchedule)
            ..._schedule.map((yr) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardAltLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tahun ke-${yr.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Sisa: ${CurrencyFormatter.formatCompact(yr.remainingBalance)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          Text(
                            'Pokok ${CurrencyFormatter.formatCompact(yr.principalPaid)} · Bunga ${CurrencyFormatter.formatCompact(yr.interestPaid)}',
                            style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
        ],
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool isDecimal = false, bool isDigits = false, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: isDecimal || isDigits
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : CurrencyInputService.isFormatted
                  ? [RupiahInputFormatter()]
                  : [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _calculate(),
          decoration: InputDecoration(isDense: true, errorText: errorText),
        ),
      ],
    );
  }
}

// ── 3. EMERGENCY FUND TAB ─────────────────────────────────
class _EmergencyFundTab extends StatefulWidget {
  const _EmergencyFundTab();

  @override
  State<_EmergencyFundTab> createState() => _EmergencyFundTabState();
}

class _EmergencyFundTabState extends State<_EmergencyFundTab> {
  final _expenseController = TextEditingController(text: '5000000');
  bool _isMarried = false;
  int _dependents = 0;
  bool _isFreelancer = false;
  EmergencyFundResult? _result;
  String? _expenseError;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    _expenseError = _amountFieldError(_expenseController.text);
    if (_expenseError != null) {
      setState(() => _result = null);
      return;
    }

    final exp = RupiahInputFormatter.parse(_expenseController.text);
    setState(() {
      _result = FinancialCalculatorService.calculateEmergencyFund(
        monthlyExpense: exp,
        isMarried: _isMarried,
        dependentsCount: _dependents,
        isFreelancer: _isFreelancer,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final res = _result;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Pengeluaran Bulanan Rutin (Rp)',
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: _expenseController,
          keyboardType: TextInputType.number,
          inputFormatters: CurrencyInputService.isFormatted
              ? [RupiahInputFormatter()]
              : [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _calculate(),
          decoration: InputDecoration(isDense: true, errorText: _expenseError),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Status Menikah'),
          value: _isMarried,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            setState(() => _isMarried = val);
            _calculate();
          },
        ),
        SwitchListTile(
          title: const Text('Pekerja Lepas / Freelancer'),
          subtitle: const Text('Pendapatan fluktuatif butuh buffer lebih'),
          value: _isFreelancer,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            setState(() => _isFreelancer = val);
            _calculate();
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Jumlah Tanggungan (Anak/Ortu)'),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _dependents > 0
                      ? () {
                          setState(() => _dependents--);
                          _calculate();
                        }
                      : null,
                ),
                Text('$_dependents',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    setState(() => _dependents++);
                    _calculate();
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (res == null) ...[
          Text(
            'Lengkapi input di atas untuk melihat hasil.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
        if (res != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardAltLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target Dana Darurat (${res.recommendedMonths} Bulan)',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.format(res.targetAmount),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  res.recommendation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── 4. RETIREMENT / FIRE TAB ──────────────────────────────
class _RetirementTab extends StatefulWidget {
  const _RetirementTab();

  @override
  State<_RetirementTab> createState() => _RetirementTabState();
}

class _RetirementTabState extends State<_RetirementTab> {
  final _monthlyExpController = TextEditingController(text: '7000000');
  final _ageController = TextEditingController(text: '28');
  final _retireAgeController = TextEditingController(text: '55');
  final _savingsController = TextEditingController(text: '50000000');
  final _returnController = TextEditingController(text: '8');

  RetirementResult? _result;
  String? _expError;
  String? _ageError;
  String? _retireAgeError;
  String? _returnError;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    _expError = _amountFieldError(_monthlyExpController.text);
    _ageError = _plainFieldError(_ageController.text);
    _retireAgeError = _plainFieldError(_retireAgeController.text);
    _returnError = _plainFieldError(_returnController.text, min: -100);

    // Savings may be 0 (starting from scratch), so no amount-field check.
    if (_retireAgeError == null && _ageError == null) {
      final age = double.parse(_ageController.text.trim()).toInt();
      final rAge = double.parse(_retireAgeController.text.trim()).toInt();
      if (rAge <= age) _retireAgeError = 'Harus > usia saat ini';
    }

    if (_expError != null || _ageError != null || _retireAgeError != null || _returnError != null) {
      setState(() => _result = null);
      return;
    }

    final exp = RupiahInputFormatter.parse(_monthlyExpController.text);
    final age = double.parse(_ageController.text.trim()).toInt();
    final rAge = double.parse(_retireAgeController.text.trim()).toInt();
    final savings = RupiahInputFormatter.parse(_savingsController.text);
    final rate = double.parse(_returnController.text.trim());

    setState(() {
      _result = FinancialCalculatorService.calculateRetirement(
        currentMonthlyExpense: exp,
        currentAge: age,
        targetRetirementAge: rAge,
        currentSavings: savings,
        expectedAnnualReturnPercent: rate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final res = _result;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildField('Estimasi Pengeluaran Bulanan Pensiun (Rp)',
            _monthlyExpController, errorText: _expError),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildField('Usia Saat Ini', _ageController,
                    isDigits: true, errorText: _ageError)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildField('Target Usia Pensiun', _retireAgeController,
                    isDigits: true, errorText: _retireAgeError)),
          ],
        ),
        const SizedBox(height: 12),
        _buildField('Tabungan / Portofolio Saat Ini (Rp)', _savingsController),
        const SizedBox(height: 12),
        _buildField(
            'Ekspektasi Return Investasi (%/Thn)', _returnController,
            isDigits: true, errorText: _returnError),
        const SizedBox(height: 24),
        if (res == null) ...[
          Text(
            'Lengkapi input di atas untuk melihat hasil.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
        if (res != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                    : [const Color(0xFF4F46E5), const Color(0xFF3730A3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Target Dana Pensiun (Metode 4% Rule)',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.format(res.targetNestEgg),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ResultColumn(
                      label: 'Tabungan/Bulan Diperlukan',
                      value: CurrencyFormatter.formatCompact(
                          res.monthlySavingsNeeded),
                      valueColor: const Color(0xFFFBBF24),
                    ),
                    _ResultColumn(
                      label: 'Sisa Waktu',
                      value: '${res.yearsToRetirement} Tahun',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool isDigits = false, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: isDigits
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : CurrencyInputService.isFormatted
                  ? [RupiahInputFormatter()]
                  : [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _calculate(),
          decoration: InputDecoration(isDense: true, errorText: errorText),
        ),
      ],
    );
  }
}

// ── 5. INFLATION & PURCHASING POWER TAB ──────────────────
class _InflationCalculatorTab extends StatefulWidget {
  const _InflationCalculatorTab();

  @override
  State<_InflationCalculatorTab> createState() => _InflationCalculatorTabState();
}

class _InflationCalculatorTabState extends State<_InflationCalculatorTab> {
  final _amountController = TextEditingController(text: '100000000');
  final _inflationRateController = TextEditingController(text: '4.5');
  final _yearsController = TextEditingController(text: '10');

  InflationResult? _result;
  String? _amountError;
  String? _rateError;
  String? _yearsError;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    _amountError = _amountFieldError(_amountController.text);
    _rateError = _plainFieldError(_inflationRateController.text, min: -100);
    _yearsError = _plainFieldError(_yearsController.text);

    if (_amountError != null || _rateError != null || _yearsError != null) {
      setState(() => _result = null);
      return;
    }

    final amount = RupiahInputFormatter.parse(_amountController.text);
    final rate = double.parse(_inflationRateController.text.trim());
    final years = double.parse(_yearsController.text.trim()).toInt();

    setState(() {
      _result = FinancialCalculatorService.calculateInflation(
        amount: amount,
        annualInflationRatePercent: rate,
        years: years,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final res = _result;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildField('Nominal Uang Saat Ini (Rp)', _amountController, errorText: _amountError),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildField(
                'Estimasi Inflasi (%/Thn)',
                _inflationRateController,
                isDigits: true,
                errorText: _rateError,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                'Jangka Waktu (Tahun)',
                _yearsController,
                isDigits: true,
                errorText: _yearsError,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (res == null) ...[
          Text(
            'Lengkapi input di atas untuk melihat hasil.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
        if (res != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF4C0519), const Color(0xFF1E1B4B)]
                    : [const Color(0xFFE11D48), const Color(0xFF9F1239)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daya Beli Riil Setelah ${res.years} Tahun',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.format(res.futurePurchasingPower),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ResultColumn(
                      label: 'Penurunan Nilai Riil',
                      value: '-${res.purchasingPowerLossPercent.toStringAsFixed(1)}%',
                      valueColor: const Color(0xFFFCA5A5),
                    ),
                    _ResultColumn(
                      label: 'Uang Pengganti Setara',
                      value: CurrencyFormatter.formatCompact(res.equivalentFutureAmount),
                      valueColor: const Color(0xFFFBBF24),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '💡 Untuk membeli barang seharga ${CurrencyFormatter.format(res.originalAmount)} hari ini, kamu butuh ${CurrencyFormatter.format(res.equivalentFutureAmount)} di masa depan.',
                  style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool isDigits = false, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: isDigits
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : CurrencyInputService.isFormatted
                  ? [RupiahInputFormatter()]
                  : [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _calculate(),
          decoration: InputDecoration(isDense: true, errorText: errorText),
        ),
      ],
    );
  }
}

class _ResultColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ResultColumn({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
