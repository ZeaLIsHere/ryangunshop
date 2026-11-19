# Skema Firestore RyanGunshop

Status: **19 November 2026**, acuan kode `a85a159`. Kontrak baca/tulis sudah
ada di kode: baca native cloud-first, SQLite/Drift cache/fallback, penulisan POS
lokal lalu outbox. APK cloud-first belum dibangun/dipasang dan baca native
langsung belum diverifikasi. Impor server berizin sudah terbukti, berbeda dari
verifikasi integrasi perangkat. Bentuk dokumen didefinisikan di
`mobile/lib/core/data/sync/firestore_schema.dart` dan diuji di
`mobile/test/core/data/sync_test.dart`. Target aktual diperiksa pada
`mobile/lib/core/data/sync/firestore_sync_target.dart`.

GET tanpa autentikasi masih HTTP 200: risiko baca publik belum ditutup.
Autentikasi aplikasi, isolasi tenant, dan pemulihan perangkat baru belum
terverifikasi. Peran Pengaturan bukan login keamanan. Tidak ada perubahan
rules/auth atau permintaan login/PIN/Anonymous Auth.

## Prinsip

1. **Cloud-first untuk baca native, lokal untuk commit POS.** Server mengisi
   cache SQLite lewat read-through; offline/gagal memakai cache. Checkout
   mencatat nota/stok/outbox lokal terlebih dahulu. Guard pending melindungi
   perubahan lokal yang belum terkirim dari snapshot cloud.
2. **Jalur target per toko.** Target menulis di `stores/{storeId}`. Struktur
   jalur ini bukan jaminan isolasi tenant; autentikasi dan aturan akses masih
   perlu diuji. `storeId` berasal dari konfigurasi, bukan identitas terverifikasi.
3. **Nominal berupa bilangan bulat rupiah.** Tidak ada `double`, sehingga tidak
   ada pembulatan yang bergeser antarperangkat.
4. **ID stabil.** Produk/nota POS (`TRX-...`) dibuat lokal; tool impor memakai
   ID stabil sendiri dan create-only. Pengiriman/impor ulang tidak menggandakan
   nota atau menjalankan pengurangan stok checkout lagi.
5. **Versi skema.** Setiap dokumen menyimpan `schemaVersion`. Perubahan bentuk
   wajib menaikkan `FirestoreSchema.version` dan menambah catatan migrasi di
   bawah.

## Struktur koleksi

```text
stores/{storeId}
├── products/{productId}
└── transactions/{transactionId}
```

Ini dua koleksi data aktif pada kontrak dan impor terverifikasi. `meta/sync`
(cadangan kontrak), `members/{uid}` (usulan akses), serta persistensi layout
Monitor **bukan koleksi aktif yang terverifikasi**.

`cartDrafts` **tidak** disinkronkan. Draft keranjang hanya berarti pada perangkat
yang sedang dipakai dan sudah tersimpan di SQLite.

### `products/{productId}`

| Bidang | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `schemaVersion` | int | ya | Versi skema dokumen |
| `name` | string | ya | Nama barang |
| `barcode` | string \| null | tidak | `null` bila barang tanpa barcode |
| `salePrice` | int | ya | Harga jual, rupiah |
| `costPrice` | int | ya | Harga modal, rupiah |
| `stock` | int | ya | Stok tersedia |
| `category` | string | ya | Kategori tampilan katalog |
| `unit` | string | ya | Satuan, mis. `pcs`, `botol` |
| `fixtureId` | string | ya | ID lokasi utama produk, boleh kosong; bidang tersedia, bukan bukti persistensi layout Monitor |
| `locationLabel` | string | ya | Nama lokasi yang dibaca kasir |
| `lowStockThreshold` | int | ya | Ambang stok menipis |
| `updatedAt` | timestamp | ya | Waktu perubahan terakhir |
| `deletedAt` | timestamp \| null | ya | *Soft delete*; `null` berarti aktif |

