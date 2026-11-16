# Skema Firestore RyanGunshop

Status: **15 November 2026**. Kontrak payload dan jalur target tulis yang sudah
ada di kode, bukan bukti skema/aturan sudah dideploy atau unggah cloud berhasil.
SQLite/Drift tetap sumber POS lokal. Bentuk dokumen didefinisikan di
`mobile/lib/core/data/sync/firestore_schema.dart` dan diuji di
`mobile/test/core/data/sync_test.dart`. Target aktual diperiksa pada
`mobile/lib/core/data/sync/firestore_sync_target.dart`.

Autentikasi Firestore, isolasi tenant, deployment aturan, dan pemulihan cloud
belum terverifikasi. Peran pemilik/kasir dari Pengaturan bukan login keamanan.

## Prinsip

1. **Lokal tetap sumber kebenaran saat kasir berjalan.** Nota ditulis ke SQLite
   lebih dahulu. Firestore menerima salinan, bukan sebaliknya.
2. **Jalur target per toko.** Target menulis di `stores/{storeId}`. Struktur
   jalur ini bukan jaminan isolasi tenant; autentikasi dan aturan akses masih
   perlu diuji. `storeId` berasal dari konfigurasi, bukan identitas terverifikasi.
3. **Nominal berupa bilangan bulat rupiah.** Tidak ada `double`, sehingga tidak
   ada pembulatan yang bergeser antarperangkat.
4. **ID ditentukan perangkat.** ID produk dan nomor nota (`TRX-...`) dibuat
   lokal, jadi pengiriman ulang bersifat idempoten.
5. **Versi skema.** Setiap dokumen menyimpan `schemaVersion`. Perubahan bentuk
   wajib menaikkan `FirestoreSchema.version` dan menambah catatan migrasi di
   bawah.

## Struktur koleksi

```text
stores/{storeId}
├── products/{productId}
├── transactions/{transactionId}
├── meta/sync                     # cadangan kontrak, belum dipakai
└── members/{uid}                 # usulan akses anggota, bukan bukti deployment
```

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
| `fixtureId` | string | ya | ID rak pada denah, boleh kosong |
| `locationLabel` | string | ya | Nama lokasi yang dibaca kasir |
| `lowStockThreshold` | int | ya | Ambang stok menipis |
| `updatedAt` | timestamp | ya | Waktu perubahan terakhir |
| `deletedAt` | timestamp \| null | ya | *Soft delete*; `null` berarti aktif |

Target mengirim penghapusan sebagai `deletedAt` dengan merge, bukan menghapus
dokumen. Helper `fetchProductsFromFirestore()` menyaring `deletedAt == null`.
Belum ada sinkronisasi dua arah yang terbukti menerapkan penghapusan ke perangkat
lain; tombstone hanya menyediakan kontrak untuk alur tersebut.

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
- Produk lama tidak otomatis di-backfill. Web tanpa SQLite, queue, atau sync native.

## Pemulihan cloud: usulan, belum terverifikasi

Helper `fetchProductsFromFirestore()` tersedia untuk membaca produk aktif.
Keberadaan helper bukan alur restore produk dan nota yang sudah terintegrasi.
Belum ada jaminan pemulihan otomatis atau tombol pemulihan siap pakai.

Rancangan berikut masih memerlukan implementasi dan pengujian: autentikasi
anggota toko, unduh produk/nota yang berhak diakses, validasi payload, tulis ke
SQLite, serta penanganan konflik dan retry tanpa menggandakan outbox. Jangan
menjalankannya sebagai prosedur pemulihan produksi berdasarkan dokumen ini.

## Rencana migrasi bertahap

| Tahap | Isi | Status |
|---|---|---|
| 1 | Skema dokumen, outbox, mesin sinkronisasi, konfigurasi Firebase | selesai (lapisan) |
| 2 | Layanan autentikasi + layar masuk, aturan keamanan diuji | belum |
| 3 | `flush()` startup, perubahan sesi, timer 15 detik selama aplikasi berjalan | terpasang; unggah nyata belum terverifikasi |
| 4 | Pemulihan produk dan nota di perangkat baru | belum |
| 5 | Sinkronisasi dua arah untuk produk (konflik stok) | belum |
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
