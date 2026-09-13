# Dokumentasi Proyek MyDuit

Selamat datang di dokumentasi resmi aplikasi **MyDuit** — aplikasi manajemen dan pencatatan keuangan pribadi modern berbasis **Flutter** untuk platform Android dan iOS.

---

## 📌 Daftar Isi Dokumentasi

1. [Arsitektur & Desain Sistem](architecture.md) — Struktur arsitektur, State Management (Provider), Database SQLite, dan Aliran Data.
2. [Panduan Fitur Aplikasi](features.md) — Penjelasan mendalam seluruh modul fitur (Transaksi, Dompet, Anggaran, Tabungan, Hutang/Piutang, Transaksi Berulang, Backup).
3. [Skema Database & Migrasi](database_schema.md) — Detail tabel SQLite, relasi, foreign key, dan riwayat migrasi (v1 s.d. v6).
4. [Pemecahan Masalah & FAQ](troubleshooting_and_faq.md) — Panduan penanganan kendala umum, formatting Rupiah, dan integrasi Google Drive.

---

## 🚀 Sekilas Tentang MyDuit

MyDuit dirancang dengan fokus pada:
- **Keamanan & Privasi Penuh**: Seluruh data tersimpan secara lokal (*offline-first*) di perangkat pengguna menggunakan SQLite.
- **Kemudahan Sinkronisasi Cloud**: Opsi pencadangan dan pemulihan data terenkripsi ke Google Drive pengguna tanpa perantara server pihak ketiga.
- **Pengalaman Pengguna Interaktif**: Desain antarmuka modern dengan dukungan Dark/Light mode dinamis, animasi halus, dan visualisasi grafik (*fl_chart*).
- **Format Lokal Indonesia**: Dukungan input cerdas mata uang Rupiah (`Rp`), pemisah ribuan otomatis, dan ekspor data yang kompatibel dengan Microsoft Excel.

---

## 🛠️ Tech Stack & Dependensi Utama

| Kategori | Teknologi / Paket | Kegunaan |
|---|---|---|
| **Framework** | Flutter (Dart SDK ^3.0.0) | Multi-platform UI Toolkit |
| **State Management** | `provider` | State container reaktif & Dependency Injection |
| **Database Lokal** | `sqflite`, `path` | SQLite database dengan WAL mode & Foreign Keys |
| **Visualisasi Data** | `fl_chart` | Grafik tren harian (Line Chart) & proporsi pengeluaran (Pie Chart) |
| **Pencadangan Cloud** | `googleapis`, `google_sign_in`, `http` | Integrasi REST API v3 Google Drive Multipart |
| **Autentikasi Biometrik** | `local_auth` | Proteksi kunci aplikasi dengan Fingerprint / Face Unlock |
| **Ekspor Dokumen** | `pdf`, `csv`, `printing`, `share_plus` | Ekspor laporan PDF tersanitasi & CSV dengan UTF-8 BOM |
| **Penyimpanan Preferensi**| `shared_preferences` | Penyimpanan pengaturan tema, preferensi format, dan jadwal |
| **Animasi** | `flutter_animate` | Micro-interaction dan transisi elemen UI |

---

## 📂 Struktur Direktori Proyek

```text
MyDuit/
├── docs/                        # Dokumentasi teknis dan fungsional
│   ├── README.md                # Indeks dokumentasi utama
│   ├── architecture.md          # Dokumen arsitektur teknis
│   ├── features.md              # Rincian fungsional fitur
│   ├── database_schema.md       # Skema database & riwayat migrasi
│   └── troubleshooting_and_faq.md # Panduan pemecahan masalah
├── lib/
│   ├── config/                  # Konfigurasi tema warna & tipografi (AppColors, AppTheme)
│   ├── models/                  # Data class & model SQLite
│   ├── providers/               # State management ChangeNotifier (Provider)
│   ├── screens/                 # Tampilan UI / Halaman aplikasi
│   ├── services/                # Layanan backend (Database, Google Drive, Ekspor)
│   ├── utils/                   # Formatters, konstanta tanggal, helper Rupiah
│   ├── widgets/                 # Reusable UI component & Bottom sheets
│   └── main.dart                # Entry point aplikasi & inisialisasi MultiProvider
└── pubspec.yaml                 # Konfigurasi dependensi dan asset
```

---

## 🏃 Menjalankan Proyek Secara Lokal

### Prasyarat
- Flutter SDK (versi 3.16 atau lebih baru disarankan)
- Android Studio / VS Code dengan ekstensi Dart & Flutter
- Emulator Android / iOS atau perangkat fisik aktif

### Langkah Menjalankan
```bash
# 1. Clone repository
git clone https://github.com/Fauzaro01/MyDuit.git

# 2. Masuk ke direktori proyek
cd MyDuit

# 3. Ambil seluruh dependensi
flutter pub get

# 4. Jalankan aplikasi pada perangkat/emulator
flutter run
```
