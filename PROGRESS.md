# RyanGunshop — Status Pengerjaan

Papan status hidup proyek. `TEAM.md` berisi rencana, sedangkan berkas ini berisi
keadaan nyata, supaya anggota tim dan agen AI mereka tahu sudah sampai mana proyek
berjalan tanpa harus menebak dari riwayat commit.

## Aturan pembaruan

- Perbarui baris Anda di sini **pada pull request yang sama** dengan tugas yang
  diselesaikan. Jangan menumpuk pembaruan status sampai akhir fase.
- Satu orang hanya menyunting baris miliknya sendiri. Pemilik berkas tetap Tariq sesuai
  peta kepemilikan di `TEAM.md`.
- Legenda: `belum` · `jalan` · `review` · `selesai`. Pakai `review` bila kode dan
  pengujian sudah selesai tetapi verifikasi emulator atau tinjauan PR belum ada, dan
  `selesai` hanya bila seluruh poin "Definisi selesai" di `TEAM.md` terpenuhi.

## Ringkasan fase

| Fase | Tariq | Farel | Blessly |
|---|---|---|---|
| 0 — Fondasi UI dan aset | selesai | review | belum |
| 1 — Kerangka aplikasi dan komponen dasar | review | belum | belum |
| 2 — Splash, onboarding, dan dashboard | review | belum | belum |
| 3 — Denah operasional dan pemindai | review | belum | belum |
| 4 — Pembayaran, panorama, dan laporan | review | belum | belum |
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
| Denah dan objek ruang | `mobile/lib/features/floor_plan/` | Farel | belum |
| Panorama 360 | `mobile/lib/features/panorama/` | Farel | belum |
| Katalog produk | `mobile/lib/features/catalog/` | Blessly | belum |
| Formulir produk | `mobile/lib/features/catalog/` | Blessly | belum |
| Pemindai produk | `mobile/lib/features/scanner/` | Blessly | belum |
| Keranjang dan pembayaran | `mobile/lib/features/checkout/`, `.../payment/` | Blessly | belum |

## Catatan per tugas

### Fase 0 — Fondasi UI dan aset

**Tariq — selesai (2026-09-25)**

- Lingkup: proyek Flutter Android (minSdk 26), struktur `lib/`, token tema,
  `docs/COLOR_PALETTE.md`, konfigurasi pratinjau Android di `.vscode/`, `AGENTS.md`,
  dan `TEAM.md`.
- Berkas penting: `mobile/lib/core/theme/app_theme.dart`,
  `mobile/lib/core/theme/app_colors.dart`, `docs/COLOR_PALETTE.md`.
- Verifikasi: `flutter analyze` bersih, `flutter test` 4/4 lulus.
- Belum: tampilan belum dijalankan di emulator atau perangkat Android.

**Farel — review (2026-09-25)**

- Lingkup: Skema koordinat denah (FixtureModel), komponen `FixtureTile` dasar, aset brand, dan `tool/generate_brand_assets.dart`.
- Berkas penting: `mobile/lib/features/floor_plan/model/fixture_model.dart`, `mobile/lib/features/floor_plan/view/fixture_tile.dart`.
- Verifikasi: (segera diuji dengan analyzer dan test).
- Belum: Tinjauan PR.

**Blessly — belum.** Model UI katalog, layar `ProductCatalog` statis, dan
`docs/ui-flow.md` belum ada.

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
- Catatan: isi tiap tab masih tampilan sementara sampai Farel dan Blessly mengirim
  fiturnya. `RyanAppLogo` memakai penanda sementara karena aset logo belum ada; oper
  `RyanAppLogo.defaultAssetPath` setelah asetnya didaftarkan di `pubspec.yaml`.

**Farel — belum.** `StoreFloorPlan` mode lihat dan `ModeSwitch` belum dikerjakan.

**Blessly — belum.** Pencarian dan filter `ProductCatalog` serta kerangka `ProductForm`
belum dikerjakan.

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

**Blessly — belum.** `ProductForm` lengkap dan layar detail produk belum dikerjakan.

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

**Blessly — belum.** `ProductScanner` belum dikerjakan.

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
