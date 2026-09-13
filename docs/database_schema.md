# Skema Database & Riwayat Migrasi SQLite

Aplikasi MyDuit menggunakan database SQLite lokal yang diakses melalui paket `sqflite`. File database tersimpan di path aplikasi dengan nama `myduit.db`.

---

## 📊 Daftar Tabel & Kolom

### 1. Tabel `transactions`
Menyimpan seluruh catatan transaksi pemasukan dan pengeluaran.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT PRIMARY KEY` | UUID unik transaksi |
| `title` | `TEXT NOT NULL` | Judul / deskripsi singkat transaksi |
| `amount` | `REAL NOT NULL` | Nilai nominal transaksi |
| `date` | `INTEGER NOT NULL` | Waktu transaksi dalam format timestamp Unix (milidetik) |
| `type` | `TEXT NOT NULL` | Tipe transaksi: `'income'` atau `'expense'` |
| `category` | `TEXT NOT NULL` | Nama enum kategori bawaan (misal: `'food'`, `'salary'`) |
| `note` | `TEXT` | Catatan opsional tambahan |
| `walletId` | `TEXT` | Referensi ke tabel `wallets(id)` |
| `customCategoryId` | `TEXT` | Referensi ke tabel `custom_categories(id)` |

---

### 2. Tabel `wallets`
Menyimpan akun/dompet keuangan milik pengguna.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT PRIMARY KEY` | UUID unik dompet |
| `name` | `TEXT NOT NULL` | Nama dompet (misal: 'BCA', 'Dompet Utama', 'Gopay') |
| `initialBalance` | `REAL NOT NULL DEFAULT 0` | Saldo awal saat dompet pertama kali dibuat |
| `colorValue` | `INTEGER NOT NULL` | Nilai warna integer ARGB untuk UI |
| `iconName` | `TEXT NOT NULL` | Nama ikon Material |
| `emoji` | `TEXT NOT NULL DEFAULT '👛'` | Karakter emoji visual dompet |
| `isDefault` | `INTEGER NOT NULL DEFAULT 0` | Boolean (1 jika dompet default, 0 jika bukan) |
| `createdAt` | `INTEGER NOT NULL` | Timestamp pembuatan |

---

### 3. Tabel `budgets`
Menyimpan batas anggaran per kategori untuk bulan dan tahun tertentu.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT PRIMARY KEY` | UUID unik anggaran |
| `category` | `TEXT NOT NULL` | Nama enum kategori bawaan |
| `monthlyLimit` | `REAL NOT NULL` | Batas maksimal pengeluaran |
| `year` | `INTEGER NOT NULL` | Tahun anggaran (misal: 2026) |
| `month` | `INTEGER NOT NULL` | Bulan anggaran (1..12) |
| `customCategoryId` | `TEXT` | Referensi ke kategori kustom jika ada |

---

### 4. Tabel `transfers`
Menyimpan riwayat mutasi saldo antar dompet.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT PRIMARY KEY` | UUID unik transfer |
| `fromWalletId` | `TEXT NOT NULL` | ID dompet pengirim |
| `toWalletId` | `TEXT NOT NULL` | ID dompet penerima |
| `amount` | `REAL NOT NULL` | Nominal yang ditransfer |
| `note` | `TEXT` | Catatan opsional |
| `date` | `INTEGER NOT NULL` | Waktu transfer (milidetik Unix) |

---

