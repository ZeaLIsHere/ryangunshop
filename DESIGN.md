# RyanGunshop — Design System (Violet Commerce POS)

## Visual Direction

Antarmuka bertema **Violet Commerce POS (Modern Spatial Warung)**: memadukan
kecepatan operasional terminal kasir ritel dengan estetika modern violet yang bersih,
elegan, dan tenang. Sistem visual ini dirancang untuk menghilangkan kelelahan mata
selama shift kerja panjang di lingkungan warung dan toko kelontong, sekaligus memberikan
kejelasan data spasial penataan rak secara instan di perangkat Android.

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

## Color Roles

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

## Typography

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

## Layout & Geometry

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

## Elevation & Depth

1. **Level 0 (Canvas):** `#FAF8FE` sebagai lantai aplikasi.
2. **Level 1 (Cards & Shelf Modules):** Permukaan `#FFFFFF` dengan bayangan difusi lembut bernuansa violet:
   `box-shadow: 0px 8px 24px -4px rgba(124, 58, 237, 0.06), 0px 2px 6px -1px rgba(15, 23, 42, 0.02)`
   serta garis tepi 1px `#EDE8F5`.
3. **Level 2 (Active Drawers, Modals & Floating Nav):** Panel melayang dengan bayangan bantal:
   `box-shadow: 0px 16px 36px -6px rgba(109, 40, 217, 0.12), 0px 4px 12px -2px rgba(15, 23, 42, 0.04)`.
4. **Hero Accent Panel (Hero Banner):** Gradien violet jenuh
   `linear-gradient(135deg, #7C3AED 0%, #6D28D9 55%, #4C1D95 100%)` dengan pendaran cahaya violet:
   `box-shadow: 0px 14px 28px -6px rgba(124, 58, 237, 0.35)`.

## Components & Screen Blueprints

- `StoreFloorPlan`: Kanvas tata letak 2D berbasis matriks titik (*grid-matrix*) dengan ukuran warung
  (mis. 8.0m × 6.0m) dan skala snap 0.5m. Objek rak, kulkas, meja kasir, dan galon memiliki siluet jelas,
  suhu/kategori micro-badge, dan status ketersediaan barang.
- `HeroOrderCard` / `HeroMetricCard`: Panel gradien violet melengkung 24 dp menampilkan metrik utama
  (Omzet Hari Ini, Total Pesanan Kasir, atau Total SKU) dengan teks putih bersih dan tombol pill aksi cepat.
- `QuickActionPods`: Baris kartu aksi 3-up atau 4-up berisi squircle 48×48 dp berlatar warna pastel
  fungsional (`#F5F3FF`, `#ECFDF5`, `#FFF7ED`, `#E0F2FE`) memuat ikon tindakan (Pindai Rak, Kasir, Voucher).
- `ProductScanner`: Layar kamera gelap dengan sudut bidik ungu menyala (*purple glow*), garis laser scan
  beranimasi `#A855F7`, status verifikasi barcode instan, kartu barang terdeteksi, serta **Pod Lokasi
  Rak Spasial** yang menampilkan pratinjau matriks mini denah dengan indikator rak aktif berdenyut (*pulse*).
- `CartCheckout`: Daftar rincian belanja bersih dengan badge lokasi rak per item (`Rak A1`), stepper
  kuantitas membulat, kartu ringkasan total, dan tombol pill bayar penuh tinggi 52 dp.
- `PaymentSheet`: Pemisahan tegas antara metode Tunai (dengan pilihan pecahan uang cepat dan kalkulator
  kembalian instan) dan QRIS dinamis berstatus transparan (`creating`, `awaitingPayment`, `paid`, `expired`, `failed`).
- `ProductCatalog`: Pencarian instan terintegrasi tombol scan, filter chips kategori mendatar (Semua,
  Rak A, Rak B, Kulkas, Stok Menipis), kartu produk ringkas beraksen tombol tambah violet, serta widget
  peta rak spasial toko.
- `ReportsAnalytics`: Pilihan tab periode kapsul (Hari Ini, Minggu Ini, Bulan Ini, Kustom), kartu hero
  omzet dengan pill laba bersih, kartu rekap shift, grafik analitik visual, dan tombol cetak struk Bluetooth.
- `FloatingBottomNav`: Navigasi bawah melayang bersudut atas 24 dp dengan bayangan violet lembut, 5 slot
  keseimbangan (Home, Katalog, Scan, Kasir, Laporan) dengan tombol Scan tengah melayang bergradien ungu.

## Interaction Rules

- **Mode Lihat vs Mode Edit Denah:** Mode lihat memicu tap untuk membuka daftar produk rak dan gesture
  pan/zoom kanvas. Mode edit (khusus Pemilik / *Owner*) mengaktifkan grid snap, penanda akses terproteksi,
  serta tombol kontrol khusus (rotasi, ukuran, duplikasi, hapus, penamaan) sehingga tidak ada objek bergeser
  tak sengaja saat transaksi kasir berjalan.
- **Konfirmasi Eksplisit Pemindai:** Pemindai barcode/AI tidak pernah memasukkan barang secara diam-diam;
  selalu tampilkan panel hasil dengan rute rak, kuantitas stepper, dan tombol konfirmasi tegas.
- **Kejujuran Data & Status Offline:** Setiap layar wajib memiliki state kosong, memuat, offline, dan error.
  Data contoh ditandai dengan jujur dan tidak menampilkan status pembayaran sukses palsu.
- **Aksesibilitas:** Target sentuh minimal 48×48 dp, kontras WCAG 2.1 minimal 4.5:1 untuk teks inti, dan
  makna status selalu disampaikan lewat kombinasi ikon, teks, dan warna.
- **Motion Efisien:** Transisi halus 120–200 ms dengan kurva eased (*cubic-bezier(0.22, 1, 0.36, 1)*).
  Menghormati preferensi *reduced motion*.

## Brand Asset Workflow

Logo produksi berada di `mobile/assets/branding/ryangunshop_logo.png`. Turunan launcher dan native splash
dapat digenerasikan ulang secara otomatis tanpa mengubah proporsi:

```bash
cd mobile
dart run tool/generate_brand_assets.dart "path/ke/logo.png"
```
