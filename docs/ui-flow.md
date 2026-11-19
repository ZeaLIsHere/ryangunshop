# Alur UI dan status implementasi RyanGunshop

Status: 15 November 2026. Dokumen ini menggambarkan implementasi lokal saat ini,
bukan lagi tahap UI-only. Pemilik fitur katalog/kasir: Blessly Victory Deo Silaban;
shell, Beranda, dan laporan: Tariq. Pembagian kerja tetap mengikuti `TEAM.md`.

## Peran dan Beranda

Pemilik/kasir dipilih lewat Pengaturan, tanpa login atau PIN. Pembatasan kelola
produk adalah pemeriksaan mode aplikasi, bukan batas keamanan autentikasi.
Peran dibaca dari sesi bersama dan diperiksa ulang saat penyimpanan.

- **Kasir:** desain operasional asli dipertahankan: Hero **Omzet Hari Ini**,
  aksi laporan, empat bento Aksi Cepat (Pindai Barcode, Buka Kasir, Stok,
  Riwayat Nota), lalu nota terkini. Tidak menampilkan alat kelola pemilik.
- **Pemilik:** periode **Hari ini / 7 hari / 30 hari**, Hero **Penjualan Bersih**
  beserta jumlah nota/rata-rata, grafik harian, perhatian stok saat ini dan aksi
  kelola, produk terlaris, lalu nota periode. Periode memakai kalender lokal,
  termasuk hari ini; batas akhir eksklusif adalah awal besok. Nilai produk
  terlaris adalah penjualan kotor sebelum diskon nota, bukan laba.
- `mobile/lib/features/dashboard/view/dashboard_components.dart` menyediakan
  Hero, pod aksi, baris nota, dan `DashboardShortcutsSection` bersama. Pemakaian
  komponen bersama tidak menyamakan hierarki kedua peran.
- **Pintasan Menu** dipulihkan pada kedua Beranda: Katalog produk, Keranjang,
  Riwayat transaksi, Pengaturan, Statistik, Chatbot. Tujuan tetap memakai router
  dan pemeriksaan izin layar terkait.

## Produk dan pemindaian

1. **Produk (`ProductCatalog`):** pencarian, kategori, urutan, dan filter stok
   membaca repository lokal. Judul halaman **Produk**; tag **Tersimpan di
   perangkat** sudah dihapus. Penghapusan tag bukan bukti unggah cloud.
2. Katalog memakai `CustomScrollView`/`SliverList.builder` untuk membangun baris
   grid secara lazy. Cakupan uji: dua kolom pada 360 dp, tiga pada 600 dp, lima
   pada 1024 dp, termasuk text scale 1.3. Tinggi kartu mengikuti konten alami,
   bukan aspect ratio tetap atau pemotongan teks untuk memaksa tinggi.
3. **Kelola produk:** pemilik dapat menambah, mengedit, menghapus, membuat kode
   internal, dan menghasilkan PDF label **Code128**. Validasi barcode/harga/stok
   tetap berlaku; kasir tidak mendapat kontrol kelola produk.
4. **`ProductScannerScreen`:** kamera native nyata melalui `mobile_scanner`,
   dengan pencarian/input manual saat izin ditolak atau kamera tidak tersedia.
   Hasil perlu konfirmasi sebelum masuk keranjang. Kamera dilepas selama
   checkout dan disiapkan ulang bila pengguna memindai lagi.

## Keranjang dan pembayaran

```text
Produk / kamera / input manual
  → hasil produk dan konfirmasi
  → keranjang: kuantitas, diskon, total
  → pembayaran tunai
  → SQLite: nota + baris barang + pengurangan stok
  → bukti transaksi lokal
```

Produk, stok, nota, dan draft keranjang tersimpan lewat SQLite/Drift pada native.
Penyimpanan transaksi tunai nyata bukan simulasi sesi. Status berhasil hanya
boleh muncul setelah penyimpanan berhasil. State memuat, kosong, error/retry,
dan offline harus tetap dapat dipakai. Data sintetis yang diimpor untuk
presentasi memakai UI biasa tanpa label contoh/sintetis/demo; asalnya dicatat
melalui ID/metadata internal, bukan penanda di layar.

QRIS belum terverifikasi sebagai pembayaran nyata. State `creating`,
`awaitingPayment`, `paid`, `expired`, `failed` adalah kontrak tampilan/simulasi,
bukan bukti pembayaran penyedia. Cetak struk thermal/Bluetooth fisik juga belum
terverifikasi. PDF label bukan bukti printer fisik bekerja.

## Laporan dan analitik

Laporan mengambil transaksi repository untuk **tanggal kalender lokal** yang
dipilih, bukan jendela 24 jam bergulir. Ekspor menghasilkan PDF dan berkas Excel
**`.xlsx` nyata**. Android membuka lembar berbagi; aplikasi penerima/pengguna
menentukan penyimpanan. Berkas **tidak dijamin otomatis masuk Downloads**.
Tidak ada laba historis karena nota belum menyimpan snapshot harga modal.

## IyanBoT, cloud, dan web

- IyanBoT/Groq memiliki tool baca dan penyusunan draft. Produk atau penjualan
  baru disimpan lokal setelah konfirmasi pengguna; kelola produk tetap khusus
  pemilik, termasuk pemeriksaan ulang saat konfirmasi. Uji API langsung belum
  terverifikasi dan dijeda atas permintaan pengguna.
- Firebase native diaktifkan lewat flag build `FIREBASE_ENABLED` dari konfigurasi
  privat. Outbox SQLite dikuras saat startup, perubahan sesi, serta setiap 15
  detik selama aplikasi berjalan. Ini bukan layanan latar belakang Android.
  SDK siap bukan bukti unggah berhasil; produk lama tidak otomatis di-backfill.
- Jalur tulis kode: `stores/{storeId}/products/{productId}` dan
  `stores/{storeId}/transactions/{transactionId}`. Autentikasi Firestore,
  keamanan/isolasi tenant, deployment aturan, dan pemulihan cloud belum
  terverifikasi. Detail: `firebase-setup.md` dan `firestore-schema.md`.
- Web hanya pratinjau; tidak memakai SQLite, antrean outbox, atau sinkronisasi
  native. Denah/panorama adalah arsip, bukan navigasi utama.
- QRIS nyata, cetak thermal, foto koreksi privat, model TFLite, dan rencana
  restok belum menjadi kemampuan produksi terverifikasi.

## Bukti validasi dan batasnya

Hasil validasi **15 November 2026**: analyzer bersih dan **212 pengujian lulus**,
dijalankan ulang saat pembaruan dokumentasi. APK sebelumnya dibangun sekitar
**51 detik**, dipasang dengan `adb install -r`, dan diluncurkan pada Samsung. Build/install/launch **tidak
membuktikan UI fisik atau seluruh alur perangkat sudah diperiksa**; verifikasi
visual, kamera, berbagi, cetak fisik, unggah cloud, dan API langsung tetap perlu
bukti masing-masing.

Pemeriksaan kode dari `mobile/`:

```bash
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
```

Acuan pengujian: `catalog_grid_test.dart`, `dashboard_test.dart`,
`dashboard_period_test.dart`, `checkout_persistence_test.dart`,
`report_export_test.dart`, `chatbot_actions_test.dart`, serta pengujian repository
pada `mobile/test/`. Pengujian widget bukan audit visual Android fisik.