### 5. Tabel `savings_goals`
Menyimpan data rencana tabungan finansial.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT PRIMARY KEY` | UUID unik tabungan |
| `title` | `TEXT NOT NULL` | Nama tujuan tabungan (misal: 'Beli Laptop') |
| `targetAmount` | `REAL NOT NULL` | Target nominal yang ingin dicapai |
| `currentAmount` | `REAL NOT NULL DEFAULT 0` | Jumlah saldo yang sudah terkumpul |
| `targetDate` | `INTEGER` | Timestamp target waktu pencapaian |
| `emoji` | `TEXT NOT NULL DEFAULT '🎯'` | Ikon emoji tabungan |
| `colorValue` | `INTEGER NOT NULL` | Nilai warna ARGB |
| `isCompleted` | `INTEGER NOT NULL DEFAULT 0` | Status pencapaian (1 = selesai, 0 = belum) |
| `createdAt` | `INTEGER NOT NULL` | Timestamp pembuatan |

---

### 6. Tabel `debts`
Menyimpan catatan hutang dan piutang.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT PRIMARY KEY` | UUID unik hutang |
| `personName` | `TEXT NOT NULL` | Nama pihak terkait |
| `amount` | `REAL NOT NULL` | Total nominal pinjaman |
| `paidAmount` | `REAL NOT NULL DEFAULT 0` | Akumulasi nominal yang telah dibayar |
| `type` | `TEXT NOT NULL` | `'iOwe'` (Hutang) atau `'owedToMe'` (Piutang) |
| `dueDate` | `INTEGER` | Timestamp batas jatuh tempo |
| `note` | `TEXT` | Catatan opsional |
| `isSettled` | `INTEGER NOT NULL DEFAULT 0` | Status lunas (1 = lunas, 0 = belum) |
| `createdAt` | `INTEGER NOT NULL` | Timestamp pembuatan |

---

### 7. Tabel `recurring_transactions`
Menyimpan konfigurasi otomatisasi transaksi rutin.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT PRIMARY KEY` | UUID unik jadwal |
| `title` | `TEXT NOT NULL` | Judul transaksi |
| `amount` | `REAL NOT NULL` | Nominal transaksi |
| `type` | `TEXT NOT NULL` | `'income'` atau `'expense'` |
| `category` | `TEXT NOT NULL` | Kategori bawaan |
| `frequency` | `TEXT NOT NULL` | `'daily'`, `'weekly'`, `'monthly'`, atau `'yearly'` |
| `startDate` | `INTEGER NOT NULL` | Tanggal mulai berlaku |
| `endDate` | `INTEGER` | Tanggal berakhir (opsional) |
| `lastGeneratedDate`| `INTEGER` | Tanggal transaksi terakhir berhasil dibuat |
| `isActive` | `INTEGER NOT NULL DEFAULT 1` | Status aktif transaksi berulang |
| `note` | `TEXT` | Catatan |
| `walletId` | `TEXT` | ID dompet terkait |
| `customCategoryId` | `TEXT` | ID kategori kustom terkait |

---

### 8. Tabel `custom_categories`
Menyimpan kategori buatan pengguna.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT PRIMARY KEY` | UUID unik kategori |
| `name` | `TEXT NOT NULL` | Nama kategori (misal: 'Kopi & Nongkrong') |
| `emoji` | `TEXT NOT NULL DEFAULT '🏷️'`| Karakter emoji ikon kategori |
| `colorValue` | `INTEGER NOT NULL` | Nilai warna ARGB |
| `type` | `TEXT NOT NULL` | `'income'` atau `'expense'` |
| `createdAt` | `INTEGER NOT NULL` | Timestamp pembuatan |

---

### 9. Tabel `split_bills`
Menyimpan data induk patungan / bagi tagihan (Split Bill).

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT PRIMARY KEY` | UUID unik tagihan |
| `title` | `TEXT NOT NULL` | Judul / nama kegiatan patungan |
| `totalAmount` | `REAL NOT NULL` | Total nilai tagihan sebelum tax & service |
| `taxPercent` | `REAL NOT NULL DEFAULT 0` | Persentase pajak (%) |
| `servicePercent` | `REAL NOT NULL DEFAULT 0` | Persentase layanan (%) |
| `date` | `INTEGER NOT NULL` | Timestamp tanggal tagihan |
| `paidBy` | `TEXT NOT NULL` | Nama penanggung/pembayar awal |
| `isSettled` | `INTEGER NOT NULL DEFAULT 0` | Status lunas seluruh peserta (1/0) |
| `createdAt` | `INTEGER NOT NULL` | Timestamp pembuatan |

---

### 10. Tabel `split_participants`
Menyimpan data rincian peserta dan pembagian nominal per orang.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT PRIMARY KEY` | UUID unik peserta |
| `billId` | `TEXT NOT NULL` | Foreign key ke `split_bills(id)` ON DELETE CASCADE |
| `name` | `TEXT NOT NULL` | Nama peserta |
| `amount` | `REAL NOT NULL` | Nominal kewajiban bayar yang ditanggung |
| `isPaid` | `INTEGER NOT NULL DEFAULT 0` | Status pembayaran individu (1/0) |
| `debtId` | `TEXT` | Referensi ke ID piutang terkait di tabel `debts` |

