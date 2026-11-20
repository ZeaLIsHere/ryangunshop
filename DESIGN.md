# RyanGunshop — Design System (Violet Commerce POS)

## Arah visual

Antarmuka bertema **Violet Commerce POS (Modern Spatial Warung)**: memadukan
kecepatan operasional terminal kasir ritel dengan estetika modern violet yang bersih,
elegan, dan tenang. Sistem visual ini dirancang untuk menghilangkan kelelahan mata
selama shift kerja panjang di lingkungan warung dan toko kelontong, sekaligus memberikan
kejelasan transaksi, stok, dan analitik di perangkat Android. Denah/panorama
adalah arsip, bukan navigasi utama. Monitor adalah rencana halaman baru pemilik,
bukan pengaktifan kembali arsip.

**Status 19 November 2026, acuan kode `a85a159`:** identitas Violet Commerce POS tetap dikunci.
Dokumen ini membedakan aturan visual dari kemampuan terpasang; bukan bukti
seluruh UI fisik atau alur perangkat Android sudah diverifikasi.

Bahasa desain berakar pada *soft modernism* dan kejelasan fungsional operasional:
- **Tonal Canvas Violet yang Bersih:** Lapisan kanvas bernuansa lembut (`#FAF8FE` / `#F8F9FF`)
  menghilangkan silau putih tajam tanpa mengorbankan hierarki visual.
- **Geometri Organik Ramah Sentuhan:** Sudut membulat modern 16–24 dp (`rounded-2xl` hingga
  `rounded-3xl`) pada kartu, hero metrik, dan sheet; tombol aksi berbentuk kapsul penuh
  (*pill*) yang tegas dan mudah ditekan.
- **Kontras Slate & Violet yang Kuat:** Tipografi menggunakan tinta slate gelap (`#0F172A`)
  berkontras tinggi demi keterbacaan prima di bawah pencahayaan toko yang bervariasi.
- **Micro-Contrast Accents:** Penanda status fungsional menggunakan latar pil pastel lembut
  yang memuat glif tegas (Emerald `#10B981` untuk stok aman/sukses, Amber `#F59E0B` untuk
  stok menipis, Rose `#EF4444` untuk peringatan/kesalahan).

## Peran warna

- **Primary `#7C3AED` (Violet-600):** Tindakan transaksi utama (Bayar, Konfirmasi Keranjang),
  pilihan aktif navigasi, tombol FAB pemindai, dan aksen penyorot rak terpilih.
- **Primary Dark `#6D28D9` (Violet-700 / `#4C1D95`):** Aksen gradient hero card, app bar
  kontras, dan state tekan tombol.
- **Primary Light `#EDE9FE` (Lavender Tint):** Pilihan sekunder, latar pill aktif, dan batas chip.
- **Primary Subtle `#F5F3FF` (Lavender Subtle):** Latar wadah ikon aksi cepat dan kontainer data ringkas.
- **Accent `#A855F7` (Purple-500) / `#8B5CF6`:** Garis laser pemindai barcode, fokus, progress bar,
  dan aksen motion.
- **Canvas `#FAF8FE`:** Latar dasar aplikasi (ultra-clean violet-white pencegah kelelahan mata).
- **Surface `#FFFFFF`:** Permukaan kartu produk, lembar kerja kasir, dan sheet elevasi.
- **Ink `#0F172A` (Deep Slate-900):** Teks utama, judul halaman, dan angka nominal rupiah.
- **Muted `#64748B` (Slate-500):** Teks pendukung, kode SKU, dan metadata rak.
- **Border Subtle `#EDE8F5`:** Garis tepi halus pemisah kartu dan input.
- **Success `#10B981` (Emerald-500):** Pembayaran tervalidasi, stok aman, dan keuntungan positif
  (wadah `#ECFDF5`, teks `#059669`).
- **Warning `#F59E0B` (Amber-500):** Peringatan stok menipis dan tindakan tertunda
  (wadah `#FFF7ED` / `#FFFBEB`, teks `#EA580C` / `#D97706`).
- **Error `#EF4444` (Rose-500):** Gagal bayar, transaksi batal, atau stok habis
  (wadah `#FEF2F2`, teks `#DC2626`).

Ramp lengkap dan aturan kontras WCAG tersedia di `docs/COLOR_PALETTE.md`.

## Tipografi

Sistem tipografi menggunakan sans-serif geometris modern (**Plus Jakarta Sans** / sistem Android)
dengan angka tabular rata lebar (*tabular figures*) untuk keterbacaan cepat pada tabel harga dan kasir.