Target mengirim penghapusan sebagai `deletedAt` dengan merge, bukan menghapus
dokumen. Read-through memvalidasi dan menerapkan tombstone ke SQLite bila produk
tidak dilindungi outbox pending. Tidak menghapus produk hanya karena ID absen
dari snapshot. Perilaku kode ini belum diverifikasi langsung lintas perangkat;
helper `fetchProductsFromFirestore()` bukan jalur read-through utama.

### `transactions/{transactionId}`

Nomor nota berformat `TRX-<microsecondsSinceEpoch>` dan dibuat di perangkat.

| Bidang | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `schemaVersion` | int | ya | Versi skema dokumen |
| `createdAt` | timestamp | ya | Waktu nota dibuat |
| `totalAmount` | int | ya | Total setelah diskon |
| `discountAmount` | int | ya | Diskon nota |
| `paymentMethod` | string | ya | `cash` (QRIS belum dicatat) |
| `cashReceived` | int \| null | tidak | Uang diterima |
| `changeAmount` | int \| null | tidak | Kembalian |
| `itemCount` | int | ya | Jumlah kuantitas seluruh baris |
| `summaryTitle` | string | ya | Ringkasan singkat untuk daftar nota |
| `items` | array<map> | ya | Baris barang, lihat di bawah |

Baris barang disimpan di dalam dokumen karena satu nota warung jarang melebihi
puluhan baris, sehingga nota dapat dibaca dengan satu permintaan:

```json
{
  "productId": "p-1",
  "productName": "Air Mineral",
  "quantity": 2,
  "unitPrice": 4000,
  "subtotal": 8000
}
```

Harga jual dan nama dibekukan saat transaksi. Perubahan harga produk tidak boleh
mengubah nota lama. Baris nota tidak menyimpan snapshot harga modal; laba
historis belum dihitung. `costPrice` produk saat ini bukan modal historis nota.

### `meta/sync`

Penanda sinkronisasi perangkat, misalnya versi data terakhir yang sudah diunggah
dan waktu pemeriksaan terakhir. Belum dipakai pada tahap ini.

## Indeks

| Kueri | Indeks |
|---|---|
| Produk aktif, urut nama | Komposit `deletedAt` ASC, `name` ASC |
| Cari barcode | Komposit `deletedAt` ASC, `barcode` ASC |
| Nota terbaru per toko | Otomatis pada `createdAt` DESC |

Indeks di atas adalah kebutuhan/usulan kueri, bukan bukti indeks aktif pada
server. Rujukan konfigurasi repositori: `firebase/firestore.indexes.json`;
deployment dan kesesuaiannya dengan aturan akses perlu diverifikasi terpisah.

## Alur sinkronisasi

```text
[Kasir] isi keranjang → bayar tunai
        │
        ▼
[SQLite, satu transaksi ACID]
   ├─ simpan nota + baris barang
   ├─ kurangi stok
   └─ tulis entri sync_outbox_entries (payload JSON dokumen)
        │
        ▼
[SyncEngine.flush()]  ← startup / perubahan sesi / timer 15 detik
   ├─ ambil entri terlama (batch 20)
   ├─ FirestoreSyncTarget.apply()
   │     ├─ products/{id}     set(merge: true)
   │     ├─ transactions/{id} set() utuh
   │     └─ delete produk     set({deletedAt}, merge: true)
   └─ berhasil → hapus entri; gagal → attempts++ dan berhenti
        │
        ▼
[Firestore] stores/{storeId}/...
```

Aturan antrean:

- Entri diproses berurutan. Bila satu entri gagal, putaran berhenti agar
  perubahan berikutnya tidak mendahului perubahan yang gagal.
- Entri gagal **tidak dibuang**, hanya menambah `attempts` dan `lastError`.
  Pemanggil saat ini memakai timer tetap 15 detik; belum exponential backoff.
- Status mesin: `offline`, `pending`, `synced`. Hasil `synced` berarti antrean
  saat itu kosong; bukan bukti produk lama sudah diunggah. SDK siap bukan bukti
  tulis berhasil. Jangan mengubah status UI menjadi klaim cloud tanpa bukti.
