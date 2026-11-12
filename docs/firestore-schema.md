# Skema Firestore RyanGunshop

Kontrak data cloud untuk migrasi dari SQLite lokal ke Firestore. Bentuk dokumen
didefinisikan di `mobile/lib/core/data/sync/firestore_schema.dart` dan diuji di
`mobile/test/core/data/sync_test.dart`.

## Prinsip

1. **Lokal tetap sumber kebenaran saat kasir berjalan.** Nota ditulis ke SQLite
   lebih dahulu. Firestore menerima salinan, bukan sebaliknya.
2. **Satu cabang per toko.** Semua data berada di `stores/{storeId}` agar aturan
   keamanan cukup memeriksa satu lokasi dan beberapa warung dapat berbagi satu
   proyek Firebase.
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
├── meta/sync
└── members/{uid}                 # hanya bila memakai aturan berbasis dokumen
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

Produk dihapus dengan mengisi `deletedAt`, bukan menghapus dokumen, agar
perangkat lain ikut membuang salinannya dan data lama tidak muncul kembali.
Semua pembacaan menyaring `deletedAt == null`.

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

Harga dan nama dibekukan saat transaksi. Perubahan harga produk tidak boleh
mengubah nota lama.

### `meta/sync`

Penanda sinkronisasi perangkat, misalnya versi data terakhir yang sudah diunggah
dan waktu pemeriksaan terakhir. Belum dipakai pada tahap ini.

## Indeks

| Kueri | Indeks |
|---|---|
| Produk aktif, urut nama | Komposit `deletedAt` ASC, `name` ASC |
| Cari barcode | Komposit `deletedAt` ASC, `barcode` ASC |
| Nota terbaru per toko | Otomatis pada `createdAt` DESC |

Definisi lengkap ada di `firebase/firestore.indexes.json`.

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
[SyncEngine.flush()]  ← dipanggil saat online / setelah checkout
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
  Pemanggil yang mengatur jeda percobaan berikutnya (*exponential backoff*).
- Status yang boleh ditampilkan: `offline`, `pending`, `synced`. Jangan
  menampilkan `synced` sebelum `flush()` mengembalikan `SyncStatus.synced`.

## Memulihkan data di perangkat baru

1. Masuk dengan akun yang terdaftar sebagai anggota toko.
2. Unduh produk:
   `fetchProductsFromFirestore()` di
   `mobile/lib/core/data/sync/firestore_sync_target.dart`.
3. Tulis ke SQLite melalui `DriftProductRepository.save()`.
4. Unduh nota terbaru untuk laporan, lalu simpan ke tabel `transactions` dan
   `transaction_items`.

Pemulihan belum dijalankan otomatis; tombol "Pulihkan dari cloud" di layar
Pengaturan adalah langkah berikutnya.

## Rencana migrasi bertahap

| Tahap | Isi | Status |
|---|---|---|
| 1 | Skema dokumen, outbox, mesin sinkronisasi, konfigurasi Firebase | selesai (lapisan) |
| 2 | Layanan autentikasi + layar masuk, aturan keamanan diuji | belum |
| 3 | Penjadwalan `flush()` saat aplikasi dibuka dan koneksi kembali | belum |
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
- **Hapus produk** memakai *soft delete*; jangan menambah kueri yang
  mengabaikan `deletedAt`.
- **Kuota Spark** (20.000 tulis/hari) cukup untuk satu warung, tetapi retry
  tanpa batas dapat menghabiskan kuota. Batasi percobaan dan tampilkan status
  kepada kasir.

## Rollback

Matikan integrasi tanpa menyentuh data:

```bash
flutter run                      # tanpa FIREBASE_ENABLED
```

Aplikasi kembali 100% lokal. Data yang sudah terkirim tetap ada di Firestore
sebagai cadangan, dan outbox berhenti bertambah karena antrean hanya diisi saat
`AppSession` menerima `SyncQueue`.
