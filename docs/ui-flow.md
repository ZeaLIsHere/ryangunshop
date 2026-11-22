# Alur UI dan status implementasi RyanGunshop

Status: 19 November 2026, acuan kode `a85a159`. Dokumen ini membedakan
implementasi cloud-first native dari rencana Monitor,
bukan lagi tahap UI-only. Pemilik fitur katalog/kasir: Blessly Victory Deo Silaban;
shell, Beranda, dan laporan: Tariq. Pembagian kerja tetap mengikuti `TEAM.md`.

## Autentikasi dan Pengelolaan Peran (Owner & Kasir)

1. **Alur Masuk & Daftar (`/login`, `/register`):**
   - Layar Login (`LoginScreen`): input email dan password dengan validasi format. Menyediakan tautan cepat ke registrasi akun baru.
   - Layar Register (`RegisterScreen`): pemilih peran antara **Pemilik Toko (Owner)** dan **Kasir**. Form Owner meminta nama toko dan alamat toko; toko dibuat otomatis saat registrasi berhasil. Form Kasir hanya mendaftarkan profil pengguna tanpa toko awal.
2. **Penampung Kasir Tanpa Toko (`/kasir-menunggu`):**
   - Kasir yang baru mendaftar atau belum memiliki relasi toko diarahkan ke `CashierPendingInvitationScreen`.
   - Menampilkan status menunggu undangan dan daftar kartu undangan masuk dari Owner toko, lengkap dengan nama toko, nama pengundang, dan tombol tindakan **Terima** atau **Tolak**.
   - Ketika kasir menerima undangan, relasi toko aktif diperbarui dan kasir diarahkan ke Beranda operasional kasir.
3. **Pengelolaan Kasir Toko oleh Owner (`/kelola-kasir`):**
   - Diakses melalui menu Pengaturan atau pintasan kelola pada Beranda Owner.
   - Tab **Kasir Aktif**: daftar kasir yang terhubung dengan toko beserta tanggal bergabung dan tombol "Lepas Kasir" (konfirmasi modal tanpa menghapus akun kasir).
   - Tab **Undangan Menunggu**: daftar undangan kasir yang berstatus pending dengan opsi "Batalkan Undangan".
   - Floating Action Button **Undang Kasir**: modal bottom sheet (`InviteCashierSheet`) untuk memasukkan email kasir terdaftar.
4. **Sesi dan Akses Kontrol:**
   - Sesi pengguna disimpan secara persisten di database Drift lokal.
   - Halaman pengelolaan kasir dan aksi kelola toko dibatasi ketat hanya untuk akun bertipe Owner. Kasir tidak dapat mengakses layar manajemen toko.

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

## Monitor — alur UI rencana, fondasi lokal tersedia

Rencana kanonis: [Rencana Monitor](monitor-plan.md), disusun terpisah.
Tombol **Monitor** direncanakan hanya pada Beranda pemilik, menuju halaman baru;
kasir dan navigasi utama tetap. Peran lokal bukan batas keamanan.

1. **Setup awal:** pilih template Dinding, Dua baris, atau Dinding + tengah.
   Pilih produk secara massal dan konfirmasikan penempatan manual. Boleh lewati;
   produk tersisa berada di **Belum ditempatkan**, tidak diberi lokasi palsu.
2. **Pantau:** kanvas isometrik 2.5D ringan, pilih fixture untuk detail; pan/zoom
   tidak memindahkan fixture. Kandidat native `CustomPainter` + `InteractiveViewer`.
   Audit reuse `floor_plan` arsip; bukan pengaktifan panorama/data contoh lama.
3. **Detail:** bottom sheet ponsel atau panel samping tablet. Baca stok dan
   `lowStockThreshold` produk yang sudah ada. Peringatan ikon + teks menghitung
   jenis produk menipis/habis, bukan total unit campuran.
4. **Edit:** grid sederhana rak/kulkas/meja kasir; tambah, pindah, nama, rotasi
   90°, hapus. **Simpan** menerapkan draft, **Batal** membuang draft; keluar
   dengan perubahan belum disimpan memerlukan konfirmasi.
5. **Penempatan:** satu lokasi utama per produk lewat `fixtureId`. Pindah fixture
   tidak mengubah stok. Hapus rak melepas penempatan, bukan menghapus produknya.
   Persistensi layout dan migrasi masih usulan, bukan koleksi Firestore aktif.
6. **Jalur alternatif:** daftar aksesibel setara kanvas, reset zoom, reduced
   motion; lebar 360 dp/skala 1.3, target sentuh 48 dp. Sediakan state kosong,
   memuat, error/retry, offline; cache bukan jaminan stok cloud terbaru.

## Produk dan pemindaian

1. **Produk (`ProductCatalog`):** pencarian, kategori, urutan, dan filter stok
   membaca repository cloud-first native dengan cache/fallback SQLite.
   Judul halaman **Produk**; tag **Tersimpan di
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
- Baca native memakai `Source.server`, reuse hasil 15 detik, backoff gagal
  30 detik, timeout 8 detik lalu fallback SQLite. Request native terlambat tidak
  overlap; hasil terlambat tidak diimpor. Outbox pending dan revisi tulis lokal
  melindungi perubahan produk/nota. `dataRevision` menyegarkan Beranda, Produk,
  Statistik, serta laporan. Impor nota tidak menjalankan checkout lagi.
- Full scan dibatasi 10.000 dokumen/koleksi; melampaui batas bukan impor parsial.
  Snapshot lintas koleksi/halaman tidak atomik dan setiap scan memakai read
  Firestore. Stok multi-device masih last-write-wins, tidak aman bersamaan.
- Jalur baca/tulis kode: `stores/{storeId}/products/{productId}` dan
  `stores/{storeId}/transactions/{transactionId}`. Autentikasi Firestore,
  keamanan/isolasi tenant, deployment aturan, dan pemulihan cloud belum
  terverifikasi. Detail: `firebase-setup.md` dan `firestore-schema.md`.
- Web hanya pratinjau; tidak memakai SQLite, antrean outbox, atau sinkronisasi
  native atau cloud-first. Denah/panorama adalah arsip; Monitor baru fondasi lokal, UI belum aktif.
- QRIS nyata, cetak thermal, foto koreksi privat, model TFLite, dan rencana
  restok belum menjadi kemampuan produksi terverifikasi.

## Bukti validasi dan batasnya

Validasi terakhir yang dilaporkan **19 November 2026**: analyzer bersih,
**240 test Flutter + 12 test Node lulus**, termasuk rekonsiliasi stok legacy.
Impor berizin sudah create-only dan read-back terverifikasi: 90 dokumen,
24 produk, 66 nota tunai, 394 unit, Rp3.035.800 untuk 10–24 November 2026
inklusif (15 hari). Tanggal mendatang termasuk dataset; filter periode tetap
mengikuti kalender. Data tampil normal, asal hanya metadata internal.

APK cloud-first belum dibangun/dipasang; baca native dan unggah outbox perangkat
belum diuji langsung. GET tanpa autentikasi masih HTTP 200: risiko baca publik.
Tidak ada perubahan rules/auth atau permintaan login/PIN/Anonymous Auth.
Hasil di atas bukan uji ulang pada tugas dokumentasi, bukan validasi Monitor.

**Riwayat sebelum cloud-first, 15 November 2026:** analyzer bersih dan
**212 pengujian lulus**. APK saat itu dibangun sekitar
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
