# Arsitektur & Desain Sistem MyDuit

Dokumen ini menjelaskan arsitektur teknis, pola manajemen state, mekanisme penyimpanan data, dan integrasi layanan cloud pada aplikasi MyDuit.

---

## 🏛️ Pola Arsitektur (Layered Pattern)

MyDuit mengadopsi pemisahan lapisan (Separation of Concerns) yang jelas:

```text
┌────────────────────────────────────────────────────────┐
│                   Presentation Layer                   │
│         (Screens, Widgets, BottomSheets, Dialogs)      │
└──────────────────────────▲─────────────────────────────┘
                           │ context.watch / context.read
┌──────────────────────────▼─────────────────────────────┐
│                     State Layer                        │
│          (ChangeNotifier Providers via Provider)        │
└──────────────────────────▲─────────────────────────────┘
                           │ CRUD Methods / Queries
┌──────────────────────────▼─────────────────────────────┐
│                    Service Layer                       │
│    (DatabaseService, GoogleDriveService, ExportService)│
└──────────────────────────▲─────────────────────────────┘
                           │ Model Mapping (toMap / fromMap)
┌──────────────────────────▼─────────────────────────────┐
│                  Data / Storage Layer                  │
│       (SQLite DB `myduit.db`, SharedPreferences)       │
└────────────────────────────────────────────────────────┘
```

---

## ⚡ State Management: Provider

Manajemen state menggunakan paket `provider` dengan kelas turunan `ChangeNotifier`. Provider didaftarkan secara global di `main.dart` melalui `MultiProvider`:

1. **`TransactionProvider`**:
   - Mengelola daftar transaksi untuk bulan/tahun terpilih.
   - Mengontrol total saldo, total pemasukan, total pengeluaran, dan batas anggaran per kategori.
   - Menggunakan mekanisme `_loadVersion` counter untuk mencegah *race condition* saat perpindahan bulan secara cepat.
2. **`WalletProvider`**:
   - Mengelola daftar dompet/akun keuangan, dompet aktif, dan saldo per dompet.
   - Menangani mutasi transfer antar dompet (`transferBetweenWallets`).
3. **`SavingsProvider`**:
   - Mengelola target tabungan, progres akumulasi dana, dan penambahan saldo tabungan.
4. **`DebtProvider`**:
   - Mengelola data hutang (*I Owe*) dan piutang (*Owed to Me*), status pelunasan, serta riwayat cicilan.
5. **`RecurringProvider`**:
   - Mengelola jadwal transaksi berulang (harian, mingguan, bulanan, tahunan) dan eksekusi otomatis.
6. **`CustomCategoryProvider`**:
   - Mengelola kategori kustom yang dibuat pengguna dengan emoji dan tipe pemasukan/pengeluaran.

---

## 💾 Mekanisme SQLite & Keamanan Data

- **Database Singleton**: `DatabaseService` bertindak sebagai singleton (`DatabaseService._internal()`) untuk memastikan hanya satu koneksi SQLite yang aktif.
- **WAL Mode & Checkpoint**: Menggunakan mode *Write-Ahead Logging* (WAL) untuk performa baca-tulis tinggi. Fungsi `checkpointWal()` (`PRAGMA wal_checkpoint(FULL)`) dipanggil sebelum operasi backup untuk memastikan seluruh buffer transaksi tertulis permanen ke file `.db` utama.
- **Foreign Keys**: Diaktifkan secara eksplisit pada `onConfigure` via `PRAGMA foreign_keys = ON`.
- **Proteksi Lock saat Restore**: Metode `closeDatabase()` memastikan koneksi database ditutup sepenuhnya sebelum file database ditimpa oleh data pemulihan dari Google Drive.

---

## ☁️ Google Drive Backup & Restore Pipeline

Proses backup dan restore dirancang dengan protokol multipart REST API v3:

### Pipeline Backup:
1. Panggil `DatabaseService().checkpointWal()` untuk flushing buffer WAL.
2. Baca file `myduit.db` lokal menjadi bytes stream.
3. Kirim multipart request (Metadata JSON + SQLite Binary Content) menggunakan pembatas unik (`boundary`).
4. Catat waktu backup terakhir ke `SharedPreferences`.

### Pipeline Restore:
1. Unduh metadata file backup `myduit_backup.db` dari folder Google Drive AppData / Root.
2. Unduh konten binary file.
3. Panggil `DatabaseService().closeDatabase()` untuk melepaskan file lock.
4. Timpa file database lokal di direktori `getDatabasesPath()`.
5. Pemicu reload ke semua provider aktif untuk memperbarui UI tanpa memerlukan restart paksa aplikasi.

---

## 📄 Sanitasi Dokumen Ekspor

- **PDF Export (`pdf_export_service.dart`)**:
  - Teks deskripsi dan catatan dibersihkan dari karakter emoji atau surrogate-pairs unicode sebelum dirender untuk mencegah kegagalan pembuatan dokumen pada engine font bawaan `pdf`.
- **CSV Export (`export_service.dart`)**:
  - File CSV diawali dengan Byte Order Mark UTF-8 (`﻿`) agar aplikasi spreadsheet (seperti Microsoft Excel versi Windows) membaca karakter aksen dan format teks Indonesia secara sempurna tanpa memerlukan konfigurasi encoding manual.
