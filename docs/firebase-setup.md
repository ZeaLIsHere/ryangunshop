# Firebase native: konfigurasi dan batas verifikasi

Status: **19 November 2026**, acuan kode `a85a159`. Baca POS native sudah
cloud-first saat Firebase siap, dengan SQLite/Drift sebagai cache/fallback.
Penulisan POS tetap lokal lalu outbox. Bootstrap, `SyncEngine`, dan read-through
sudah di kode; APK cloud-first **belum dibangun/dipasang**, baca native langsung
serta unggah outbox perangkat belum terverifikasi.

Impor berizin melalui Google Cloud CLI sudah create-only dan read-back
terverifikasi: **90 dokumen, 24 produk, 66 nota tunai, 394 unit, Rp3.035.800**,
10–24 November 2026 inklusif (15 hari, termasuk tanggal mendatang), pada
`iyangunshop`, `stores/toko-utama`. Tidak menimpa dokumen lama. Data tampil
normal tanpa label contoh/sintetis/demo; asal dicatat lewat metadata internal.
CLI sudah dipasang dan diotorisasi pengguna; tidak perlu mencetak kredensial.

**Risiko tetap:** GET tanpa autentikasi masih HTTP 200. Impor admin bukan bukti
rules aman, autentikasi aplikasi, isolasi tenant, atau pemulihan perangkat baru.
Tidak ada perubahan rules/auth; login/PIN/Anonymous Auth tidak diminta.

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

## Alur yang sudah ada di kode, bukan bukti APK terpasang

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
   **bukan exponential backoff** untuk penguras outbox. Backoff baca cloud
   30 detik adalah mekanisme terpisah.
6. Read-through native meminta `Source.server` untuk produk dan nota, memakai
   ulang hasil sukses **15 detik**, backoff gagal **30 detik**, timeout **8 detik**.
   Kegagalan memakai SQLite tanpa mengklaim cache sebagai data cloud terbaru.
   Fetch native tidak dapat dibatalkan; request masih dilacak sampai selesai
   agar tidak overlap, dan hasil yang terlambat tidak diimpor.
7. Snapshot divalidasi sebelum impor SQLite. Guard outbox pending/revisi tulis
   lokal melindungi perubahan produk, penghapusan, dan nota lokal. Impor nota
   tidak mengurangi stok lagi atau membuat checkout/outbox baru. Ack nota
   outbox lama dan antrean rekonsiliasi stok dilakukan atomik; regresinya diuji.
8. `dataRevision` menyegarkan Beranda, Produk, Statistik, dan laporan ketika data
   berubah, tidak hanya saat jumlah nota hari ini berubah.

Pembacaan melakukan **full scan**, halaman 500 dokumen dengan batas **10.000
per koleksi**; snapshot yang melewati batas ditolak, bukan diimpor sebagian.
Koleksi/halaman bukan snapshot server atomik. Stok lintas perangkat masih
**last-write-wins**, tidak aman untuk penjualan bersamaan. Reuse 15 detik
mengurangi frekuensi, bukan menghapus biaya read Firestore.

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

Skema dalam `firestore-schema.md` memisahkan payload aktif, bukti impor, dan
usulan masa depan.
Dokumen anggota, custom claims, aturan berbasis pengguna, indeks, dan prosedur
pemulihan yang direncanakan tidak boleh dianggap sudah dideploy atau diuji.
Mengaktifkan Anonymous pada konsol saja tidak membuat aplikasi otomatis login.
Jangan membuka aturan publik untuk melewati kegagalan izin tulis.

## Pemeriksaan native/keamanan berikutnya — bukan tugas dokumentasi

1. Bangun/pasang APK cloud-first pada tugas terpisah yang disetujui, lalu
   verifikasi baca server, cache, dan pembaruan UI pada perangkat. Jangan
   menambahkan login/PIN/Anonymous Auth; perubahan keamanan perlu persetujuan
   tersendiri, bukan prasyarat yang diam-diam mengubah cakupan.
2. Audit aturan dan indeks terhadap jalur target aktual; uji penolakan akses
   lintas toko serta penulisan tanpa izin sebelum deployment yang disetujui.
3. Buat perubahan produk/nota uji; cocokkan dokumen server, payload, dan
   penyelesaian outbox. Inisialisasi SDK saja tidak cukup.
4. Uji kegagalan izin/jaringan, antrean yang tertahan, retry, dan restart aplikasi.
5. Uji read-through pada database/perangkat kosong. Parser/impor produk dan
   nota sudah ada; pemulihan produksi belum terverifikasi. Backfill produk lama
   dan penyelesaian konflik stok lintas perangkat masih pekerjaan terpisah.
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

## Monitor — tidak menambah koleksi pada tugas ini

[Monitor](monitor-plan.md) mulai dibangun pada fondasi layout lokal. Kandidat halaman
native 2.5D membaca `product.stock`, ambang, dan satu `fixtureId` per produk.
Persistensi lokal layout/fixture memakai SQLite skema 7. Aturan akses cloud dan
sinkronisasi layout masih usulan; tidak ada koleksi layout aktif yang dibuktikan
oleh impor 90 dokumen.
Tidak deploy, seed layout, mengubah rules, atau menambah dependensi pada tugas ini.

## Bukti validasi terakhir dan riwayat

**19 November 2026:** analyzer bersih, **240 test Flutter + 12 test Node lulus**,
termasuk guard pending, impor idempoten, dan rekonsiliasi stok legacy. Impor
server berizin/read-back sudah terverifikasi sebagaimana rincian di atas.
APK cloud-first belum dibangun/dipasang; baca native langsung belum diverifikasi.
Tidak menjalankan ulang test atau operasi jaringan pada pembaruan dokumentasi ini.

**Riwayat sebelum cloud-first, 15 November 2026:** analyzer bersih, **212 test
lulus**, APK dibangun sekitar **51 detik**, dipasang dengan `adb install -r`,
dan diluncurkan pada Samsung. Bukti ini tidak berlaku sebagai build/install
cloud-first, audit tenant, pemulihan, atau pemeriksaan visual/alur Android penuh.
