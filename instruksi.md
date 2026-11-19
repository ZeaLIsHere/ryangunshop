# Instruksi — Operasi dan Verifikasi Firebase Firestore

Status **19 November 2026**, branch `feat/ui-shell-owner-barcode`, acuan `a85a159`.
Firebase native sudah dikonfigurasi, dengan sakelar `FIREBASE_ENABLED` dan
outbox SQLite. Integrasi cloud telah disetujui pengguna; larangan lama tahap
UI-only tidak berlaku pada cakupan ini. Jangan menganggap SDK siap sebagai
bukti dokumen berhasil terunggah atau seluruh produk sudah tersinkron.

Baca POS Android cloud-first saat Firebase siap, dengan SQLite sebagai cache/
fallback; tulis POS tetap lokal lalu outbox. Web tetap preview lokal tanpa SQLite
atau cloud-first native. APK cloud-first belum dibangun/dipasang; baca native
langsung, unggah outbox perangkat, dan pemulihan perangkat baru belum terverifikasi.
Pengaturan pemilik/kasir bukan login.

Impor berizin 19 November sudah create-only/read-back terverifikasi: 90 dokumen,
24 produk, 66 nota tunai, 394 unit, Rp3.035.800, 10–24 November 2026 inklusif
(15 hari, termasuk tanggal mendatang), `iyangunshop`, `stores/toko-utama`.
Tidak menimpa dokumen lama. Data tampil normal tanpa label; asal metadata internal.
Google Cloud CLI sudah dipasang dan diotorisasi pengguna, tanpa mencetak kredensial.

GET tanpa autentikasi masih HTTP 200: risiko baca publik belum ditutup. Tidak
mengubah rules/auth; pengguna tidak meminta login/PIN/Anonymous Auth. Impor admin
berhasil bukan bukti autentikasi aplikasi atau isolasi tenant aman.

## 1. Komponen yang tersedia

| Bagian | Berkas |
|---|---|
| Kontrak dokumen Firestore | `mobile/lib/core/data/sync/firestore_schema.dart` |
| Model outbox | `mobile/lib/core/data/sync/outbox.dart` |
| Antarmuka dan antrean memori | `mobile/lib/core/data/sync/sync_queue.dart` |
| Outbox permanen SQLite | `mobile/lib/core/data/sync/drift_sync_queue.dart` |
| Penguras antrean | `mobile/lib/core/data/sync/sync_engine.dart` |
| Penulis Firestore | `mobile/lib/core/data/sync/firestore_sync_target.dart` |
| Baca server dan impor cache | `mobile/lib/core/data/sync/cloud_read_through.dart` |
| Bootstrap Firebase native | `mobile/lib/core/config/firebase_bootstrap.dart` |
| Tabel outbox | `SyncOutboxEntries` di `mobile/lib/core/data/app_database.dart`, skema v6 |
| Pemicu startup/sesi/timer | `mobile/lib/app/app.dart` |
| Aturan dan indeks | `firebase/firestore.rules`, `firebase/firestore.indexes.json`, `firebase.json` |
| Referensi persiapan/skema | `docs/firebase-setup.md`, `docs/firestore-schema.md` |

Alur: simpan produk/bayar tunai mencatat data lokal dan entri outbox dalam
transaksi SQLite saat jalur outbox aktif. `SyncEngine.flush()` mengirim antrean
lewat `FirestoreSyncTarget` ke `stores/{storeId}/...`.

Pada jalur native, `FIREBASE_ENABLED` mengizinkan antrean; mesin penguras dibuat
ketika bootstrap Firebase siap. Tanpa flag aktif aplikasi berjalan lokal tanpa
membuat outbox baru. Penguras sudah dipanggil saat startup, perubahan sesi,
dan melalui `Timer.periodic` setiap 15 detik selama aplikasi berjalan. Tidak
perlu menambahkan scheduler baru untuk mengulang pekerjaan ini. Timer tersebut
bukan layanan background Android dan tidak menjamin pengiriman saat aplikasi
ditutup atau proses ditangguhkan.

**Produk yang sudah tersimpan sebelum outbox aktif tidak otomatis di-backfill.**
Antrean kosong atau satu proses `flush()` sukses bukan bukti seluruh katalog
lokal ada di cloud. Belum ada jaminan pemulihan dari cloud ke perangkat baru.

