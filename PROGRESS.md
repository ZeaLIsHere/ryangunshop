# RyanGunshop — Status Pengerjaan

Papan status hidup proyek. `TEAM.md` berisi rencana, sedangkan berkas ini berisi
keadaan nyata, supaya anggota tim dan agen AI mereka tahu sudah sampai mana proyek
berjalan tanpa harus menebak dari riwayat commit.

## Aturan pembaruan

- Perbarui baris Anda di sini **pada pull request yang sama** dengan tugas yang
  diselesaikan. Jangan menumpuk pembaruan status sampai akhir fase.
- Satu orang hanya menyunting baris miliknya sendiri. Bila anggota yang bersangkutan
  belum sempat, pemilik berkas boleh memperbarui baris itu agar papan status tidak
  basi, dan menyebutkannya di ringkasan pull request.
- Legenda: `belum` · `jalan` · `review` · `selesai`. Pakai `review` bila kode dan
  pengujian sudah selesai tetapi verifikasi emulator atau tinjauan PR belum ada, dan
  `selesai` hanya bila seluruh poin "Definisi selesai" di `TEAM.md` terpenuhi.

## Ringkasan fase

| Fase | Tariq | Farel | Blessly |
|---|---|---|---|
| 0 — Fondasi UI dan aset | selesai | review | review |
| 1 — Kerangka aplikasi dan komponen dasar | review | review | review |
| 2 — Splash, onboarding, dan dashboard | review | review | review |
| 3 — Denah operasional dan pemindai | review | review | review |
| 4 — Pembayaran, panorama, dan laporan | review | review | review |
| 5 — Audit aksesibilitas dan rilis internal | belum | belum | belum |

## Peta fitur

Tempat setiap fitur berada dan siapa pemiliknya. Statusnya mengikuti ringkasan fase di
atas. Bila Mini-SRS memiliki nomor FR/NFR, tambahkan kolomnya di tabel ini, bukan lewat
berkas checklist terpisah.

| Fitur | Folder | Pemilik | Status |
|---|---|---|---|
| Kerangka aplikasi, tema, komponen dasar | `mobile/lib/app/`, `mobile/lib/core/` | Tariq | review |
| Perkenalan | `mobile/lib/features/onboarding/` | Tariq | review |
| Dashboard | `mobile/lib/features/dashboard/` | Tariq | review |
| Pengaturan dan peran pengguna | `mobile/lib/features/settings/`, `core/session/` | Tariq | review |
| Riwayat dan laporan | `mobile/lib/features/reports/` | Tariq | review |
| Denah dan objek ruang | `mobile/lib/features/floor_plan/` | Farel | review |
| Panorama 360 | `mobile/lib/features/panorama/` | Farel | review |
| Aset brand & launcher | `mobile/assets/branding/`, `mobile/tool/` | Farel | review |
| Katalog produk | `mobile/lib/features/catalog/` | Blessly | review |
| Formulir produk | `mobile/lib/features/catalog/` | Blessly | review |
| Pemindai produk | `mobile/lib/features/scanner/` | Blessly | review |
| Keranjang dan pembayaran | `mobile/lib/features/checkout/`, `.../payment/` | Blessly | review |

## Catatan per tugas

Catatan umum: Fase 0–4 Tariq sudah di-merge ke `main`, dan aplikasi sudah dipasang serta
dijalankan pada perangkat Android SM A366B. Sisa poin definisi selesai adalah tinjauan
silang anggota lain dan verifikasi text scale 1.3 yang masuk audit Fase 5. Karena itu
statusnya `review`, bukan `selesai`.

**Pembaruan integrasi (2026-10-02) — Farel dan Blessly.**

- Fitur Farel dan Blessly yang sebelumnya masih di branch/berkas kerja sudah disatukan ke
  `main` dalam satu lintasan integrasi: `StoreFloorPlan` (mode lihat dan edit, `SyncPill`),
  viewer panorama 360 per zona, `ProductForm`, layar detail produk, pencarian dan filter
  katalog, `ProductScanner`, keranjang `CartCheckout`, `PaymentSheet` tunai/QRIS, dan
  `PaymentSuccessScreen`.
- Mode edit denah dilengkapi sesuai Fase 2: selain drag, putar, ganti nama, dan hapus,
  kini tersedia kontrol ukuran (perbesar/perkecil) dan duplikat objek di
  `mobile/lib/features/floor_plan/view_model/floor_plan_view_model.dart` dan
  `.../view/store_floor_plan.dart`.
