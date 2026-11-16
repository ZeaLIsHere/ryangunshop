# RyanGunshop

Aplikasi kasir dan pengelolaan warung Android berbasis Flutter/Dart,
offline-first dengan SQLite/Drift. Mini-SRS menjadi sumber requirement,
bukan bukti seluruh fitur sudah berjalan di produksi.

## Status — 15 November 2026

Branch integrasi: `feat/ui-shell-owner-barcode`. Tahap UI-only sudah dilewati;
integrasi lintas fitur berikut disetujui pengguna.

| Area | Kondisi berjalan |
|---|---|
| POS lokal | Produk, stok, draft keranjang, nota tunai, snapshot item, dan pengurangan stok memakai SQLite/Drift; database baru kosong |
| Peran | Pemilik/kasir dipilih di Pengaturan tanpa login/PIN; kelola produk hanya pemilik, izin dibaca ulang saat simpan; bukan batas keamanan |
| Beranda kasir | Hero Omzet asli, laporan harian, empat bento Aksi Cepat, nota terkini |
| Beranda pemilik | Analitik repository Hari ini/7 hari/30 hari, grafik, perhatian stok, produk terlaris, nota, dan aksi kelola |
| Komponen Beranda | Hero/aksi/nota bersama; Pintasan Menu pada kedua peran: katalog, keranjang, riwayat, pengaturan, statistik, chatbot |
| Produk | Judul `Produk`, tanpa badge lokal; grid lazy 2 kolom pada 360 dp, 3 pada 600 dp, 5 pada 1024 dp, aman pada text scale 1.3 dalam pengujian otomatis |
| Barcode | Kamera `mobile_scanner` nyata, fallback manual, generator kode internal RG dan label Code128 untuk pemilik |
| Laporan | PDF/XLSX harian dari repository, berbagi Android; bukan penyimpanan otomatis ke Downloads |
| IyanBoT | Groq dengan tool baca dan draft; transaksi/produk perlu konfirmasi sebelum disimpan; produk hanya pemilik; live API belum terverifikasi dan pengujian dijeda pengguna |
| Firebase | Native bersakelar `FIREBASE_ENABLED`, outbox SQLite, pengurasan saat startup/perubahan sesi dan tiap 15 detik selama aplikasi berjalan |
| QRIS | Jalur simulasi tersedia; pembayaran QRIS nyata belum terverifikasi |
| Denah/360 | Arsip fitur, bukan navigasi utama |

Laba historis belum dihitung karena snapshot harga modal transaksi belum tersedia.
Produk terlaris menampilkan penjualan kotor sebelum diskon nota, bukan laba.
Inisialisasi Firebase bukan bukti unggah cloud. Produk lama tidak otomatis masuk
outbox; belum ada jaminan backfill, pemulihan cloud, atau isolasi tenant produksi.
Timer sinkronisasi bukan layanan latar belakang Android. Web hanya pratinjau,
tanpa SQLite/sinkronisasi native. POS lokal tidak memerlukan `backend-agent`.

## Tim dan dokumen

| Nama | NIM |
|---|---|
| M. Al Farel Azhar | 241401009 |
| Tariq Rahmadari | 241401021 |
| Blessly Victory Deo Silaban | 241401060 |

| Berkas | Isi |
|---|---|
| [AGENTS.md](AGENTS.md) | Aturan kerja dan cakupan integrasi yang disetujui |
| [PRODUCT.md](PRODUCT.md) | Pengguna, pengalaman, status nyata, dan batas produk |
| [DESIGN.md](DESIGN.md) | Token visual, komponen, dan interaksi |
| [TEAM.md](TEAM.md) | Kepemilikan, riwayat pembagian tugas, dan review |
| [PROGRESS.md](PROGRESS.md) | Status tugas, bukti pengujian, dan riwayat pengerjaan |
| [instruksi.md](instruksi.md) | Operasi dan verifikasi sinkronisasi Firebase |

Panduan tambahan: `docs/firebase-setup.md`, `docs/firestore-schema.md`,
`docs/COLOR_PALETTE.md`, `docs/ui-flow.md`, dan `docs/a11y.md`.
Baca catatan historis sesuai tanggalnya; persiapan layanan bukan bukti produksi.

## Struktur

```text
mobile/
├── lib/
│   ├── main.dart
│   ├── app/                 # shell, routing, startup, pemicu sinkronisasi
│   ├── core/
│   │   ├── config/          # konfigurasi build dan bootstrap Firebase
│   │   ├── data/            # Drift, repository, migrasi, outbox, sinkronisasi
│   │   ├── session/         # sesi/peran dan keadaan lintas fitur
│   │   ├── format/          # format rupiah
│   │   ├── theme/           # token visual
│   │   └── widgets/         # komponen dasar
│   └── features/<nama_fitur>/
│       ├── model/
│       ├── view_model/
│       ├── view/
│       └── sample/          # data pratinjau, bukan data usaha
├── test/                    # pengujian unit, repository, widget, dan alur
└── android/                 # Android min API 26
firebase/                    # aturan dan indeks; deploy bukan bukti akses aman
docs/                        # panduan fitur, Firebase, dan aksesibilitas
```

## Menjalankan dan memvalidasi

Dari root proyek:

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