Read-through memakai `Source.server`, reuse sukses **15 detik**, backoff gagal
**30 detik**, timeout **8 detik** lalu cache. Fetch native tidak dapat dibatalkan;
request terlambat dilacak agar tidak overlap, hasil terlambat tidak diimpor.
Outbox pending/revisi tulis lokal melindungi perubahan, dan `dataRevision`
menyegarkan Beranda, Produk, Statistik, serta laporan. Impor nota tidak mengulang
checkout/pengurangan stok. Ack nota legacy atomik dengan antrean rekonsiliasi stok.

Full scan halaman 500 dibatasi **10.000 dokumen/koleksi**; snapshot melebihi
batas ditolak. Koleksi/halaman tidak atomik; stok multi-device masih
**last-write-wins**, tidak aman bersamaan. Read Firestore tetap berbiaya meski
hasil digunakan ulang 15 detik. Lihat `docs/firebase-setup.md` untuk batas lengkap.

## 2. Menjalankan build yang dikonfigurasi

Konfigurasi privat disediakan pengelola. Jangan membaca atau menyalin isi
`.env`, kredensial, atau konfigurasi privat untuk memperbarui dokumentasi.
Jangan membuat ulang proyek Firebase atau mengganti konfigurasi yang sudah ada
hanya karena panduan persiapan lama masih menyebut langkah tersebut.

Dari root proyek:

```bash
cd mobile
flutter run --dart-define-from-file=../.env
```

Riwayat build debug 15 November (sebelum cloud-first) memakai shell `sh`, dari
`mobile/`; perintah berikut referensi, bukan perintah yang dijalankan tugas ini:

```sh
JAVA_TOOL_OPTIONS=-Dorg.gradle.project.kotlin.incremental=false flutter build apk --debug --dart-define-from-file=../.env
```

PowerShell memakai assignment terpisah:

```powershell
$env:JAVA_TOOL_OPTIONS = '-Dorg.gradle.project.kotlin.incremental=false'
flutter build apk --debug --dart-define-from-file=../.env
```

`--dart-define` bukan penyimpanan rahasia yang aman dalam APK. Service account,
private key, dan secret pembayaran tidak boleh berada dalam aplikasi atau Git.
Akses cloud memerlukan jaringan, dapat menimbulkan biaya, dan mengirim data toko
ke penyedia. Pengujian produksi atau deploy aturan memerlukan persetujuan dan
pemeriksaan target proyek; jangan melonggarkan rules demi membuat upload lolos.

## 3. Verifikasi perangkat yang masih diperlukan

Langkah berikut untuk tugas perangkat terpisah, bukan izin build/install atau
operasi cloud pada tugas dokumentasi. Impor admin sudah selesai; jangan ulangi
seed atau meminta token melalui chat.

1. Bangun/pasang APK cloud-first pada tugas yang disetujui. Pastikan target toko
   benar; verifikasi baca server, cache offline, dan pembaruan UI. Catat status
   bootstrap tanpa menampilkan kredensial. APK lama bukan bukti kode ini berjalan.
2. Buat produk uji baru sebagai pemilik dan lakukan pembayaran tunai. Periksa
   nota/stok lokal terlebih dahulu; izin tulis aplikasi bukan bukti izin cloud.
3. Amati outbox SQLite serta hasil/error `SyncEngine.flush()`. Pemicu otomatis
   sudah ada; kegagalan jaringan/rules harus meninggalkan antrean untuk dicoba lagi.
4. Periksa dokumen produk dan transaksi pada cabang `stores/{storeId}` yang benar
   di Firestore Console. Cocokkan ID, isi, dan jumlah dengan SQLite, bukan hanya
   pesan SDK siap. Jangan menyalin data pribadi ke catatan pengujian.
5. Putuskan jaringan, simpan perubahan/transaksi lokal, kemudian sambungkan lagi
   dan biarkan aplikasi berjalan. Pastikan antrean terkuras tanpa nota ganda
   dan tanpa kehilangan data lokal.
6. Bandingkan produk lama dengan produk baru. Produk lama yang belum pernah
   diantrekan memerlukan strategi backfill tersendiri, persetujuan, dan uji
   idempotensi; jangan menjanjikan migrasi otomatis.
7. Catat bukti dokumen server, hasil/error sinkronisasi, serta kasus yang belum
   teruji dalam PR. Status `synced` hanya mewakili hasil antrean yang diproses,
   bukan audit semua data lokal, autentikasi, atau keamanan tenant.

## 4. Pekerjaan keamanan dan pemulihan berikutnya

