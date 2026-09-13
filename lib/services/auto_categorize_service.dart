import '../models/transaction_model.dart';

class AutoCategorizeSuggestion {
  final TransactionCategory category;
  final TransactionType type;
  final double confidence;

  const AutoCategorizeSuggestion({
    required this.category,
    required this.type,
    this.confidence = 1.0,
  });
}

class AutoCategorizeService {
  static final Map<String, TransactionCategory> _foodKeywords = {
    'makan': TransactionCategory.food,
    'kopi': TransactionCategory.food,
    'coffee': TransactionCategory.food,
    'resto': TransactionCategory.food,
    'warung': TransactionCategory.food,
    'cafe': TransactionCategory.food,
    'gofood': TransactionCategory.food,
    'grabfood': TransactionCategory.food,
    'shopeefood': TransactionCategory.food,
    'indomaret': TransactionCategory.food,
    'alfamart': TransactionCategory.food,
    'starbucks': TransactionCategory.food,
    'mcd': TransactionCategory.food,
    'kfc': TransactionCategory.food,
    'bakso': TransactionCategory.food,
    'mie': TransactionCategory.food,
    'nasi': TransactionCategory.food,
    'padang': TransactionCategory.food,
    'sate': TransactionCategory.food,
    'ayam': TransactionCategory.food,
    'sarapan': TransactionCategory.food,
    'dinner': TransactionCategory.food,
    'lunch': TransactionCategory.food,
    'snack': TransactionCategory.food,
    'martabak': TransactionCategory.food,
    'jus': TransactionCategory.food,
    'boba': TransactionCategory.food,
  };

  static final Map<String, TransactionCategory> _transportKeywords = {
    'bensin': TransactionCategory.transport,
    'pertalite': TransactionCategory.transport,
    'pertamax': TransactionCategory.transport,
    'solar': TransactionCategory.transport,
    'spbu': TransactionCategory.transport,
    'parkir': TransactionCategory.transport,
    'tol': TransactionCategory.transport,
    'grab': TransactionCategory.transport,
    'gojek': TransactionCategory.transport,
    'goride': TransactionCategory.transport,
    'gocar': TransactionCategory.transport,
    'maxim': TransactionCategory.transport,
    'kereta': TransactionCategory.transport,
    'krl': TransactionCategory.transport,
    'mrt': TransactionCategory.transport,
    'lrt': TransactionCategory.transport,
    'bus': TransactionCategory.transport,
    'busway': TransactionCategory.transport,
    'transjakarta': TransactionCategory.transport,
    'tiket pesawat': TransactionCategory.transport,
    'pesawat': TransactionCategory.transport,
    'ojek': TransactionCategory.transport,
    'servis motor': TransactionCategory.transport,
    'cuci mobil': TransactionCategory.transport,
    'cuci motor': TransactionCategory.transport,
    'tambal ban': TransactionCategory.transport,
  };

  static final Map<String, TransactionCategory> _billsKeywords = {
    'listrik': TransactionCategory.bills,
    'pln': TransactionCategory.bills,
    'token': TransactionCategory.bills,
    'air': TransactionCategory.bills,
    'pdam': TransactionCategory.bills,
    'wifi': TransactionCategory.bills,
    'indihome': TransactionCategory.bills,
    'biznet': TransactionCategory.bills,
    'firstmedia': TransactionCategory.bills,
    'pulsa': TransactionCategory.bills,
    'kuota': TransactionCategory.bills,
    'paket data': TransactionCategory.bills,
    'bpjs': TransactionCategory.bills,
    'telkom': TransactionCategory.bills,
    'sewa': TransactionCategory.bills,
    'kos': TransactionCategory.bills,
    'kontrakan': TransactionCategory.bills,
    'ipl': TransactionCategory.bills,
    'maintenance': TransactionCategory.bills,
  };

