# RyanGunshop — Palet Warna

Dokumen ini adalah rujukan token warna yang dipakai `DESIGN.md`. Nilai di sini
dipasang sebagai token di `mobile/lib/core/theme/app_colors.dart`. Widget tidak
boleh menulis nilai heksadesimal secara langsung.

## Peran warna

| Nama | Token | Heksadesimal | Peran |
|---|---|---|---|
| Primary | `AppColors.primary` | `#565C9D` | Tindakan utama dan pilihan aktif |
| Primary dark | `AppColors.primaryDark` | `#34385F` | Splash, app bar kontras, state tekan |
| Primary light | `AppColors.primaryLight` | `#E9EAF6` | Pilihan sekunder, latar ikon, garis pemisah |
| Accent | `AppColors.accent` | `#8B91D4` | Fokus, progress, aksen motion |
| Canvas | `AppColors.canvas` | `#F7F7FB` | Latar aplikasi |
| Surface | `AppColors.surface` | `#FFFFFF` | Lembar kerja dan sheet |
| Ink | `AppColors.ink` | `#191A2E` | Teks utama |
| Muted | `AppColors.muted` | `#62657A` | Teks pendukung |
| Success | `AppColors.success` | `#287A66` | Tersimpan atau tersinkron |
| Warning | `AppColors.warning` | `#A86616` | Stok menipis atau tindakan belum selesai |
| Error | `AppColors.error` | `#B44252` | Gagal bayar, gagal sinkron, stok tidak cukup |

## Aturan pemakaian

- Slate blue (primary, primary dark, primary light, accent) hanya untuk aksi,
  pilihan, dan status. Permukaan pasif tetap netral (canvas, surface, ink, muted).
- Status tidak boleh disampaikan lewat warna saja; selalu pasangkan ikon dan teks.
- Teks utama selalu `ink` di atas `canvas` atau `surface`. Teks pendukung memakai
  `muted` dan tidak dipakai untuk informasi yang wajib terbaca cepat.
- Warna diambil dari `Theme.of(context).colorScheme` bila perannya sudah tersedia;
  gunakan `AppColors` langsung hanya untuk peran yang belum ada di `ColorScheme`.

## Ramp turunan

Empat nilai bertanda sumber adalah token dari `DESIGN.md` dan tidak boleh diubah.
Langkah lain adalah turunan untuk kebutuhan internal seperti garis halus dan state
tekan; turunan dibuat dengan mencampur slate blue ke arah `canvas`/`surface`
(langkah terang) atau ke arah `primaryDark`/`ink` (langkah gelap).

| Langkah | Heksadesimal | Asal |
|---|---|---|
| 50 | `#F4F5FB` | turunan |
| 100 | `#E9EAF6` | sumber (`primaryLight`) |
| 200 | `#C3C6E8` | turunan |
| 300 | `#B7BAE0` | turunan |
| 400 | `#8B91D4` | sumber (`accent`) |
| 500 | `#565C9D` | sumber (`primary`) |
| 600 | `#454A7E` | turunan |
| 700 | `#3E4372` | turunan |
| 800 | `#34385F` | sumber (`primaryDark`) |
| 900 | `#272946` | turunan |

Turunan hanya boleh dipakai sebagai tambahan, bukan pengganti token di tabel peran.

## Aturan kontras

Rasio di bawah adalah perkiraan hasil perhitungan formula kontras WCAG 2.1 dari
nilai token. Ambang minimum adalah 4.5:1 untuk teks inti dan 3:1 untuk grafik,
ikon, serta batas kontrol.

| Pasangan | Pemakaian | Rasio | Ambang |
|---|---|---|---|
| Ink di atas Canvas | Teks utama | ≥ 15:1 | 4.5:1 |
| Ink di atas Surface | Teks utama pada sheet | ≥ 15:1 | 4.5:1 |
| Muted di atas Surface | Teks pendukung | ≥ 5.5:1 | 4.5:1 |
| Muted di atas Canvas | Metadata | ≥ 5:1 | 4.5:1 |
| Surface di atas Primary | Label tombol utama | ≥ 6:1 | 4.5:1 |
| PrimaryDark di atas PrimaryLight | Teks pada pilihan sekunder | ≥ 9:1 | 4.5:1 |
| Error di atas Surface | Pesan gagal | ≥ 5:1 | 4.5:1 |
| Success di atas Surface | Pesan tersimpan | ≥ 5:1 | 4.5:1 |
| Warning di atas Surface | Peringatan stok menipis | ≥ 4.5:1 | 4.5:1 |

Catatan:

- `warning` hanya sedikit di atas ambang pada ukuran 14 sp, jadi pakai bobot
  semi-bold atau dampingi dengan ikon dan teks, jangan sebagai warna tunggal.
- Jangan menaruh teks di atas `accent` atau `primary` tanpa memeriksa ulang rasio,
  karena keduanya dirancang untuk aksen, bukan latar teks panjang.
- Periksa ulang dengan alat pemeriksa kontras sebelum rilis internal bila ada
  warna baru yang ditambahkan.
