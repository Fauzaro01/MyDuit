# Pemecahan Masalah (Troubleshooting) & FAQ

Dokumen ini memuat panduan penanganan kendala umum dalam pengembangan dan penggunaan aplikasi MyDuit.

---

## ❓ Pertanyaan yang Sering Diajukan (FAQ)

### 1. Bagaimana cara kerja pencadangan otomatis Google Drive?
- Pencadangan otomatis berjalan saat pengguna membuka aplikasi jika interval jadwal (Mingguan = 7 hari, Bulanan = 30 hari) telah terpenuhi sejak tanggal pencadangan terakhir.
- Seluruh data SQLite dipaketkan dalam satu file database terpadu (`myduit_backup.db`).

### 2. Mengapa format Rupiah menggunakan `RupiahInputFormatter` khusus?
- Menggunakan formatter standar sering memunculkan bug kursor yang melompat ke posisi awal saat pengguna mengetik angka di tengah.
- `RupiahInputFormatter` secara dinamis menghitung offset kursor berdasarkan pertambahan pemisah ribuan (`.`) sehingga pengetikan angka berjalan mulus dan natural.

### 3. Mengapa ekspor CSV memerlukan Byte Order Mark (`﻿`)?
- Microsoft Excel secara default sering membuka file CSV dengan asumsi encoding ANSI lokal jika tidak ada BOM. Dengan menyertakan prefix UTF-8 BOM, teks Bahasa Indonesia dan format angka terbaca dengan benar tanpa karakter aneh.

---

## 🛠️ Panduan Penanganan Masalah (Troubleshooting)

### 1. Database Lock / SQLite Busy saat Restore
- **Penyebab**: Koneksi database SQLite masih terbuka saat file fisik `.db` sedang ditimpa oleh file hasil unduhan Google Drive.
- **Solusi**: Pastikan selalu memanggil `DatabaseService().closeDatabase()` sebelum melakukan penulisan byte stream ke file, lalu pemicu reload ke semua provider aktif setelah file berhasil ditulis.

### 2. Chart Assertion Error pada `fl_chart`
- **Penyebab**: `fl_chart` mewajibkan setiap `FlSpot(x, y)` memiliki nilai sumbu X yang terurut secara monoton naik (`x1 < x2 < x3`) dan tidak boleh ada nilai X yang duplikat.
- **Solusi**: Agregasi data harian dipetakan terlebih dahulu ke dalam struktur Map terurut per tanggal lokal (1..31) di lapisan Dart sebelum dikonversi menjadi daftar `List<FlSpot>`.

### 3. Font Error saat Export PDF
- **Penyebab**: Library rendering PDF standar tidak mendukung glyph emoji atau surrogate pairs Unicode tertentu pada font default TrueType.
- **Solusi**: Gunakan utilitas sanitasi teks `_cleanText()` di `pdf_export_service.dart` yang menghapus range unicode emoji sebelum teks dikirim ke widget PDF.