- Kerangka aplikasi disambungkan: tab Kasir memakai `CartCheckoutScreen`, aksi utama
  dashboard dan tombol Scan membuka `ProductScannerScreen`, dan "Lihat di Denah" pada hasil
  pemindaian membuka denah dengan rak yang sesuai tersorot.
- Verifikasi: `flutter analyze` bersih dan `flutter test` 55/55 lulus pada Flutter 3.47.4 /
  Dart 3.13.3, termasuk state kosong, memuat, error, dan offline, target sentuh, serta
  lebar 360 dp pada skala teks 1,3. Belum ada verifikasi emulator atau perangkat Android
  dan belum ada tinjauan PR, jadi status tetap `review`.

### Fase 0 — Fondasi UI dan aset

**Tariq — selesai (2026-09-25)**

- Lingkup: proyek Flutter Android (minSdk 26), struktur `lib/`, token tema,
  `docs/COLOR_PALETTE.md`, konfigurasi pratinjau Android di `.vscode/`, `AGENTS.md`,
  dan `TEAM.md`.
- Berkas penting: `mobile/lib/core/theme/app_theme.dart`,
  `mobile/lib/core/theme/app_colors.dart`, `docs/COLOR_PALETTE.md`.
- Verifikasi: `flutter analyze` bersih, `flutter test` 4/4 lulus.
- Belum: tampilan belum dijalankan di emulator atau perangkat Android.

**Farel — review (2026-10-02).** Skema koordinat relatif 2D, `FixtureTile`, dan
konstanta template area warung sudah ada. Aset brand ditambahkan:

- `mobile/assets/branding/ryangunshop_logo.png` sebagai logo produksi, dipakai
  `RyanAppLogo` lewat `RyanAppLogo.defaultAssetPath`.
- `mobile/tool/generate_brand_assets.dart` membuat ulang launcher icon dan gambar
  native splash dari PNG sumber tanpa mengubah proporsi, memakai zlib `dart:io`
  tanpa menambah dependensi. Logo bawaan dibuat bila sumber tidak dioper.
- Verifikasi: `flutter analyze` bersih dan uji `test/tool/brand_assets_test.dart`
  (round-trip PNG, logo bawaan, dan generasi aset) lulus. Belum dijalankan di
  perangkat Android untuk melihat launcher icon hasilnya.

**Blessly — review (2026-09-27)**

- Lingkup Fase 0: model UI katalog, snapshot keranjang, state pembayaran dan data
  contoh masing-masing fitur; `ProductCatalog` statis dengan harga rupiah, lokasi,
  status stok, dan `SampleBadge`; dokumentasi `docs/ui-flow.md`.
- Skenario daftar, memuat, kosong, gagal, dan offline dapat dicoba lewat pemilih
  skenario. Tombol pemulihan mengembalikan daftar contoh; reduced motion memakai
  indikator memuat statis.
- Branch `feat/ui-commerce-ui-catalog` sudah di-push dan di-merge ke `main` lewat PR #4.
  Commit-nya memakai identitas Git Blessly.
- Pratinjau mandiri: `mobile/lib/features/catalog/sample/catalog_preview.dart`,
  dibuka lewat CodeLens Debug ekstensi Flutter di VS Code pada Android. Tab Produk
  di app shell belum disambungkan karena berkasnya milik Tariq.
- Verifikasi proyek: `flutter analyze` dan `flutter test` sudah dicoba, keduanya
  berhenti pada resolusi dependensi karena Dart lokal 3.9.2 tidak memenuhi
  `sdk: ^3.13.3`. `mobile/pubspec.yaml` tidak diubah.
- Pemeriksaan tambahan: salinan sementara di luar repository memakai batas SDK
  `^3.9.2` dengan Flutter 3.35.7/Dart 3.9.2; `flutter analyze` bersih dan
  `flutter test` 43/43 lulus (10 test baru). Cakupan meliputi state, pemulihan,
  lebar 360 dp, skala teks 1,3, target sentuh, reduced motion, serta model kasir.
  Hasil salinan ini belum menggantikan verifikasi pada SDK yang diminta proyek.
- Sudah dilanjutkan Tariq: `ProductCatalog` disambungkan ke tab Katalog pada branch
  `feat/ui-shell-integrasi-katalog`, beserta test integrasinya.
- Belum: verifikasi pada SDK sesuai proyek dan pratinjau pada perangkat Android.
  Pencarian, filter, dan formulir kini dicatat pada Fase 1–2 di bawah.

### Fase 1 — Kerangka aplikasi dan komponen dasar

