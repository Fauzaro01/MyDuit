# Panduan Modul & Fitur MyDuit

Dokumen ini menguraikan seluruh fitur utama yang ada pada aplikasi MyDuit.

---

## 1. 💰 Manajemen Transaksi (Income & Expense)

- **Pencatatan Cepat**: Pengguna dapat mencatat pemasukan dan pengeluaran dengan nominal, kategori, tanggal, catatan, dan pilihan dompet sumber/tujuan.
- **Dukungan Kategori Fleksibel**:
  - Kategori standar bawaan sistem (Makanan, Transportasi, Belanja, Tagihan, Gaji, dll.).
  - Kategori kustom buatan pengguna dengan ikon emoji unik.
- **Input Rupiah Cerdas**: Pemformatan instan `Rp xx.xxx` saat mengetik nominal transaksi.
- **Penyaringan & Pencarian Transaksi**: Filter berdasarkan bulan/tahun, jenis transaksi, dan pencarian teks secara langsung.

---

## 2. 👛 Manajemen Multi-Dompet (Wallets & Transfers)

- **Multi-Akun**: Buat banyak dompet untuk berbagai rekening bank, dompet digital (e-wallet), atau uang tunai (cash).
- **Saldo Terisolasi**: Setiap transaksi memotong atau menambah saldo pada dompet yang bersangkutan.
- **Transfer Antar Dompet**:
  - Fitur transfer instan untuk memindahkan saldo dari Dompet A ke Dompet B.
  - Tercatat dalam riwayat mutasi transfer tanpa merusak agregasi pemasukan/pengeluaran bulanan.
- **Proteksi Hapus Dompet**: Saat dompet dihapus, transaksi dan jadwal transaksi berulang otomatis dialihkan ke dompet default agar data tidak hilang (*no orphan records*).

---

## 3. 🎯 Target Tabungan (Savings Goals)

- **Perencanaan Tabungan**: Buat target finansial dengan target nominal dan tenggat waktu pencapaian.
- **Progres Visual**: Menampilkan persentase pencapaian dan sisa nominal yang harus dikumpulkan.
- **Penyetoran Fleksibel**: Tambah simpanan secara berkala dengan validasi batas target.
- **Status Selesai**: Penanda otomatis saat target tabungan telah berhasil dipenuhi.

---

## 4. 🤝 Hutang & Piutang (Debts & Receivables)

- **Dua Tipe Pencatatan**:
  - *Hutang Saya (I Owe)*: Kewajiban bayar kepada orang lain.
  - *Piutang Saya (Owed to Me)*: Tagihan yang belum dibayar oleh orang lain kepada kita.
- **Jatuh Tempo & Peringatan**: Notifikasi visual untuk hutang/piutang yang mendekati atau telah melewati tanggal jatuh tempo (*overdue*).
- **Cicilan Pembayaran**: Fasilitas mencatat pembayaran sebagian (*partial payment*) dengan batas maksimal sisa hutang.
- **Pelunasan Cepat**: Opsi menandai transaksi langsung lunas.

---

## 5. 🔁 Transaksi Berulang (Recurring Transactions)

- **Otomatisasi Finansial**: Jadwalkan transaksi rutin (seperti sewa bulanan, gaji berkala, tagihan internet, langganan aplikasi).
- **Pilihan Frekuensi**: Harian, Mingguan, Bulanan, dan Tahunan.
- **Generasi Cerdas**: Transaksi secara otomatis dibuat saat aplikasi dibuka jika jadwal telah jatuh tempo, dengan penanganan kalender aman untuk akhir bulan (misalnya tanggal 31 Februari/April).

---

## 6. 📊 Statistik & Laporan Visual

- **Grafik Tren Pengeluaran Harian**: Line chart interaktif (`fl_chart`) yang memetakan aktivitas pengeluaran dari tanggal 1 hingga akhir bulan.
- **Proporsi Kategori (Pie Chart)**: Menampilkan persentase pengeluaran terbesar per kategori.
- **Perbandingan Bulanan**: Menampilkan selisih pemasukan dan pengeluaran secara komprehensif.

---

## 7. ☁️ Pencadangan Google Drive & Ekspor Dokumen

- **Google Drive Backup**: Simpan database SQLite ke cloud dengan akun Google pribadi.
- **Jadwal Pencadangan**: Opsi pencadangan otomatis (Tidak Aktif, Mingguan, atau Bulanan).
- **Ekspor Laporan**:
  - **PDF**: Laporan ringkas dan daftar transaksi bulanan yang rapi dan siap cetak.
  - **CSV**: Data mentah terformat UTF-8 BOM untuk analisis di Microsoft Excel atau Google Sheets.

---

## 8. 🔒 Keamanan & Personalisasi

- **Kunci Biometrik**: Proteksi membuka aplikasi menggunakan sidik jari atau pemindai wajah.
- **Tema Gelap & Terang**: Dukungan mode tampilan yang konsisten dan nyaman di mata.

---

## 9. 💱 Engine Multi-Mata Uang & Kurs Otomatis (Multi-Currency)

- **Mata Uang Global**: Dukungan konversi IDR, USD, EUR, SGD, MYR, JPY, GBP, AUD, CNY, dan SAR.
- **Nilai Tukar Otomatis**: Pengambilan rate live via API publik dengan fallback offline dan caching persisten.
- **Dompet Valas**: Setiap dompet dapat memiliki satuan mata uang tersendiri dengan agregasi saldo otomatis ke IDR.