  static final Map<String, TransactionCategory> _shoppingKeywords = {
    'tokopedia': TransactionCategory.shopping,
    'shopee': TransactionCategory.shopping,
    'lazada': TransactionCategory.shopping,
    'tiktok shop': TransactionCategory.shopping,
    'baju': TransactionCategory.shopping,
    'sepatu': TransactionCategory.shopping,
    'celana': TransactionCategory.shopping,
    'tas': TransactionCategory.shopping,
    'skincare': TransactionCategory.shopping,
    'makeup': TransactionCategory.shopping,
    'uniqlo': TransactionCategory.shopping,
    'h&m': TransactionCategory.shopping,
    'zara': TransactionCategory.shopping,
    'supermarket': TransactionCategory.shopping,
    'hypermart': TransactionCategory.shopping,
    'superindo': TransactionCategory.shopping,
  };

  static final Map<String, TransactionCategory> _entertainmentKeywords = {
    'bioskop': TransactionCategory.entertainment,
    'cinema': TransactionCategory.entertainment,
    'xxi': TransactionCategory.entertainment,
    'cgv': TransactionCategory.entertainment,
    'netflix': TransactionCategory.entertainment,
    'spotify': TransactionCategory.entertainment,
    'youtube': TransactionCategory.entertainment,
    'game': TransactionCategory.entertainment,
    'steam': TransactionCategory.entertainment,
    'playstation': TransactionCategory.entertainment,
    'nintendo': TransactionCategory.entertainment,
    'liburan': TransactionCategory.entertainment,
    'hotel': TransactionCategory.entertainment,
    'karaoke': TransactionCategory.entertainment,
    'konser': TransactionCategory.entertainment,
  };

  static final Map<String, TransactionCategory> _healthKeywords = {
    'obat': TransactionCategory.health,
    'apotek': TransactionCategory.health,
    'kimia farma': TransactionCategory.health,
    'k24': TransactionCategory.health,
    'dokter': TransactionCategory.health,
    'klinik': TransactionCategory.health,
    'rumah sakit': TransactionCategory.health,
    'vitamin': TransactionCategory.health,
    'lab': TransactionCategory.health,
    'rapid': TransactionCategory.health,
    'swab': TransactionCategory.health,
  };

  static final Map<String, TransactionCategory> _educationKeywords = {
    'kursus': TransactionCategory.education,
    'buku': TransactionCategory.education,
    'gramedia': TransactionCategory.education,
    'kuliah': TransactionCategory.education,
    'spp': TransactionCategory.education,
    'les': TransactionCategory.education,
    'udemy': TransactionCategory.education,
    'coursera': TransactionCategory.education,
    'seminar': TransactionCategory.education,
    'workshop': TransactionCategory.education,
  };

  static final Map<String, TransactionCategory> _incomeKeywords = {
    'gaji': TransactionCategory.salary,
    'salary': TransactionCategory.salary,
    'payroll': TransactionCategory.salary,
    'upah': TransactionCategory.salary,
    'honor': TransactionCategory.salary,
    'bonus': TransactionCategory.salary,
    'thr': TransactionCategory.salary,
    'insentif': TransactionCategory.salary,
    'dividen': TransactionCategory.investment,
    'reksadana': TransactionCategory.investment,
    'saham': TransactionCategory.investment,
    'bunga bank': TransactionCategory.investment,
    'freelance': TransactionCategory.freelance,
    'proyek': TransactionCategory.freelance,
    'side job': TransactionCategory.freelance,
    'hadiah': TransactionCategory.gift,
    'angpao': TransactionCategory.gift,
    'kado': TransactionCategory.gift,
  };

  /// Match title text to best category
  static AutoCategorizeSuggestion? suggest(String title) {
    final clean = title.toLowerCase().trim();
    if (clean.isEmpty) return null;

    // Check income keywords
    for (final entry in _incomeKeywords.entries) {
      if (clean.contains(entry.key)) {
        return AutoCategorizeSuggestion(
          category: entry.value,
          type: TransactionType.income,
        );
      }
    }

    // Check expense keywords
    final Map<String, TransactionCategory> allExpenseKeywords = {
      ..._foodKeywords,
      ..._transportKeywords,
      ..._billsKeywords,
      ..._shoppingKeywords,
      ..._entertainmentKeywords,
      ..._healthKeywords,
      ..._educationKeywords,
    };

    for (final entry in allExpenseKeywords.entries) {
      if (clean.contains(entry.key)) {
        return AutoCategorizeSuggestion(
          category: entry.value,
          type: TransactionType.expense,
        );
      }
    }

    return null;
  }
}