Hierarki utama:
- `display-hero` (32 sp, w700, -0.02em): Nominal total belanja, omzet toko, dan saldo kasir.
- `headline-lg` (24 sp, w700, -0.02em): Judul halaman utama dan nama modal sheet.
- `headline-md` (20 sp, w600, -0.01em): Judul bagian dan identitas app bar.
- `headline-sm` (18 sp, w600): Sub-bagian dan judul kategori rak.
- `title-card` (16 sp, w600): Nama produk pada kartu dan judul modul tindakan.
- `body-lg` (16 sp, w400): Teks deskripsi dan panduan pemindaian.
- `body-md` (14 sp, w400): Teks operasional, label input, dan rincian transaksi.
- `body-sm` (12 sp, w500): Teks pendukung sekunder dan keterangan rak.
- `label-numeric` (15 sp, w700): Angka harga satuan, jumlah item, dan kode barcode.
- `label-caps` (11 sp, w700, +0.04em tracking): Label kategori rak (`RAK A-02`, `KULKAS-01`),
  indikator status (`TERSEDIA (48)`, `RESTOCK SEGERA`), dan caption micro-badge.

## Tata letak dan geometri

- **Rhythm Dasar:** Spacing kelipatan 4/8 dp (4, 8, 12, 16, 20, 24, 32 dp).
- **Padding Layar Ponsel:** 16 dp (`margin-mobile`), 20 dp pada tablet/desktop.
- **Sudut Lengkung (Border Radius):**
  - Kartu Dashboard & Produk: 16–20 dp (`rounded-2xl`).
  - Hero Card & Panel Metrik: 24 dp (`rounded-3xl`).
  - Tombol CTA Utama (Bayar, Konfirmasi, Tambah): Kapsul penuh (*full pill* 9999 dp) atau 16 dp.
  - Wadah Ikon Aksi Cepat (*Quick Action Pods*): Squircle 14–16 dp dalam footprint 48×48 dp.
  - Input & Bar Pencarian: 14–16 dp dengan border halus `#EDE8F5`.
  - Bottom Sheet & Floating Nav: Radius atas 24–28 dp.
- **Target Sentuh Ergonomis:** Seluruh tombol dan kontrol interaktif mempertahankan tinggi
  minimal 48–52 dp agar aman dari salah sentuh di saat jam sibuk antrean kasir.

## Elevasi dan kedalaman

1. **Level 0 (Canvas):** `#FAF8FE` sebagai lantai aplikasi.
2. **Level 1 (Cards & Shelf Modules):** Permukaan `#FFFFFF` dengan bayangan difusi lembut bernuansa violet:
   `box-shadow: 0px 8px 24px -4px rgba(124, 58, 237, 0.06), 0px 2px 6px -1px rgba(15, 23, 42, 0.02)`
   serta garis tepi 1px `#EDE8F5`.
3. **Level 2 (Active Drawers, Modals & Floating Nav):** Panel melayang dengan bayangan bantal:
   `box-shadow: 0px 16px 36px -6px rgba(109, 40, 217, 0.12), 0px 4px 12px -2px rgba(15, 23, 42, 0.04)`.
4. **Hero Accent Panel (Hero Banner):** Gradien violet jenuh
   `linear-gradient(135deg, #7C3AED 0%, #6D28D9 55%, #4C1D95 100%)` dengan pendaran cahaya violet:
   `box-shadow: 0px 14px 28px -6px rgba(124, 58, 237, 0.35)`.

## Komponen dan susunan layar

- `HeroOrderCard` / `HeroMetricCard`: Nama pola panel gradien violet melengkung 24 dp.
  Implementasi bersama `DashboardHeroCard` berada di
  `mobile/lib/features/dashboard/view/dashboard_components.dart`: **Omzet Hari Ini**
  untuk kasir, **Penjualan Bersih** untuk pemilik, beserta jumlah nota/rata-rata
  dan CTA sesuai peran. Ekstraksi komponen mempertahankan desain asli kasir.
- Beranda kasir mempertahankan Hero, aksi laporan, empat bento Aksi Cepat, dan
  nota terkini. Beranda pemilik mempunyai hierarki analitik tersendiri:
  **Hari ini / 7 hari / 30 hari**, ringkasan, grafik tren harian (*Smooth Area Line Chart* bergradien violet interaktif dengan scrubbing tanggal dan kurva adaptif), Status Stok, **Bento Aksi Kelola** (kartu unggulan Monitor Toko 3D isometrik + 4 action pods), produk terlaris, lalu nota periode. Periode memakai kalender lokal;
  produk terlaris berlabel penjualan kotor sebelum diskon nota, bukan laba.