**Tariq — review (2026-09-25)**

- Lingkup: app shell, routing, navigasi bawah empat tab, dan komponen dasar di
  `core/widgets` (`PrimaryAction`, `AppCard`, `AppTextField`, `AppBottomSheet`,
  `AppDialog`, `BrandSpinner`, `RyanAppLogo`).
- Berkas penting: `mobile/lib/app/shell/app_shell.dart`,
  `mobile/lib/app/routing/app_router.dart`,
  `mobile/lib/core/widgets/widgets.dart`.
- Verifikasi: `flutter analyze` bersih, `flutter test` 15/15 lulus.
- Belum: tampilan belum dijalankan di emulator Android dan PR belum ditinjau.
- Catatan: `RyanAppLogo` kini memuat aset brand dari
  `RyanAppLogo.defaultAssetPath` pada splash dan app bar, dengan penanda sementara
  sebagai cadangan bila aset gagal dimuat.

**Farel — review (2026-10-02)**

- Lingkup: `StoreFloorPlan` mode lihat (zoom/pan, interaktif) dan `ModeSwitch` (opsi 360° nonaktif saat belum tersedia panorama).
- Berkas penting: `mobile/lib/features/floor_plan/view/store_floor_plan.dart`, `mobile/lib/features/floor_plan/view/mode_switch.dart`.
- Verifikasi: (segera diuji dengan analyzer).
- Belum: Tinjauan PR.

**Blessly — review (2026-11-06).** Pencarian, filter, dan urutan katalog sudah
tersedia; kerangka `ProductForm` sudah terhubung ke alur tambah/edit produk. Widget
test katalog dan validasi formulir berjalan pada salinan pratinjau sementara.
Belum: verifikasi dengan SDK proyek dan tinjauan PR.

### Fase 2 — Splash, onboarding, dan dashboard

**Tariq — review (2026-09-25)**

- Lingkup: splash dengan signature motion 1,45 detik dan crossfade 280 ms,
  `OnboardingCarousel` tiga halaman yang dapat dilewati, serta dashboard bento dengan
  satu aksi utama dan tiga pintasan.
- Berkas penting: `mobile/lib/app/splash/splash_screen.dart`,
  `mobile/lib/features/onboarding/view/onboarding_screen.dart`,
  `mobile/lib/features/dashboard/view/dashboard_screen.dart`.
- Verifikasi: `flutter analyze` bersih, `flutter test` 23/23 lulus, termasuk pengujian
  pada lebar layar 360 dp.
- Belum: tampilan belum dijalankan di emulator Android dan PR belum ditinjau.
- Catatan: penanda "sudah melihat perkenalan" masih ada di memori
  (`AppStartupState`), jadi perkenalan muncul sekali per sesi; penyimpanan tetap
  menyusul bersama lapisan data. Tab Denah kini menampilkan dashboard, dan kanvas denah
  Farel disambungkan di sana pada Fase 3.

**Farel — belum.** Mode edit denah dan `SyncPill` belum dikerjakan.

**Blessly — review (2026-11-06).** Layar detail dan formulir produk sudah ada.
Formulir kini punya bagian pratinjau foto contoh, validasi angka dan barcode ganda,
serta susunan input satu kolom untuk layar kecil. Pratinjau foto belum memilih atau
menyimpan berkas gambar. Pada salinan sementara dengan Dart 3.9.2,
`flutter analyze` bersih dan `flutter test` 71/71 lulus; pratinjau Chrome dapat
dijalankan. Pada proyek utama, kedua perintah belum dapat melewati resolusi
dependensi karena SDK lokal 3.9.2 tidak memenuhi syarat `^3.13.2`.
Belum: verifikasi pada SDK proyek, perangkat Android, dan tinjauan PR.

### Fase 3 — Denah operasional dan pemindai

**Tariq — review (2026-09-25), kecuali penyambungan ke kasir**

- Lingkup yang selesai: keadaan sesi peran pengguna di `core/session/`, halaman
  pengaturan, dan status ketersediaan mode edit denah. Aksi "Mulai pindai" sudah
  ditempatkan di dashboard pada Fase 2.
- Berkas penting: `mobile/lib/core/session/app_session.dart`,
  `mobile/lib/features/settings/view/settings_screen.dart`.
- Verifikasi: `flutter analyze` bersih, `flutter test` 28/28 lulus.
- Belum: tampilan belum dijalankan di emulator Android dan PR belum ditinjau.
- Ditunda sesuai urutan kerja: "menyambungkan navigasi ke kasir" menunggu pemindai
  Blessly, karena rute pemindai didaftarkan bersamanya.