---

## 10. 🧾 Smart Receipt Parser (Ekstraksi Struk Belanja)

- **Deteksi Toko/Merchant**: Klasifikasi otomatis nama toko (Indomaret, Alfamart, Starbucks, SPBU, PLN, dsb.) dan kategori transaksi terkait.
- **Ekstraksi Tanggal & Nominal**: Parsing regex cerdas untuk mengenali format tanggal Indonesia dan total belanja secara presisi.
- **Aksi Cepat**: Form transaksi terisi otomatis dari hasil scan/paste teks struk belanja.

---

## 11. 👥 Modul Split Bill & Patungan Tagihan

- **Pembagian Rata & Fleksibel**: Hitung pembagian tagihan secara merata (*equal split*) dengan penyesuaian persentase pajak (tax) dan servis (service).
- **Sinkronisasi Piutang**: Integrasi langsung dengan modul Hutang/Piutang (*DebtProvider*) untuk mencatat bagian teman yang belum lunas.
- **Format WhatsApp**: Pembuat ringkasan pesan tagihan yang rapi untuk dibagikan langsung via media sosial.

---

## 12. 🩺 Smart Financial Health & Proyeksi Arus Kas

- **Skor Kesehatan Finansial (0-100)**: Penilaian komprehensif berdasarkan rasio anggaran 50/30/20 (Needs, Wants, Savings), rasio dana darurat, dan beban hutang (DTI).
- **Rekomendasi Cerdas**: Rekomendasi tindakan personal untuk memperbaiki arus kas.
- **Proyeksi Saldo 30/60/90 Hari**: Simulasi saldo masa depan berbasis rata-rata pengeluaran harian dan jadwal transaksi berulang beserta peringatan risiko defisit.

---

## 13. 📥 Data Migration Hub (Impor Mutasi Bank)

- **Preset Bank Populer**: Format parser mutasi siap pakai untuk BCA, Mandiri Livin, BRI, BNI, dan format Universal CSV.
- **Deduplikasi Cerdas**: Deteksi transaksi duplikat terhadap data transaksi yang sudah ada di database lokal.
- **Batch Ingestion**: Pratinjau dan pemilihan transaksi sebelum disimpan secara batch ke dompet tujuan.

---

## 14. 🏷️ Multi-Tagging System (#Tag / Proyek)

- **Pelabelan Fleksibel**: Setiap transaksi dapat memiliki banyak tag (misal: `#Liburan`, `#ProyekA`, `#Bisnis`).
- **Tag Selector Cerdas**: Input tag otomatis dengan auto-chip dan rekomendasi tag yang sering digunakan.
- **Pencarian Terpadu**: Transaksi dapat difilter dan dicari berdasarkan label tag.

---

## 15. 📊 Smart Budget Rollover & Multi-Threshold Alerts

- **Akumulasi Surplus Anggaran**: Sisa kuota anggaran yang tidak terpakai di bulan sebelumnya otomatis diakumulasikan ke batas anggaran bulan berjalan (*Carry-Forward*).
- **Multi-Level Threshold Alert**:
  - `Safe` (< 50% kuota)
  - `Warning` (50% - 79% kuota)
  - `Alert` (80% - 99% kuota)
  - `Exceeded` (>= 100% kuota)
- **Status Visual**: Label indikator rollover pada daftar anggaran bulanan.

---

## 16. 📅 Kalender Finansial Interaktif & Heatmap Pengeluaran

- **Peta Intensitas Belanja (Heatmap)**: Visualisasi intensitas pengeluaran harian dari hijau/tenang hingga merah menyala.
- **Marker Jatuh Tempo Terpadu**: Penanda visual titik event pada tanggal jatuh tempo hutang/piutang, transaksi berulang, dan tagihan langganan.
- **Rincian Harian**: Klik tanggal untuk melihat daftar transaksi dan mutasi pengeluaran per hari.

---

## 17. 🔁 Subscription & Fixed Bills Hub

- **Pelacakan Beban Rutin**: Kelola tagihan Netflix, Spotify, Internet, Listrik, dan Gym pass dalam satu dasbor terpusat.
- **Fixed Cost Ratio**: Kalkulasi otomatis persentase beban tetap bulanan terhadap total pemasukan rutin.
- **Siklus Fleksibel**: Dukungan siklus tagihan mingguan, bulanan, dan tahunan.

---

## 18. 💎 Net Worth Engine & Portofolio Aset Investasi

- **Konsolidasi Kekayaan Bersih**:
  $$\text{Net Worth} = (\text{Kas Dompet} + \text{Aset Investasi} + \text{Piutang}) - \text{Hutang}$$
- **Portofolio Investasi**: Catat dan pantau aset emas, saham, reksadana, deposito, kripto, properti, dan aset lainnya.
- **Komposisi Aset**: Ringkasan komposisi aset likuid vs non-likuid serta rasio liabilitas.

---

## 19. 🤖 AI Personal Financial Advisor & Anomaly Detector

- **Deteksi Anomali Pengeluaran**: Sistem otomatis mendeteksi lonjakan belanja per kategori (>35% kenaikan vs baseline).
- **Spending Velocity Tracker**: Peringatan kecepatan laju pengeluaran harian terhadap sisa hari dalam bulan.
- **Pencarian Cepat Berbasis Bahasa Alami (Natural Query Engine)**: Query pencarian instan seperti "makan", "kemarin", "minggu ini", "hari ini", "belanja".


