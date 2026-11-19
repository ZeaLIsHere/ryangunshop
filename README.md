# RyanGunshop

Aplikasi kasir dan pengelolaan warung Android berbasis Flutter/Dart,
cloud-first pada native dengan cache dan operasi offline SQLite/Drift.
Web hanya pratinjau lokal. Mini-SRS menjadi sumber requirement,
bukan bukti seluruh fitur sudah berjalan di produksi.

## Status — 19 November 2026

Branch integrasi: `feat/ui-shell-owner-barcode`. Tahap UI-only sudah dilewati;
integrasi lintas fitur berikut disetujui pengguna. Basis kode terakhir dipush:
`a85a159`. Fondasi Monitor mulai dibangun atas persetujuan pengguna; belum UI aktif.

| Area | Kondisi berjalan |
|---|---|
| POS lokal | Produk, stok, draft keranjang, nota tunai, snapshot item, dan pengurangan stok memakai SQLite/Drift; database baru kosong |
| Peran | Pemilik/kasir dipilih di Pengaturan tanpa login/PIN; kelola produk hanya pemilik, izin dibaca ulang saat simpan; bukan batas keamanan |
| Beranda kasir | Hero Omzet asli, laporan harian, empat bento Aksi Cepat, nota terkini |
| Beranda pemilik | Analitik repository Hari ini/7 hari/30 hari, Smooth Area Line Chart bergradien violet interaktif, Status Stok, Bento Aksi Kelola, produk terlaris, dan nota |
| Statistik | Layar statistik berbasis Bento Grid Asimetris Fungsional: estimasi nilai aset toko, omzet, kesehatan inventaris, efisiensi margin, dan komposisi kategori |
| Komponen Beranda | Hero/aksi/nota bersama; Pintasan Menu pada kedua peran dengan perataan tinggi kartu (`IntrinsicHeight`): katalog, keranjang, riwayat, pengaturan, statistik, chatbot |
| Produk | Judul `Produk`, tanpa badge lokal; grid lazy 2 kolom pada 360 dp, 3 pada 600 dp, 5 pada 1024 dp, aman pada text scale 1.3 dalam pengujian otomatis |
| Barcode | Kamera `mobile_scanner` nyata, fallback manual, generator kode internal RG dan label Code128 untuk pemilik |
| Laporan | PDF/XLSX harian dari repository, berbagi Android; bukan penyimpanan otomatis ke Downloads |
| IyanBoT | Groq dengan tool baca dan draft; transaksi/produk perlu konfirmasi sebelum disimpan; produk hanya pemilik; live API belum terverifikasi dan pengujian dijeda pengguna |
| Firebase | Native bersakelar `FIREBASE_ENABLED`; `CloudReadThrough` cloud-first, cache hasil server 15 detik, backoff 30 detik, timeout 8 detik lalu fallback cache; outbox saat startup/perubahan sesi dan tiap 15 detik selama aplikasi berjalan |
| Konsistensi UI | Perubahan tertunda dilindungi dari cloud usang; revisi data sesi memperbarui dashboard, katalog, statistik, dan laporan |
| Monitor | Isometrik native, editor drag, tiga template, penempatan massal dan alert stok tersedia lokal; jalur sync layout ditulis, belum diuji live |
| QRIS | Jalur simulasi tersedia; pembayaran QRIS nyata belum terverifikasi |
| Denah/360 | Arsip fitur, bukan navigasi utama |

Laba historis belum dihitung karena snapshot harga modal transaksi belum tersedia.
Produk terlaris menampilkan penjualan kotor sebelum diskon nota, bukan laba.
Impor Firestore `iyangunshop` / `stores/toko-utama` terverifikasi: 90 dokumen
dibuat dan terbaca ulang, 24 produk, 66 nota tunai, 394 unit, Rp3.035.800.
Rentang data presentasi 10–24 November 2026 inklusif (15 hari, 3–6 nota/hari),
termasuk tanggal setelah hari verifikasi. Tanpa label visual demo; metadata asal
internal. Ini bukan klaim penjualan aktual atau bukti unduh data lewat aplikasi.

Produk lama tidak otomatis masuk outbox; belum ada jaminan backfill atau
pemulihan perangkat baru. Stok lintas perangkat masih last-write-wins, bukan
atomik. Tidak ada snapshot atomik lintas halaman/koleksi; batas 10.000 dokumen
per koleksi. Full scan tetap memakai read Firestore sesuai jumlah dokumen.
Timer sinkronisasi bukan layanan latar belakang Android. Web hanya pratinjau
lokal tanpa SQLite/cloud-first native. POS lokal tidak memerlukan `backend-agent`.