- Identitas/keanggotaan toko tepercaya perlu keputusan keamanan terpisah.
  Jangan menambah login/PIN/Anonymous Auth tanpa permintaan pengguna. Pada
  rancangan produksi, `storeId` tidak boleh dipercaya hanya karena berasal
  dari konfigurasi, input LLM, atau pilihan peran lokal.
- Uji rules: pengguna tanpa izin, toko lain, serta penulisan bidang yang tidak
  sah harus ditolak. Keberadaan rules/index bukan bukti sudah dideploy atau lulus.
- Uji read-through produk/nota ke SQLite pada perangkat baru, termasuk snapshot
  item, idempotensi, dan state kosong/memuat/error/offline. Parser/impor sudah
  ada di kode; jangan menjanjikan restore produksi atau tombol pulihkan.
- Tentukan backfill dan konflik sebelum migrasi data nyata. Jangan menghapus
  produk permanen; ikuti soft delete `deletedAt` pada kontrak skema.
- Perubahan koleksi/bidang/`schemaVersion` memerlukan migrasi dan review skema.
  Dependensi baru serta perubahan `pubspec.yaml` tetap lewat PR.
- Storage/App Check, foto koreksi privat, dan retensi dataset memerlukan
  verifikasi tersendiri; konfigurasi Firestore tidak otomatis mengaktifkannya.

## 5. Bukti validasi dan batasnya

Hasil terakhir yang dilaporkan, bukan eksekusi ulang pada penyuntingan dokumen:

- 19 November 2026: analyzer bersih; **240 test Flutter + 12 test Node lulus**,
  termasuk guard pending dan rekonsiliasi stok outbox legacy. Tidak menjalankan
  ulang suite pada tugas dokumentasi ini.
- Pengujian sinkronisasi lokal mencakup kontrak dokumen, outbox memori/SQLite,
  serialisasi, urutan, kegagalan/offline, dan pembatalan checkout bila penulisan
  antrean gagal. Test lokal bukan uji jaringan Firebase nyata.
- Riwayat sebelum cloud-first, 15 November 2026: **212 test lulus**, APK debug
  dibangun sekitar **51 detik**, dipasang ulang
  memakai `adb install -r`, dan diluncurkan pada Samsung **SM_A366B**,
  `RRGYC07G09Z`, dengan data tetap dipertahankan.
- Belum terverifikasi: UI fisik menyeluruh, pemindaian penuh, cetak fisik
  label/struk, baca native dan unggah outbox perangkat, autentikasi/isolasi tenant,
  dan pemulihan. Impor admin/read-back terverifikasi tidak menggantikan uji ini.
- IyanBoT/Groq sudah memiliki tool baca dan draft berkonfirmasi untuk transaksi
  serta produk pemilik; pengujian API langsung belum terverifikasi dan dijeda
  atas permintaan pengguna. Jangan meneruskan pengujian live pada tugas dokumen.

Riwayat awal lapisan Firestore pernah mencatat 141 test, termasuk 15 test sync.
Angka itu bukti tahap awal, bukan jumlah test terkini. Lihat `PROGRESS.md` untuk
urutan pengerjaan. Riwayat APK lama bukan build/install cloud-first.

## 6. Monitor — fondasi lokal, integrasi cloud belum aktif

Rujukan kanonis: [Rencana Monitor](docs/monitor-plan.md), disusun terpisah.
Tombol Beranda pemilik membuka halaman baru isometrik 2.5D ringan; kandidat
`CustomPainter` + `InteractiveViewer`. Tiga template: Dinding, Dua baris,
Dinding + tengah. Penempatan produk massal perlu konfirmasi manual; boleh lewati.

Pantau tidak memindahkan fixture. Editor grid rak/kulkas/meja kasir: tambah,
pindah, nama, rotasi 90°, hapus, Simpan/Batal, penjaga keluar dengan perubahan.
Satu lokasi utama via `fixtureId`; stok/ambang memakai produk yang ada.
Hapus rak melepas penempatan, bukan produk; pindah lokasi tidak mengubah stok.
Peringatan menghitung jenis produk menipis/habis dengan ikon + teks, bukan
jumlah unit campuran. Detail bottom sheet ponsel/panel samping tablet, daftar
aksesibel, reset zoom, reduced motion; target 48 dp, lebar 360 dp/skala 1.3.

Audit reuse `floor_plan` arsip, bukan menghidupkan panorama/data palsu.
Persistensi layout/skema baru masih usulan, bukan koleksi deployed. Tidak
mengubah sumber, auth/rules, kredensial, melakukan deploy, atau menjalankan
build/install dalam tugas dokumentasi; referensi desain dan skills tetap.
