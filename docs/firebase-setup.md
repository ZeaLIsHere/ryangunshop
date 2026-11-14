# Firebase native: konfigurasi dan batas verifikasi

Status: **15 November 2026**. POS native sudah memakai SQLite/Drift offline-first.
Bootstrap Firebase, outbox SQLite, dan pemanggilan `SyncEngine` sudah terpasang;
bukan lagi rencana integrasi. Keberhasilan unggah cloud, autentikasi Firestore,
isolasi tenant, deployment aturan, dan pemulihan cloud **belum terverifikasi**.

## Konfigurasi build saat ini

Konfigurasi berasal dari `.env` privat melalui `--dart-define-from-file`.
Dokumentasi ini tidak membaca atau menyalin `.env`, konfigurasi Google, maupun
kredensial. Nama flag berasal dari `mobile/lib/core/config/firebase_bootstrap.dart`:

| Flag | Peran |
|---|---|
| `FIREBASE_ENABLED` | Sakelar integrasi; bawaan `false` |
| `FIREBASE_STORE_ID` | Segmen toko; bawaan kode `toko-utama` |
| `FIREBASE_API_KEY` | Konfigurasi SDK |
| `FIREBASE_PROJECT_ID` | ID proyek |
| `FIREBASE_APP_ID` | ID aplikasi |
| `FIREBASE_MESSAGING_SENDER_ID` | Konfigurasi pengirim |
| `FIREBASE_STORAGE_BUCKET` | Konfigurasi bucket; bukan bukti unggah foto |

Bootstrap juga menerima opsi platform lain yang tersedia di kode. Bila API key,
project ID, dan app ID lengkap, kode membentuk `FirebaseOptions`; bila tidak,
SDK mencoba konfigurasi native. Jangan menganggap isi konfigurasi privat sudah
valid hanya karena nama flag tersedia.

Dari `mobile/`, memakai konfigurasi privat yang telah disiapkan pemilik proyek:

```bash
flutter run --dart-define-from-file=../.env
flutter build apk --debug --dart-define-from-file=../.env
```

`--dart-define` bukan tempat menyimpan rahasia dengan aman. Nilai dapat ikut masuk
APK. Jangan memasukkan service account, private key, atau kunci server ke aplikasi
klien maupun Git. API key Firebase tidak menggantikan autentikasi dan aturan
keamanan. Kunci Groq di aplikasi klien juga tidak boleh dianggap rahasia aman;
penggunaan produksi memerlukan rancangan perlindungan tersendiri.

## Alur yang sudah terpasang

Acuan: `mobile/lib/app/app.dart`, `mobile/lib/core/config/firebase_bootstrap.dart`,
dan `mobile/lib/core/data/sync/`.

1. Pada native dengan database lokal dan `FIREBASE_ENABLED`, aplikasi membuat
   `DriftSyncQueue` dan memasukkannya ke `AppSession`.
2. Bila SDK siap, aplikasi membuat `SyncEngine` dengan `FirestoreSyncTarget`.
3. `flush()` dipanggil saat startup, notifikasi perubahan sesi, dan timer setiap
   **15 detik** selama aplikasi berjalan. Ini bukan Android background service,
   bukan jaminan sinkronisasi ketika aplikasi ditutup, dan bukan listener khusus
   koneksi kembali.
4. Target menulis ke `stores/{storeId}/products/{productId}` dan
   `stores/{storeId}/transactions/{transactionId}`. Produk memakai merge;
   nota ditulis utuh. Hapus produk mengirim tombstone `deletedAt`.
5. Entri berhasil dikeluarkan dari antrean. Kegagalan mencatat `attempts` dan
   `lastError`, lalu menghentikan putaran. Jadwal saat ini interval tetap,
   **bukan exponential backoff**.

Produk yang sudah ada sebelum antrean aktif **tidak otomatis di-backfill**.
Draft keranjang tetap lokal. Web tidak memakai SQLite, queue, atau sinkronisasi
native. POS lokal tidak memerlukan `backend-agent` untuk transaksi tunai.

`FirebaseBootstrap.isReady` hanya berarti SDK berhasil diinisialisasi. Itu tidak
membuktikan izin tulis, data sudah terkirim, atau data dapat dipulihkan. Bahkan
outbox kosong tidak membuktikan semua produk lama sudah berada di cloud.

## Peran lokal bukan autentikasi Firestore

Pengaturan mengganti mode pemilik/kasir tanpa login atau PIN. Guard pemilik
melindungi alur UI dan penyimpanan produk lokal, bukan identitas pengguna cloud.
Jangan menganggap `FIREBASE_STORE_ID` sebagai isolasi tenant atau bukti keanggotaan.

Skema dalam `firestore-schema.md` menjelaskan payload dan jalur target **kode**.
Dokumen anggota, custom claims, aturan berbasis pengguna, indeks, dan prosedur
pemulihan yang direncanakan tidak boleh dianggap sudah dideploy atau diuji.
Mengaktifkan Anonymous pada konsol saja tidak membuat aplikasi otomatis login.
Jangan membuka aturan publik untuk melewati kegagalan izin tulis.

## Pemeriksaan berikutnya sebelum menyebut cloud terverifikasi

1. Pilih dan uji autentikasi pengguna serta pemetaan anggota/peran toko.
2. Audit aturan dan indeks terhadap jalur target aktual; uji penolakan akses
   lintas toko serta penulisan tanpa izin sebelum deployment yang disetujui.
3. Buat perubahan produk/nota uji; cocokkan dokumen server, payload, dan
   penyelesaian outbox. Inisialisasi SDK saja tidak cukup.
4. Uji kegagalan izin/jaringan, antrean yang tertahan, retry, dan restart aplikasi.
5. Rancang backfill produk lama, konflik stok beberapa perangkat, dan pemulihan
   pada database/perangkat kosong. Helper baca produk bukan alur restore lengkap.
6. Pastikan biaya, kuota, dan data toko yang keluar ke Firebase disetujui.
   Perubahan paket berbayar, layanan, atau dependensi tetap perlu persetujuan.

Tidak ada deploy, akses konsol, pembacaan rahasia, atau uji jaringan dalam tugas
dokumentasi ini. Uji Groq langsung juga tetap dijeda atas permintaan pengguna.

## Menonaktifkan integrasi

Build ulang dengan `FIREBASE_ENABLED=false`, termasuk override bila konfigurasi
privat memuat nilai `true`:

```bash
flutter run --dart-define-from-file=../.env --dart-define=FIREBASE_ENABLED=false
```

Pada jalur kode saat ini, queue/engine tidak dibuat bila flag mati. SQLite lokal
tetap dipakai; entri outbox lama dan data server tidak otomatis dihapus. Penulisan
baru saat queue tidak tersedia tidak otomatis mendapat backfill setelah flag
kembali aktif. Menonaktifkan integrasi bukan prosedur pemulihan atau penghapusan
cadangan cloud.

## Bukti validasi terakhir

Pengguna melaporkan pada **15 November 2026**: analyzer bersih, **212 pengujian
lulus**, APK dibangun sekitar **51 detik**, dipasang ulang dengan
`adb install -r`, dan diluncurkan pada Samsung. Ini bukan bukti unggah Firestore,
audit keamanan tenant, pemulihan cloud, atau pemeriksaan visual/alur Android penuh.
Tidak menjalankan ulang validasi tersebut dalam pembaruan dokumentasi ini.