- Pod aksi dan baris nota kedua peran juga memakai `dashboard_components.dart`.
  `DashboardShortcutsSection` memulihkan enam **Pintasan Menu** pada keduanya:
  Katalog produk, Keranjang, Riwayat transaksi, Pengaturan, Statistik, Chatbot.
  Tinggi kartu berpasangan diratakan secara presisi menggunakan `IntrinsicHeight` dan `crossAxisAlignment.stretch`.
- `QuickActionPods`: Baris kartu aksi 4-up berisi squircle 48×48 dp berlatar warna pastel fungsional
  (`08_pindai_barcode.png`, `02_keranjang.png`, `09_stok_produk.png`, `03_riwayat_transaksi.png`) memuat aksi operasional kasir harian.
- `ProductScanner`: Layar kamera dengan sudut bidik ungu menyala (*purple glow*), garis laser scan
  beranimasi `#A855F7`, status verifikasi barcode instan, kartu barang terdeteksi, serta tombol konfirmasi produk ke keranjang.
- `CartCheckout`: Daftar rincian belanja, stepper kuantitas, ringkasan subtotal,
  diskon, dan total, serta tombol pill bayar. Transaksi tunai, baris nota,
  pengurangan stok, dan draft keranjang memakai SQLite/Drift pada native.
  Jangan menganggap pajak PB1 sudah diterapkan hanya dari cetak biru visual.
- `PaymentSheet`: Pemisahan tegas antara metode Tunai (dengan pilihan pecahan uang cepat, uang pas, dan kalkulator
  kembalian instan) dan QRIS berstatus transparan (`creating`, `awaitingPayment`,
  `paid`, `expired`, `failed`). Tunai disimpan nyata; QRIS masih kontrak
  tampilan/simulasi, belum pembayaran nyata terverifikasi.
- `ProductCatalog`: Judul halaman **Produk**, tanpa tag **Tersimpan di perangkat**.
  Pencarian, kategori, urutan, dan filter stok memakai repository cloud-first
  pada native saat Firebase siap, dengan SQLite sebagai cache/fallback. Grid baris
  lazy (`CustomScrollView`/`SliverList.builder`) diuji dua kolom pada 360 dp,
  tiga pada 600 dp, lima pada 1024 dp, termasuk text scale 1.3. Tinggi kartu
  alami mengikuti isi, bukan aspect ratio tetap. Hilangnya tag bukan bukti cloud.
  Pemilik dapat tambah/edit/hapus, membuat kode internal dan PDF label Code128;
  kasir tidak mendapat alat kelola produk.
- `ProductScanner`: Kamera native nyata melalui `mobile_scanner`, dengan fallback
  manual dan konfirmasi hasil sebelum masuk keranjang. Kamera dilepas selama
  checkout dan disiapkan ulang saat pemindaian berikutnya.
- `ReportsAnalytics`: Urutan pilih tanggal, ringkasan penjualan bersih, rincian
  kotor/diskon, pembayaran/produk/nota, lalu panel Bagikan laporan. Pemilih tanggal
  berikon setinggi minimal 48 dp, Hari ini dan muat ulang dikelompokkan; status
  perangkat ini/offline/waktu lokal selalu terlihat. Penjelasan lengkap tersedia
  lewat disclosure. Empty/error memakai kartu dengan satu aksi pemulihan utama.
  Konten tablet dibatasi 768 dp agar tetap mudah dipindai. Data repository nyata;
  laporan mengikuti tanggal kalender lokal yang dipilih, ekspor PDF dan Excel
  `.xlsx` nyata melalui berbagi Android.
  Berbagi bukan jaminan penyimpanan otomatis ke Downloads. Laba historis belum
  dihitung karena nota belum menyimpan snapshot harga modal. Cetak thermal/
  Bluetooth fisik belum terverifikasi; jangan menampilkannya sebagai kemampuan teruji.
- `StatisticsScreen`: Layar statistik dan performa warung berbasis **Bento Grid Asimetris Fungsional**:
  Hero Bento Utama memuat Estimasi Nilai Total Aset/Inventaris Toko (`inventoryValue`) dan Omzet Hari Ini;
  2-Up Bento Cards menyajikan Kesehatan Inventaris (total item, varian, alert restok) dan Efisiensi Margin Laba (rata-rata margin % dan produk termodal);
  Bento Kategori Produk memuat multi-segment progress bar tonal;
  kontainer bento terstruktur untuk tren penjualan, metode pembayaran, jam sibuk, produk terlaris/lambat laku, peringkat margin laba, dan daftar perlu restok.
  Hierarki mengutamakan data nyata dari database/cloud daripada tumpukan kartu kosong.