- Queue dibuat pada native bila database tersedia dan Firebase diaktifkan;
  engine hanya dibuat bila SDK siap. Pemicu berada di `mobile/lib/app/app.dart`.
  Tidak ada jaminan Android background service atau pengiriman saat aplikasi tutup.
- Produk lama tidak otomatis di-backfill. Web hanya preview lokal tanpa SQLite,
  queue, atau cloud-first native.
- Ack nota outbox legacy tanpa `stockQueued` mengantrekan rekonsiliasi stok lokal
  terkait dalam transaksi yang sama dengan penghapusan entri nota. Produk dengan
  perubahan/hapus tertunda tetap dilindungi; regresi rekonsiliasi sudah diuji.

## Read-through native dan batas pemulihan

`cloud_read_through.dart` membaca produk/nota dengan `Source.server`, memvalidasi
payload, lalu mengimpor dalam transaksi SQLite. Hasil sukses dipakai ulang
15 detik, kegagalan backoff 30 detik, timeout 8 detik memakai cache. Fetch native
tidak dapat dibatalkan; request yang terlambat tetap dilacak agar tidak overlap,
dan hasil terlambat tidak diimpor. Ini berbeda dari timer outbox 15 detik.

Guard pending dan revisi tulis lokal mencegah snapshot menimpa perubahan lokal
yang sedang/masih diantrekan. Impor nota tidak menjalankan checkout ulang atau
membuat outbox baru. `dataRevision` menyegarkan UI lintas fitur setelah perubahan.

Full scan memakai halaman 500 dokumen, maksimal **10.000 dokumen per koleksi**.
Snapshot melebihi batas ditolak, bukan diimpor sebagian. Snapshot antar koleksi/
halaman tidak atomik meski impor lokal atomik. Pembacaan tetap menimbulkan read
Firestore. Stok lintas perangkat masih **last-write-wins**, tidak aman serentak.
Baca native langsung, pemulihan perangkat kosong, dan keamanan tenant belum
terverifikasi; jangan menjanjikan restore produksi atau tombol pulihkan.

## Bukti impor dan validasi — 19 November 2026

Google Cloud CLI sudah dipasang dan diotorisasi pengguna. Impor OAuth berizin
pada `iyangunshop`, `stores/toko-utama` menghasilkan **90 dokumen dibuat,
0 dilewati, 90 read-back sesuai rencana**: 24 produk, 66 nota tunai, 394 unit,
Rp3.035.800, tanggal 10–24 November 2026 inklusif (15 hari). Create-only,
tidak menimpa dokumen lama. Asal dicatat internal; tanpa label visual data demo.
Tidak mencetak/menyalin kredensial; rules/auth tidak diubah.

Validasi terakhir yang dilaporkan: analyzer bersih, **240 test Flutter + 12 test
Node lulus**, termasuk guard outbox dan rekonsiliasi legacy. Bukan eksekusi ulang
pada tugas dokumen. Impor admin/read-back bukan bukti baca native, unggah outbox
APK, atau stok multi-device aman. APK cloud-first belum dibangun/dipasang.

## Monitor — kontrak di kode, belum diverifikasi live

Acuan kanonis: [Rencana Monitor](monitor-plan.md). Pembangunan fondasi lokal
sudah disetujui: model/template, layout SQLite skema 7 dan UI lokal tersedia.
Kontrak cloud baru ditulis ke `stores/{storeId}/layouts/main` sebagai
`{layout, token}`. Layout menyimpan assignments produk→fixture, bukan stok.
Transaksi Firestore memeriksa baseToken atau token retry, membaca seluruh produk
terkait lalu memperbarui lokasi dan layout secara atomik. `monitorLocationToken`
produk mencegah snapshot outbox stok lama mengembalikan lokasi sebelumnya.
Maksimal 400 penempatan, 450 perubahan lokasi/operasi. Perubahan lokasi tidak
menulis harga, stok atau nota. Jalur ini belum diuji pada server; rules tidak diubah.

