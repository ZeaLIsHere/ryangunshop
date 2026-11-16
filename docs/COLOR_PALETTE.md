# RyanGunshop — Palet Warna (Violet Commerce POS)

Status: **15 November 2026**. Identitas violet tetap dikunci; bukan perubahan
palet. Dokumen ini adalah rujukan token warna yang dipakai `DESIGN.md`. Nilai di sini
dipasang sebagai token di `mobile/lib/core/theme/app_colors.dart`. Widget tidak
boleh menulis nilai heksadesimal secara langsung.

## Peran warna

| Nama | Token | Heksadesimal | Peran |
|---|---|---|---|
| Primary | `AppColors.primary` | `#7C3AED` | Tindakan utama, konfirmasi checkout, navigasi aktif |
| Primary dark | `AppColors.primaryDark` | `#6D28D9` | Gradien hero card, app bar kontras, state tekan |
| Primary light | `AppColors.primaryLight` | `#EDE9FE` | Pilihan sekunder, latar pill aktif, batas chip |
| Primary subtle | `AppColors.primarySubtle` | `#F5F3FF` | Latar wadah ikon aksi cepat (*action pods*) |
| Accent | `AppColors.accent` | `#A855F7` | Laser scan, fokus, progress bar, aksen visual |
| Canvas | `AppColors.canvas` | `#FAF8FE` | Latar aplikasi (ultra-clean tonal violet-white) |
| Surface | `AppColors.surface` | `#FFFFFF` | Lembar kerja kasir, kartu produk, dan sheet |
| Ink | `AppColors.ink` | `#0F172A` | Teks utama, judul halaman, dan angka nominal |
| Muted | `AppColors.muted` | `#64748B` | Teks pendukung, SKU, metadata rak |
| Border subtle | `AppColors.borderSubtle` | `#EDE8F5` | Garis tepi kartu dan pembatas halus |
| Success | `AppColors.success` | `#10B981` | Tersimpan, tersinkron, pembayaran lunas, stok aman |
| Warning | `AppColors.warning` | `#F59E0B` | Stok menipis, peringatan, tindakan belum selesai |
| Error | `AppColors.error` | `#EF4444` | Gagal bayar, gagal sinkron, stok habis |

## Aturan pemakaian

- Warna violet (`primary`, `primaryDark`, `primaryLight`, `accent`) memandu tindakan,
  pilihan aktif, dan status interaktif. Permukaan pasif tetap netral (`canvas`, `surface`, `ink`, `muted`).
- Status tidak boleh disampaikan lewat warna saja; selalu pasangkan ikon dan teks.
- Teks utama selalu `ink` di atas `canvas` atau `surface`. Teks pendukung memakai
  `muted` dan tidak dipakai untuk informasi yang wajib terbaca cepat.
- Warna diambil dari `Theme.of(context).colorScheme` bila perannya sudah tersedia;
  gunakan `AppColors` langsung untuk peran spesifik seperti status atau gradient hero.

## Ramp turunan

| Langkah | Heksadesimal | Peran |
|---|---|---|
| Violet-50 | `#FAF5FF` | Latar selang-seling tabel / hover sangat halus |
| Violet-100 | `#F5F3FF` | `primarySubtle`, wadah ikon aksi cepat |
| Violet-200 | `#EDE9FE` | `primaryLight`, pill aktif, border chip |
| Violet-300 | `#DDD6FE` | Border badge terpilih |
| Violet-400 | `#C4B5FD` | Aksen fokus sekunder |
| Violet-500 | `#8B5CF6` | Sudut bidik kamera pemindai |
| Violet-600 | `#7C3AED` | `primary`, tombol utama kasir, FAB |
| Violet-700 | `#6D28D9` | `primaryDark`, gradien hero tengah |
| Violet-800 | `#5B21B6` | Gradien hero gelap |
| Violet-900 | `#4C1D95` | Kode barcode terverifikasi, teks penekanan gelap |

## Aturan kontras

Rasio berikut dihitung ulang dengan luminansi relatif sRGB WCAG, dibulatkan
dua desimal, untuk warna solid tanpa opacity. Ini bukan audit seluruh UI atau
bukti keterbacaan pada perangkat fisik. Ambang teks normal 4.5:1:

| Pasangan | Pemakaian | Rasio | Ambang WCAG |
|---|---|---|---|
| Ink di atas Canvas | Teks utama pada latar aplikasi | 16.94:1 | Lulus 4.5:1 |
| Ink di atas Surface | Teks utama pada kartu & sheet | 17.85:1 | Lulus 4.5:1 |
| Muted di atas Surface | Teks pendukung pada kartu | 4.76:1 | Lulus 4.5:1 |
| Muted di atas Canvas | Metadata pada latar | 4.51:1 | Lulus 4.5:1, margin tipis |
| Surface di atas Primary | Label tombol utama | 5.70:1 | Lulus 4.5:1 |
| PrimaryDark di atas PrimaryLight | Teks pada pill lavender | 5.98:1 | Lulus 4.5:1 |
| Error di atas Surface | Warna status dasar, bukan teks normal | 3.76:1 | Tidak lulus 4.5:1 |
| Success di atas Surface | Warna status dasar, bukan teks normal | 2.54:1 | Tidak lulus 4.5:1 |
| Warning di atas Surface | Warna status dasar, bukan teks normal | 2.15:1 | Tidak lulus 4.5:1 |

Warna dasar status tetap boleh menyampaikan aksen, tetapi label teks membutuhkan
pasangan foreground/background yang memenuhi ambang. Jangan mengklaim seluruh
badge atau ikon memenuhi kontras hanya dari tabel ini; batas nonteks juga perlu
pemeriksaan tersendiri. Pertahankan ikon dan teks untuk makna status, serta
verifikasi gradien, opacity, dan state aktual. Dokumentasi tidak mengubah kode
tema atau menyatakan audit perangkat sudah lulus.