---

### 11. Tabel `tags`
Menyimpan daftar tag / label proyek transaksi.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT PRIMARY KEY` | UUID unik tag |
| `name` | `TEXT NOT NULL UNIQUE` | Nama label tag |
| `colorValue` | `INTEGER NOT NULL` | Nilai warna ARGB |
| `createdAt` | `INTEGER NOT NULL` | Timestamp pembuatan |

---

### 12. Tabel `subscriptions`
Menyimpan tagihan rutin & langganan berkala.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT PRIMARY KEY` | UUID unik langganan |
| `name` | `TEXT NOT NULL` | Nama layanan (Netflix, Spotify, Wifi) |
| `amount` | `REAL NOT NULL` | Nominal biaya tagihan |
| `billingCycle` | `TEXT NOT NULL` | `'monthly'`, `'yearly'`, atau `'weekly'` |
| `dueDay` | `INTEGER NOT NULL` | Tanggal jatuh tempo tagihan (1..31) |
| `walletId` | `TEXT` | ID dompet pemotong tagihan (opsional) |
| `category` | `INTEGER NOT NULL` | Kategori transaksi |
| `isActive` | `INTEGER NOT NULL DEFAULT 1` | Status langganan aktif (1/0) |
| `reminderDaysBefore` | `INTEGER NOT NULL DEFAULT 2` | Pengingat H-N hari sebelum jatuh tempo |
| `notes` | `TEXT` | Catatan opsional |
| `createdAt` | `INTEGER NOT NULL` | Timestamp pembuatan |

---

### 13. Tabel `assets`
Menyimpan daftar portofolio aset investasi dan kekayaan.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT PRIMARY KEY` | UUID unik aset |
| `name` | `TEXT NOT NULL` | Nama aset (Antam 10gr, Saham BBCA, dsb.) |
| `type` | `TEXT NOT NULL` | `'cash'`, `'gold'`, `'mutualFund'`, `'stock'`, `'deposit'`, `'property'`, `'crypto'`, `'other'` |
| `amount` | `REAL NOT NULL` | Nilai estimasi total aset |
| `notes` | `TEXT` | Catatan opsional |
| `updatedAt` | `INTEGER NOT NULL` | Timestamp pembaruan terakhir |

---

## 🔄 Riwayat Versi & Migrasi Schema

| Versi DB | Perubahan & Skrip Migrasi |
|---|---|
| **v1** | Pembuatan tabel dasar: `transactions` dan `budgets`. |
| **v2** | Penambahan tabel `wallets` dan `transfers`; penambahan kolom `walletId` pada `transactions`. Pembuatan dompet default otomatis jika belum tersedia. |
| **v3** | Penambahan tabel `savings_goals` dan `debts`. |
| **v4** | Penambahan tabel `recurring_transactions`. |
| **v5** | Penambahan tabel `custom_categories`. |
| **v6** | **Integrasi Kategori Kustom & Foreign Key Integrity**:<br>• `ALTER TABLE transactions ADD COLUMN customCategoryId TEXT;`<br>• `ALTER TABLE budgets ADD COLUMN customCategoryId TEXT;`<br>• `ALTER TABLE recurring_transactions ADD COLUMN customCategoryId TEXT;`<br>• Penanganan orphan wallet pada transaksi berulang saat dompet dihapus.<br>• Pengaktifan `PRAGMA foreign_keys = ON;`. |
| **v7** | **Multi-Currency & Split Bill**:<br>• `ALTER TABLE wallets ADD COLUMN currencyCode TEXT NOT NULL DEFAULT 'IDR';`<br>• Pembuatan tabel `split_bills` dan `split_participants`. |
| **v8** | **Tagging, Subscriptions, Assets & Budget Rollover**:<br>• `ALTER TABLE transactions ADD COLUMN tags TEXT;`<br>• `ALTER TABLE budgets ADD COLUMN isRollover INTEGER NOT NULL DEFAULT 0;`<br>• Pembuatan tabel `tags`, `subscriptions`, dan `assets`. |
