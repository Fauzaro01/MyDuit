import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../services/financial_calculator_service.dart';
import '../utils/formatters.dart';

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

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final initial = RupiahInputFormatter.parse(_initialController.text);
    final monthly = RupiahInputFormatter.parse(_monthlyController.text);
    final rate = double.tryParse(_returnController.text) ?? 10.0;
    final years = int.tryParse(_yearsController.text) ?? 10;

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
        _buildInputField('Setoran Awal (Rp)', _initialController),
        const SizedBox(height: 12),
        _buildInputField('Setoran Rutin Bulanan (Rp)', _monthlyController),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInputField('Imbal Hasil (%/Thn)', _returnController,
                  isPercent: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInputField('Jangka Waktu (Tahun)', _yearsController,
                  isDigits: true),
            ),
          ],
        ),
        const SizedBox(height: 24),
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
          const SizedBox(height: 10),
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
      {bool isPercent = false, bool isDigits = false}) {
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
          decoration: const InputDecoration(isDense: true),
        ),
      ],
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

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final principal = RupiahInputFormatter.parse(_principalController.text);
    final rate = double.tryParse(_rateController.text) ?? 8.5;
    final months = int.tryParse(_tenureController.text) ?? 120;

    setState(() {
      _result = FinancialCalculatorService.calculateLoan(
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
        _buildField('Pokok Pinjaman (Rp)', _principalController),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildField('Suku Bunga (%/Thn)', _rateController,
                  isDecimal: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField('Tenor (Bulan)', _tenureController,
                  isDigits: true),
            ),
          ],
        ),
        const SizedBox(height: 24),
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
        ],
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool isDecimal = false, bool isDigits = false}) {
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
          decoration: const InputDecoration(isDense: true),
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

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
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
          decoration: const InputDecoration(isDense: true),
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

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final exp = RupiahInputFormatter.parse(_monthlyExpController.text);
    final age = int.tryParse(_ageController.text) ?? 28;
    final rAge = int.tryParse(_retireAgeController.text) ?? 55;
    final savings = RupiahInputFormatter.parse(_savingsController.text);
    final rate = double.tryParse(_returnController.text) ?? 8.0;

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
            _monthlyExpController),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child:
                    _buildField('Usia Saat Ini', _ageController, isDigits: true)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildField('Target Usia Pensiun', _retireAgeController,
                    isDigits: true)),
          ],
        ),
        const SizedBox(height: 12),
        _buildField('Tabungan / Portofolio Saat Ini (Rp)', _savingsController),
        const SizedBox(height: 12),
        _buildField(
            'Ekspektasi Return Investasi (%/Thn)', _returnController,
            isDigits: true),
        const SizedBox(height: 24),
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
      {bool isDigits = false}) {
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
          decoration: const InputDecoration(isDense: true),
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

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final amount = RupiahInputFormatter.parse(_amountController.text);
    final rate = double.tryParse(_inflationRateController.text) ?? 4.5;
    final years = int.tryParse(_yearsController.text) ?? 10;

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
        _buildField('Nominal Uang Saat Ini (Rp)', _amountController),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildField(
                'Estimasi Inflasi (%/Thn)',
                _inflationRateController,
                isDigits: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                'Jangka Waktu (Tahun)',
                _yearsController,
                isDigits: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
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
      {bool isDigits = false}) {
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
          decoration: const InputDecoration(isDense: true),
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