- `FloatingBottomNav`: Navigasi bawah berbayang violet lembut dengan urutan Beranda (ikon `beranda.png`), Chatbot, tombol Kasir terangkat di tengah (`02_keranjang.png`), Produk, dan Statistik. Chatbot/Statistik membuka rute yang sudah ada dan kembali ke tab sebelumnya; Statistik kasir tetap diarahkan ke Riwayat Nota. Pengaturan tersedia melalui app bar.
- `StoreFloorPlan (Arsip)`: Komponen kanvas tata letak 2D berbasis matriks titik (*grid-matrix*) dan panorama 360 zona diarsipkan dari antarmuka utama demi kecepatan alur kasir.

## Monitor — kontrak UI, fondasi lokal tersedia

Rencana kanonis: [Rencana Monitor](docs/monitor-plan.md). Model/template dan
persistensi lokal, UI isometrik, drag dan penempatan tersedia; visual perangkat
belum diverifikasi. Kontrak di bawah tetap menjadi acuan penyempurnaan.
Bagian ini menetapkan kontrak visual/interaksi, bukan bukti fitur atau persistensi
layout sudah tersedia. Tidak mengubah referensi `contoh-desain/` atau skills.

- Masuk melalui tombol **Monitor** di Beranda pemilik menuju halaman baru;
  bukan tab utama baru dan bukan perubahan alur kasir.
- Kandidat renderer native: isometrik 2.5D ringan dengan `CustomPainter` dan
  `InteractiveViewer`. Tanpa panorama, WebView, atau mesin 3D tambahan.
  Audit bagian `floor_plan` arsip sebelum memakai ulang model, hit-test,
  pan/zoom atau semantik; jangan menghidupkan data palsu dan panorama arsip.
- Setup: pilih salah satu dari tiga template **Dinding**, **Dua baris**,
  **Dinding + tengah**; lanjutkan penempatan produk secara massal dengan
  konfirmasi manual. Produk boleh dilewati dan tetap **Belum ditempatkan**.
- **Pantau** hanya memilih fixture dan pan/zoom; tidak bisa menggeser fixture.
  **Edit** memakai grid sederhana untuk rak, kulkas, dan meja kasir: tambah,
  pindah, nama, rotasi 90°, hapus. Sediakan **Simpan**, **Batal**, serta
  konfirmasi saat keluar dengan perubahan belum disimpan.
- Satu lokasi utama per produk melalui `fixtureId`. Stok dan ambang dibaca
  dari `product.stock`/`lowStockThreshold` yang sudah ada, bukan salinan stok
  pada fixture. Pindah lokasi tidak mengubah stok; hapus rak melepas penempatan,
  bukan menghapus produk. Persistensi layout masih usulan, bukan koleksi aktif.
- Peringatan memakai ikon + teks + jumlah **jenis produk** menipis/habis.
  Jangan menjumlah stok berbeda satuan menjadi satu total yang tidak bermakna.
  Violet untuk pilihan/aksi; fixture pasif netral, status memakai token tema.
- Detail fixture memakai bottom sheet di ponsel dan panel samping di tablet.
  Sediakan daftar aksesibel setara kanvas, reset zoom, reduced motion, state
  kosong/memuat/error/offline, serta aman pada 360 dp/skala 1.3 dan target 48 dp.
  Tidak ada klaim audit atau pengujian Monitor lulus sebelum implementasi.

## Aturan interaksi

- **Mode Lihat vs Mode Edit Denah (arsip):** Mode lihat memicu tap untuk membuka daftar produk rak dan gesture
  pan/zoom kanvas. Mode edit (khusus Pemilik / *Owner*) mengaktifkan grid snap, penanda mode edit,
  serta tombol kontrol khusus (rotasi, ukuran, duplikasi, hapus, penamaan) sehingga tidak ada objek bergeser
  tak sengaja saat transaksi kasir berjalan.
- **Konfirmasi Eksplisit Pemindai:** Pemindai barcode/AI tidak pernah memasukkan barang secara diam-diam;
  selalu tampilkan panel hasil dengan rute rak, kuantitas stepper, dan tombol konfirmasi tegas.
