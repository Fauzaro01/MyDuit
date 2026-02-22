# MyDuit 💸

**MyDuit** adalah aplikasi mobile Flutter untuk mengelola keuangan pribadi. Aplikasi ini membantu Anda melacak pengeluaran dan pendapatan, membuat anggaran, melihat insight keuangan, dan mengekspor laporan.

## Fitur

- 💰 **Tracking Transaksi**: Catat pendapatan dan pengeluaran dengan kategori lengkap
- 📊 **Visualisasi Data**: Lihat grafik dan statistik pengeluaran per kategori
- 📅 **Manajemen Anggaran**: Atur anggaran bulanan per kategori dengan tracking real-time
- 🔍 **Pencarian**: Cari transaksi berdasarkan judul atau catatan
- 🌙 **Dark Mode**: Dukungan tema gelap dan terang dengan Material 3
- 📤 **Export CSV**: Ekspor dan bagikan laporan transaksi
- 🎯 **Onboarding**: Intro singkat untuk pengguna baru
- 🌐 **Lokalisasi**: Dukungan bahasa Indonesia (id_ID)

## Teknologi & Dependencies

**Framework & UI:**

- Flutter 3.10.8+
- Material 3 Design
- Provider 6.1.2 (State Management)

**Database & Persistence:**

- SQLite (sqflite 2.4.2)
- SharedPreferences (shared_preferences 2.3.5)

**Utilities:**

- fl_chart 0.70.2 (Grafik)
- flutter_animate 4.5.2 (Animasi)
- google_fonts 6.2.1 (Typography - Plus Jakarta Sans)
- intl 0.20.2 (Lokalisasi - id_ID)
- uuid 4.5.1 (ID unik)
- path_provider 2.1.5 (File system)
- share_plus 10.1.4 (Sharing)

**Testing:**

- flutter_test
- mockito 5.4.4
- sqflite_common_ffi 2.3.4+4

## Struktur Project

```
lib/
├── main.dart                 # Entry point
├── config/
│   └── app_theme.dart       # Theme configuration (Light/Dark)
├── models/
│   ├── transaction_model.dart
│   └── budget_model.dart
├── providers/
│   ├── theme_provider.dart
│   └── transaction_provider.dart
├── services/
│   ├── database_service.dart  # SQLite operations
│   ├── export_service.dart    # CSV export
├── screens/
│   ├── main_navigation.dart   # Bottom navigation
│   ├── splash_screen.dart     # Splash screen
│   ├── onboarding_screen.dart # Intro
│   ├── add_transaction_screen.dart
│   ├── home_screen.dart
│   ├── history_screen.dart
│   ├── statistics_screen.dart
│   └── settings_screen.dart
├── widgets/
│   └── common_widgets.dart    # Reusable components
└── utils/
    └── formatters.dart        # Currency & date formatting

test/
├── config/
│   └── app_theme_test.dart
├── models/
│   ├── transaction_model_test.dart
│   └── budget_model_test.dart
├── services/
│   ├── database_service_test.dart
│   └── export_service_test.dart
├── providers/
│   ├── theme_provider_test.dart
│   └── transaction_provider_test.dart
├── screens/
│   ├── onboarding_screen_test.dart
│   ├── splash_screen_test.dart
│   └── add_transaction_screen_test.dart
├── widgets/
│   └── common_widgets_test.dart
└── widget_test.dart           # App smoke test
```

## Getting Started

### Prerequisites

- Flutter 3.10.8 atau lebih tinggi
- Dart 3.0+
- IDE (VS Code, Android Studio, atau IntelliJ)

### Installation

1. **Clone repository:**

   ```bash
   git clone https://github.com/yourusername/MyDuit.git
   cd MyDuit
   ```

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Generate Google Fonts cache (opsional):**

   ```bash
   flutter pub run google_fonts:get_fonts
   ```

4. **Run aplikasi:**
   ```bash
   flutter run
   ```

## Testing

Aplikasi dilengkapi dengan test suite komprehensif mencakup:

- **Unit tests** untuk models, services, providers, dan utilities (123+ tests)
- **Widget tests** untuk UI components (10+ tests)
- **Integration/Screen tests** untuk screens (21+ tests)
- **Total**: 194+ tests passed ✅

### Jalankan tests:

```bash
# Semua tests
flutter test

# Test specific file
flutter test test/models/transaction_model_test.dart

# Dengan coverage
flutter test --coverage
```

## Cara Penggunaan

1. **Buka aplikasi** → Lakukan onboarding singkat
2. **Tambah Transaksi** → Tekan FAB, pilih jenis (Pendapatan/Pengeluaran), isi detail
3. **Lihat History** → Tab History menampilkan semua transaksi dengan filter bulanan
4. **Analisis** → Tab Statistics menunjukkan grafik dan insight per kategori
5. **Kelola Anggaran** → Tab Settings untuk atur anggaran bulanan per kategori
6. **Export** → Bagikan laporan dalam format CSV

## Database Schema

**v2** (Latest):

- `transactions` table: id, title, amount, type, category, date, note, createdAt
- `budgets` table: id, category, monthlyLimit, year, month

## Kontribusi

Contributions welcome! Silakan:

1. Fork repository
2. Buat feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Buka Pull Request

## License

Proyek ini berlisensi MIT - lihat file LICENSE untuk detail.

## Kontak

Pertanyaan atau saran? Buat issue di repository ini atau hubungi kami melalui email.

---

**Made with ❤️ using Flutter**