**Batas keamanan:** akses baca tanpa autentikasi diketahui menghasilkan HTTP 200.
Rules tidak diubah; pengguna menolak tambahan login/PIN/Anonymous Auth. Impor
berhasil bukan bukti isolasi tenant atau keamanan produksi.

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
| [docs/monitor-plan.md](docs/monitor-plan.md) | Rencana dan status pembangunan Monitor |

Panduan tambahan: `docs/firebase-setup.md`, `docs/firestore-schema.md`,
`docs/COLOR_PALETTE.md`, `docs/ui-flow.md`, dan `docs/a11y.md`.
Baca catatan historis sesuai tanggalnya; persiapan layanan bukan bukti produksi.

## Monitor — UI lokal, validasi cloud/perangkat berikutnya

Tombol Beranda pemilik membuka halaman isometrik 2.5D ringan dari atas, Flutter
native tanpa engine/dependensi baru. Tanpa login atau tab baru; navigasi tetap.
Penyiapan: pilih salah satu dari tiga template (rak dinding, dua baris,
rak dinding + tengah), lalu tempatkan produk lewat filter massal dan konfirmasi
manual. Produk tanpa lokasi boleh ditunda.

Satu fixture utama per produk memakai `fixtureId`, `locationLabel`, dan ambang
stok yang ada; hitungan stok tetap dari repository. Mode Pantau terpisah dari
Edit: snap ke grid, tambah/nama/pindah/putar 90°/hapus rak, kulkas, atau meja kasir.
Draft memakai Simpan/Batal dan konfirmasi saat keluar. Hapus fixture hanya
melepas penempatan produk; pindah fixture tidak mengubah stok. Kuantitas fisik
per lokasi dan deteksi otomatis tidak didukung.

Ponsel memakai bottom sheet, tablet panel samping; target ≥48 dp, lebar 360 dp,
text scale 1.3, state kosong/memuat/error/offline. Arsip `floor_plan` wajib diaudit
sebelum digunakan ulang, bukan diaktifkan dengan data contoh. Detail mengikuti
[rencana kanonis](docs/monitor-plan.md); usulan peran di `TEAM.md` belum mengubah
kepemilikan permanen.

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

Dari `mobile/`, perintah `sh` yang dipakai pada build 15 November
(bukan bukti APK cloud-first sudah dibangun):

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
- Uji unduh data cloud, fallback offline/timeout, perlindungan perubahan tertunda,
  dan pembaruan UI lewat revisi data. Impor terverifikasi bukan bukti alur ini
  sudah berjalan di APK.
- Uji outbox dan dokumen cloud dengan prosedur `instruksi.md`; jangan menyamakan
  status SDK siap atau antrean kosong dengan semua produk sudah terunggah.

## Bukti validasi terakhir

Hasil terakhir yang dilaporkan, bukan eksekusi ulang saat penyuntingan dokumen:

- `flutter analyze --no-pub`: bersih.
- `flutter test --no-pub --reporter expanded`: **268/268 lulus**.
- `node --test mobile/tool/seed_firestore_november.test.mjs`: **12/12 lulus**.
- 20 November 2026: APK debug cloud-first + Monitor (dengan pembaruan Bento Aksi Kelola, Smooth Area Line Chart, dan Bento Grid Statistik) berhasil dibangun sekitar **19–50 detik**, dipasang memakai `adb install -r`, dan diluncurkan pada Samsung **SM_A366B**, perangkat `RRGYC07G09Z`. Pemasangan ulang mempertahankan data lokal.
- UI fisik menyeluruh, alur pemindaian penuh, cetak label/struk, serta live Groq
  **belum terverifikasi**. Peluncuran APK tidak membuktikan semua alur tersebut lulus.

## Riwayat dan tahap berikutnya

Rilis historis `v0.6.0-ui` menyelesaikan tahap UI dengan 90 test dan data contoh.
Fondasi lokal, kamera nyata, laporan, analitik pemilik, label, Groq, serta outbox
kemudian ditambahkan. Klaim data sesi/contoh pada rilis lama bukan kondisi POS
Android sekarang; riwayat rinci tetap di `PROGRESS.md`.

Belum selesai atau belum terverifikasi untuk produksi:

- Pengamanan akses, identitas tepercaya, claim/keanggotaan toko, serta pengujian
  isolasi tenant dan rules. Login/PIN/Anonymous Auth ditolak pengguna; perubahan
  autentikasi perlu persetujuan baru. Pilihan peran bukan pengaman.
- Build/install APK cloud-first, unduh data dan unggah outbox lewat aplikasi,
  backfill produk lama, pemulihan perangkat baru, konflik stok lintas perangkat,
  dan sinkronisasi latar belakang Android bila disetujui.
- Monitor lokal tersedia dengan editor, penempatan dan kanvas; jalur cloud layout
  perlu uji live dan visual Android. Review lintas pemilik tetap berlaku.
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