- **Kejujuran Data & Status Offline:** Setiap layar wajib memiliki state kosong, memuat, offline, dan error.
  Data sintetis untuk presentasi memakai tampilan biasa tanpa label contoh,
  sintetis, atau demo; asalnya tetap dicatat internal melalui ID/metadata.
  Simulasi pembayaran tetap dijelaskan sebagai simulasi. Jangan menampilkan
  pembayaran berhasil sebelum penyimpanan dikonfirmasi atau cloud tersinkron
  hanya karena SDK siap. Firebase native memakai outbox dan `SyncEngine` saat
  startup, perubahan sesi, serta timer 15 detik selama aplikasi berjalan, bukan
  layanan latar belakang Android. Produk lama tidak otomatis di-backfill.
  Baca native mengutamakan server, memakai ulang hasil 15 detik, backoff gagal
  30 detik, dan timeout 8 detik dengan fallback SQLite. Guard outbox melindungi
  perubahan tertunda; `dataRevision` memperbarui Beranda, Produk, Statistik, dan
  laporan. Web hanya pratinjau lokal tanpa SQLite, queue, atau cloud-first native.
- **Peran:** Pengaturan memilih pemilik/kasir tanpa login/PIN. Guard produk
  diperiksa ulang saat simpan; bukan batas keamanan autentikasi atau isolasi tenant.
- **IyanBoT:** Groq membaca dan menyiapkan draft. Penyimpanan produk/penjualan
  lokal memerlukan konfirmasi pengguna; produk khusus pemilik. API langsung
  belum terverifikasi dan dijeda atas permintaan pengguna.
- **Aksesibilitas:** Target sentuh minimal 48×48 dp, kontras WCAG 2.1 minimal 4.5:1 untuk teks inti, dan
  makna status selalu disampaikan lewat kombinasi ikon, teks, dan warna.
- **Motion Efisien:** Transisi halus 120–200 ms dengan kurva eased (*cubic-bezier(0.22, 1, 0.36, 1)*).
  Menghormati preferensi *reduced motion*. Splash memakai signature motion sekitar
  1,45 detik dengan crossfade 280 ms; `disableAnimations` menghasilkan transisi
  instan. Onboarding menyediakan reduced motion.

## Batas integrasi dan bukti validasi

Firebase diaktifkan melalui `FIREBASE_ENABLED` dari konfigurasi build privat.
SDK siap bukan bukti unggah berhasil. Jalur produk dan nota berada di
`stores/{storeId}/products/{productId}` dan
`stores/{storeId}/transactions/{transactionId}`. Impor berizin pada 19 November
2026 sudah create-only dan read-back terverifikasi: 90 dokumen, 24 produk,
66 nota tunai, 394 unit, Rp3.035.800, 6–20 November 2026 inklusif (15 hari sampai hari ini).
Asal data tetap metadata internal, tanpa label visual.

APK cloud-first belum dibangun/dipasang; baca native langsung dan pengurasan
outbox perangkat belum terverifikasi. GET tanpa autentikasi masih HTTP 200:
risiko baca publik belum ditutup. Tidak ada perubahan rules/auth atau permintaan
login/PIN/Anonymous Auth. Stok lintas perangkat masih last-write-wins, tidak
aman untuk penjualan bersamaan. Snapshot lintas koleksi/halaman tidak atomik;
full scan dibatasi 10.000 dokumen/koleksi dan tetap memakai read Firestore.
Keamanan tenant dan pemulihan perangkat baru belum terverifikasi.
Konfigurasi privat tidak dibaca atau disalin untuk dokumentasi. `--dart-define`
bukan penyimpanan rahasia aman dalam APK.

QRIS nyata, cetak thermal fisik, foto koreksi privat, model TFLite, dan rencana
restok belum menjadi kemampuan produksi terverifikasi.

Validasi terakhir yang dilaporkan **19 November 2026**: analyzer bersih,
**240 test Flutter + 12 test Node lulus**, termasuk rekonsiliasi stok outbox lama.
Bukan eksekusi ulang pada tugas dokumentasi; bukan bukti UI Monitor atau baca
native langsung sudah berjalan.

**Riwayat 15 November 2026, sebelum cloud-first:** analyzer bersih,
**212 pengujian lulus**, APK dibangun sekitar **51 detik**, dipasang dengan
`adb install -r`, dan diluncurkan pada Samsung. Bukan hasil uji ulang tugas
ini. Build/install/launch tidak membuktikan pemeriksaan visual Android fisik
atau seluruh alur perangkat; audit aksesibilitas penuh juga belum terverifikasi.
Rujukan batas pengujian: `docs/a11y.md` dan `docs/ui-flow.md`.

## Alur kerja aset merek

Logo produksi berada di `mobile/assets/branding/ryangunshop_logo.png`. Turunan launcher dan native splash
dapat digenerasikan ulang secara otomatis tanpa mengubah proporsi:

```bash
cd mobile
dart run tool/generate_brand_assets.dart "path/ke/logo.png"
```
