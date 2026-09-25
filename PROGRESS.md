# RyanGunshop — Status Pengerjaan

Papan status hidup proyek. `TEAM.md` berisi rencana, sedangkan berkas ini berisi
keadaan nyata, supaya anggota tim dan agen AI mereka tahu sudah sampai mana proyek
berjalan tanpa harus menebak dari riwayat commit.

## Aturan pembaruan

- Perbarui baris Anda di sini **pada pull request yang sama** dengan tugas yang
  diselesaikan. Jangan menumpuk pembaruan status sampai akhir fase.
- Satu orang hanya menyunting baris miliknya sendiri. Pemilik berkas tetap Tariq sesuai
  peta kepemilikan di `TEAM.md`.
- Legenda: `belum` · `jalan` · `selesai`. Status `selesai` baru diberikan bila seluruh
  poin "Definisi selesai" di `TEAM.md` terpenuhi, termasuk `flutter analyze` dan
  `flutter test` yang lulus.

## Ringkasan fase

| Fase | Tariq | Farel | Blessly |
|---|---|---|---|
| 0 — Fondasi UI dan aset | selesai | belum | belum |
| 1 — Kerangka aplikasi dan komponen dasar | jalan | belum | belum |
| 2 — Splash, onboarding, dan dashboard | belum | belum | belum |
| 3 — Denah operasional dan pemindai | belum | belum | belum |
| 4 — Pembayaran, panorama, dan laporan | belum | belum | belum |
| 5 — Audit aksesibilitas dan rilis internal | belum | belum | belum |

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

**Farel — belum.** Skema koordinat denah, `FixtureTile`, aset brand, dan
`tool/generate_brand_assets.dart` belum ada.

**Blessly — belum.** Model UI katalog, layar `ProductCatalog` statis, dan
`docs/ui-flow.md` belum ada.

### Fase 1 — Kerangka aplikasi dan komponen dasar

**Tariq — jalan.** Sedang membangun app shell, routing, navigasi bawah, dan komponen
dasar di `core/widgets`.

**Farel — belum.** `StoreFloorPlan` mode lihat dan `ModeSwitch` belum dikerjakan.

**Blessly — belum.** Pencarian dan filter `ProductCatalog` serta kerangka `ProductForm`
belum dikerjakan.

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