- Satu lokasi utama per produk via `fixtureId`; tanpa salinan stok pada fixture.
  Produk boleh belum ditempatkan. Penempatan massal memerlukan konfirmasi manual.
- Layout memuat identitas fixture, jenis rak/kulkas/meja kasir, nama,
  posisi grid dan rotasi 90°. Outbox layout memakai token/baseToken; konflik
  tetap pending dan tidak menghambat antrean nota/produk. Rules perlu uji terpisah.
- Pindah lokasi tidak mengubah stok; hapus rak melepas penempatan, bukan
  menghapus produk. Simpan/Batal bekerja pada draft; konsistensi perubahan
  layout dan penempatan harus diuji, bukan diasumsikan atomik di cloud.
- Jumlah peringatan adalah jenis produk menipis/habis dari stok/ambang yang
  sudah ada. Tidak menjumlah unit berbeda dan tidak membuat koleksi stok baru.

Tidak deploy rules atau seed layout Monitor. Koleksi layout baru hanya target
kode, belum bukti dokumen tersimpan server. Migrasi lokal SQLite 6→7 menambah
`monitor_layouts`; payload lokasi produk menambah token internal opsional.

## Peta lapisan dan pekerjaan berikutnya

Nomor berikut menjaga urutan rencana lama; bukan persetujuan implementasi
keamanan atau layanan tambahan.

| Tahap | Isi | Status |
|---|---|---|
| 1 | Skema dokumen, outbox, mesin sinkronisasi, konfigurasi Firebase | selesai (lapisan) |
| 2 | Identitas/keanggotaan toko dan aturan keamanan | belum disetujui; tidak menambah login/PIN/Anonymous Auth |
| 3 | `flush()` startup, perubahan sesi, timer 15 detik selama aplikasi berjalan | terpasang; unggah nyata belum terverifikasi |
| 4 | Read-through produk/nota ke SQLite | kode dan test ada; baca native/perangkat baru belum live terverifikasi |
| 5 | Penyelesaian konflik stok beberapa perangkat | belum; last-write-wins tidak aman serentak |
| 6 | QRIS, foto produk, dan laporan berbasis cloud | belum |

### Batasan yang harus disepakati sebelum tahap 2

- **Konflik stok:** dua perangkat yang menjual barang sama dapat saling
  menimpa. Solusi yang disarankan: transaksi stok memakai
  `FieldValue.increment(-qty)` dan server menolak stok negatif lewat aturan atau
  Cloud Function.
- **Draft keranjang tidak disinkronkan** agar kasir tidak melihat keranjang
  perangkat lain.
- **QRIS belum tercatat** karena pembayaran QRIS masih simulasi.
- **Peran pengguna** masih lokal (`AppSession`), belum menjadi klaim Firebase.
- **Hapus produk** mengirim tombstone; penerapan lintas perangkat belum teruji.
- **Kuota dan biaya:** periksa paket/kuota aktual sebelum operasi cloud. Retry
  dapat menambah pemakaian; kapasitas aman satu warung belum dibuktikan.

## Riwayat kontrak awal

Dokumentasi 15 November 2026 menggambarkan upload-only dan helper baca produk,
belum read-through terintegrasi. Itu riwayat sebelum `a85a159`, bukan batas kode
terkini. Usulan `meta/sync`, anggota toko, dan autentikasi tidak menjadi deployed
hanya karena tercatat dalam rencana lama.

## Rollback

Matikan integrasi tanpa menyentuh data:

```bash
flutter run --dart-define-from-file=../.env --dart-define=FIREBASE_ENABLED=false
```

Override diperlukan bila konfigurasi privat mengaktifkan Firebase. Queue/engine
tidak dibuat saat flag mati; SQLite tetap berjalan. Outbox lama dan data server
tidak dihapus. Penulisan baru tanpa queue tidak otomatis di-backfill saat flag
kembali aktif. Data server tidak boleh disebut cadangan yang dapat dipulihkan
sebelum uji restore lulus. Konfigurasi privat tidak dibaca dalam pembaruan ini.
