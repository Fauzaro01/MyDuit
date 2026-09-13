class CurrencyModel {
  final String code;
  final String symbol;
  final String name;
  final double rateToIdr;
  final DateTime lastUpdated;

  const CurrencyModel({
    required this.code,
    required this.symbol,
    required this.name,
    required this.rateToIdr,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'symbol': symbol,
      'name': name,
      'rateToIdr': rateToIdr,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory CurrencyModel.fromMap(Map<String, dynamic> map) {
    return CurrencyModel(
      code: map['code'] as String,
      symbol: map['symbol'] as String,
      name: map['name'] as String,
      rateToIdr: (map['rateToIdr'] as num).toDouble(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        map['lastUpdated'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  static final List<CurrencyModel> defaultCurrencies = [
    CurrencyModel(
      code: 'IDR',
      symbol: 'Rp',
      name: 'Rupiah Indonesia',
      rateToIdr: 1.0,
      lastUpdated: DateTime.now(),
    ),
    CurrencyModel(
      code: 'USD',
      symbol: '\$',
      name: 'US Dollar',
      rateToIdr: 16200.0,
      lastUpdated: DateTime.now(),
    ),
    CurrencyModel(
      code: 'EUR',
      symbol: '€',
      name: 'Euro',
      rateToIdr: 17500.0,
      lastUpdated: DateTime.now(),
    ),
    CurrencyModel(
      code: 'SGD',
      symbol: 'S\$',
      name: 'Singapore Dollar',
      rateToIdr: 12100.0,
      lastUpdated: DateTime.now(),
    ),
    CurrencyModel(
      code: 'MYR',
      symbol: 'RM',
      name: 'Malaysian Ringgit',
      rateToIdr: 3650.0,
      lastUpdated: DateTime.now(),
    ),
    CurrencyModel(
      code: 'JPY',
      symbol: '¥',
      name: 'Japanese Yen',
      rateToIdr: 108.0,
      lastUpdated: DateTime.now(),
    ),
    CurrencyModel(
      code: 'GBP',
      symbol: '£',
      name: 'British Pound',
      rateToIdr: 20800.0,
      lastUpdated: DateTime.now(),
    ),
    CurrencyModel(
      code: 'AUD',
      symbol: 'A\$',
      name: 'Australian Dollar',
      rateToIdr: 10500.0,
      lastUpdated: DateTime.now(),
    ),
    CurrencyModel(
      code: 'SAR',
      symbol: 'SR',
      name: 'Saudi Riyal',
      rateToIdr: 4320.0,
      lastUpdated: DateTime.now(),
    ),
  ];
}