Untuk regenerasi tabel Drift: `dart run build_runner build` dari `mobile/`.
Sertakan `app_database.g.dart` bersama perubahan skema/migrasi dalam PR.

VS Code: pasang extension Dart/Flutter, pilih emulator/perangkat, lalu konfigurasi
**RyanGunshop — Android Preview** di Run and Debug dan tekan `F5`.
Konfigurasi workspace ada di `.vscode/`. Validasi Android memakai emulator atau
perangkat; `flutter run -d chrome` hanya untuk inspeksi susunan layar.

### Build Android dengan konfigurasi privat

Berkas `.env` privat disediakan pengelola di root proyek. Jangan membaca,
menyalin, menampilkan, atau commit isinya untuk dokumentasi. Build lokal tanpa
konfigurasi layanan tetap tersedia lewat `flutter build apk --debug`.

Dari `mobile/`, perintah `sh` yang dipakai pada build terakhir:

```sh
JAVA_TOOL_OPTIONS=-Dorg.gradle.project.kotlin.incremental=false flutter build apk --debug --dart-define-from-file=../.env
```

Untuk PowerShell, assignment environment terpisah:

```powershell
$env:JAVA_TOOL_OPTIONS = '-Dorg.gradle.project.kotlin.incremental=false'
flutter build apk --debug --dart-define-from-file=../.env
```

APK: `mobile/build/app/outputs/flutter-apk/app-debug.apk`. Opsi Kotlin tersebut
merupakan workaround build debug yang dipakai, bukan perubahan konfigurasi sumber.
`--dart-define` tidak menyembunyikan secret dalam APK. Jangan memasukkan service
account, private key, atau secret pembayaran. Groq/Firebase memerlukan jaringan,
dapat menimbulkan biaya, dan dapat mengirim data toko ke penyedia.

### Pemeriksaan perangkat

- Lebar 360 dp dan text scale 1.3: gulir kedua Beranda, semua Pintasan Menu,
  Produk, formulir, dan checkout; periksa overflow serta target sentuh ≥48 dp.
- Uji offline: buat produk sebagai pemilik, cari/pindai, bayar tunai, tutup/buka
  aplikasi; produk, draft, nota, dan stok harus konsisten.
- Uji izin kamera ditolak, barcode asing, fallback manual, dan pelepasan kamera
  selama checkout. Ganti peran sebelum simpan untuk memeriksa ulang izin.
- Bagikan laporan PDF/XLSX hari yang benar; periksa isi, bukan hanya sheet berbagi.
- Cetak label ukuran aktual 100%, tanpa penyesuaian halaman, lalu pindai hasil.
  Kode RG/Code128 bukan EAN/GS1; barcode kemasan yang ada tidak diganti.
- Uji outbox dan dokumen cloud dengan prosedur `instruksi.md`; jangan menyamakan
  status SDK siap atau antrean kosong dengan semua produk sudah terunggah.

## Bukti validasi terakhir

Hasil terakhir yang dilaporkan, bukan eksekusi ulang saat penyuntingan dokumen:

- `flutter analyze --no-pub`: bersih.
- `flutter test --no-pub --reporter expanded`: **212/212 lulus**.
- 15 November 2026: APK debug dibangun sekitar **51 detik**, dipasang memakai
  `adb install -r`, dan diluncurkan pada Samsung **SM_A366B**, perangkat
  `RRGYC07G09Z`. Pemasangan ulang mempertahankan data, bukan uninstall/reset.
- UI fisik menyeluruh, alur pemindaian penuh, cetak label/struk, live cloud,
  serta live Groq **belum terverifikasi**. Peluncuran APK tidak membuktikan
  semua alur tersebut lulus.

## Riwayat dan tahap berikutnya

Rilis historis `v0.6.0-ui` menyelesaikan tahap UI dengan 90 test dan data contoh.
Fondasi lokal, kamera nyata, laporan, analitik pemilik, label, Groq, serta outbox
kemudian ditambahkan. Klaim data sesi/contoh pada rilis lama bukan kondisi POS
Android sekarang; riwayat rinci tetap di `PROGRESS.md`.

Belum selesai atau belum terverifikasi untuk produksi:

- Login/PIN, identitas tepercaya, claim/keanggotaan toko, serta pengujian isolasi
  tenant dan aturan Firestore. Pilihan peran di Pengaturan bukan pengaman.
- Bukti unggah cloud nyata, backfill produk lama, pemulihan perangkat baru,
  strategi konflik, dan sinkronisasi latar belakang Android bila dibutuhkan.
- QRIS resmi: charge dan secret di server, signature/webhook tervalidasi sebelum
  pembayaran dinyatakan berhasil.
- Cetak fisik, snapshot modal untuk laba historis, serta rencana restok berbasis
  penjualan, lead time, stok pengaman, dan target persediaan.
- Foto koreksi privat dengan consent, penghapusan EXIF/GPS, retensi dan akses
  tenant-scoped yang diuji; model TFLite beserta kalibrasi perangkat.
- WhatsApp/Ollama `backend-agent` sebagai pengembangan terpisah, bukan langkah
  instalasi yang diperlukan untuk POS lokal.

Dependensi/layanan baru perlu persetujuan dan PR. Pertahankan kepemilikan berkas,
review lintas anggota, serta larangan commit rahasia sesuai `AGENTS.md`/`TEAM.md`.