**Farel — belum.** Bottom sheet produk per fixture dan sorot rak hasil pemindaian belum
dikerjakan.

**Blessly — review (2026-11-06).** `ProductScanner` kini memakai simulasi yang
dimulai lewat tombol, dengan state siap, memuat, hasil, kosong, izin ditolak,
gagal, offline, dan produk masuk keranjang. Pencarian manual tidak memilih
produk lain ketika kata kunci tidak cocok; hasil harus dikonfirmasi sebelum
masuk keranjang. Lampu dan keyakinan hasil diberi label simulasi.
- Berkas penting: `mobile/lib/features/scanner/view/product_scanner_screen.dart`,
  `.../view/manual_product_search_screen.dart`, dan
  `.../view_model/scanner_view_model.dart`.
- Verifikasi salinan sementara dengan Dart 3.9.2: `flutter analyze` bersih,
  `flutter test` 75/75 lulus, termasuk lebar 360 dp, skala teks 1,3, dan target
  sentuh. Pada proyek utama, kedua perintah masih tertahan karena SDK lokal
  3.9.2 tidak memenuhi syarat `^3.13.2`.
- Belum: verifikasi pada SDK proyek, perangkat Android, tinjauan PR, serta
  kamera dan deteksi nyata yang memang di luar cakupan UI tahap ini.

### Fase 4 — Pembayaran, panorama, dan laporan

**Tariq — review (2026-09-25)**

- Lingkup: layar riwayat dan laporan transaksi dengan data contoh, lengkap dengan
  state memuat, kosong, dan gagal yang dapat dicoba lewat pemilih skenario contoh.
- Berkas penting: `mobile/lib/features/reports/view/reports_screen.dart`,
  `mobile/lib/core/format/rupiah.dart`, `mobile/lib/core/widgets/sample_badge.dart`.
- Verifikasi: `flutter analyze` bersih, `flutter test` 33/33 lulus.
- Belum: tampilan belum dijalankan di emulator Android dan PR belum ditinjau.
- Catatan: layar dibuka dari pintasan "Riwayat transaksi" di dashboard lewat rute
  `/riwayat`. Metode pembayaran pada riwayat masih model lokal, dan disatukan dengan
  fitur pembayaran Blessly setelah fitur itu ada.

**Farel — belum.** Viewer panorama 360 belum dikerjakan.

**Blessly — belum.** `CartCheckout` dan `PaymentSheet` belum dikerjakan.

## Catatan untuk agen AI

- Baca `AGENTS.md` lebih dahulu, lalu `TEAM.md`, lalu berkas ini untuk mengetahui posisi
  proyek sebelum menulis kode.
- Token tema sudah tersedia sejak Fase 0. Pakai `Theme.of(context)`, `AppColors`,
  `AppSpacing`, dan `AppRadius`; jangan menulis warna, ukuran teks, atau jarak langsung.
- Setelah Fase 1 di-merge, komponen dasar dapat diimpor dari
  `package:ryangunshop/core/widgets/widgets.dart`. Pakai komponen itu, jangan membuat
  versi tandingan di dalam folder fitur.
- `mobile/lib/app/**` dan `mobile/lib/core/**` milik Tariq. Jangan menyuntingnya tanpa
  pull request.
- Belum ada pekerjaan backend, sesuai cakupan tahap ini. Semua layar memakai data contoh
  lokal di folder `sample/` pada fitur masing-masing.
- Peran pengguna ada di `core/session/`. Baca dengan `AppSessionScope.of(context)` dan
  periksa `canEditFloorPlan` sebelum menampilkan mode edit denah; jangan menyalin peran
  ke variabel lokal fitur.
- Nominal rupiah lewat `formatRupiah` di `core/format/rupiah.dart`, dan data contoh
  ditandai `SampleBadge` dari `core/widgets/widgets.dart`.
- Alur pembuka aplikasi: splash menuju perkenalan (sekali per sesi), lalu kerangka utama.
  Rutenya terdaftar di `mobile/lib/app/routing/app_router.dart`.
- Keempat tab sudah memakai fitur aslinya. Tab Kasir memakai `CartCheckoutScreen`,
  pemindai dan keranjang tersambung lewat `mobile/lib/app/shell/app_shell.dart`, dan rute
  `AppRoutes.scanner`, `AppRoutes.panorama`, serta `AppRoutes.productForm` sudah terdaftar.
