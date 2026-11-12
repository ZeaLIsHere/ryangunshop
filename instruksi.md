# Instruksi — Persiapan Migrasi Database ke Firebase Firestore

Dokumen kerja untuk melanjutkan bagian **persiapan Firestore** yang sudah
dikerjakan. Panduan akun dan API key yang rinci ada di
`docs/firebase-setup.md`; bentuk data dan rencana bertahap ada di
`docs/firestore-schema.md`.

Status: **lapisan selesai, integrasi belum dinyalakan.** Aplikasi tetap
offline-first dengan SQLite. Jangan menganggap data sudah tersinkron sebelum
`SyncEngine.flush()` mengembalikan `SyncStatus.synced`.

---

## 1. Yang sudah ada

| Bagian | Berkas |
|---|---|
| Kontrak dokumen Firestore | `mobile/lib/core/data/sync/firestore_schema.dart` |
| Model antrean tulis | `mobile/lib/core/data/sync/outbox.dart` |
| Antrean memori + antarmuka | `mobile/lib/core/data/sync/sync_queue.dart` |
| Antrean permanen SQLite | `mobile/lib/core/data/sync/drift_sync_queue.dart` |
| Mesin penguras antrean | `mobile/lib/core/data/sync/sync_engine.dart` |
| Penulis ke Firestore | `mobile/lib/core/data/sync/firestore_sync_target.dart` |
| Penyalaan Firebase | `mobile/lib/core/config/firebase_bootstrap.dart` |
| Tabel outbox | `SyncOutboxEntries` di `mobile/lib/core/data/app_database.dart` (skema v6) |
| Aturan & indeks | `firebase/firestore.rules`, `firebase/firestore.indexes.json`, `firebase.json` |
| Panduan | `docs/firebase-setup.md`, `docs/firestore-schema.md` |

Alur yang sudah tersambung:

```text
simpan produk / bayar tunai
  → SQLite (produk/nota + entri sync_outbox_entries dalam satu transaksi)
  → SyncEngine.flush()  (belum dijadwalkan otomatis)
  → FirestoreSyncTarget → stores/{storeId}/...
```

Sakelar: `--dart-define=FIREBASE_ENABLED=true`. Tanpa sakelar itu tidak ada
antrean yang dibuat dan aplikasi berjalan 100% lokal.

---

## 2. Yang harus dikerjakan berikutnya

### Langkah 1 — Buat proyek Firebase

Ikuti `docs/firebase-setup.md` bagian 2–5:

1. Proyek baru di <https://console.firebase.google.com>.
2. Daftarkan aplikasi Android dengan paket `com.ryangunshop.ryangunshop`.
3. Unduh `google-services.json` ke `mobile/android/app/` **atau** isi
   variabel `FIREBASE_*` di `.env`.
4. Buat Firestore mode produksi di `asia-southeast2`.
5. Deploy aturan dan indeks:

   ```bash
   firebase login
   firebase use --add
   firebase deploy --only firestore:rules,firestore:indexes
   ```

### Langkah 2 — Nyalakan dan uji tulisan

1. Isi `.env` (sudah di-.gitignore) sesuai `docs/firebase-setup.md` bagian 4.
2. Jalankan:

   ```bash
   cd mobile
   flutter run --dart-define-from-file=../.env
   ```

3. Tambah produk, lakukan pembayaran tunai.
4. Pastikan dokumen muncul di Firestore Console:
   `stores/toko-utama/products/{id}` dan
   `stores/toko-utama/transactions/TRX-...`.
5. Uji putus jaringan: transaksi tetap tersimpan lokal, outbox bertambah, dan
   setelah `flush()` tidak ada nota ganda.

### Langkah 3 — Autentikasi dan hak akses

1. Aktifkan **Authentication → Anonymous** untuk uji awal.
2. Daftarkan perangkat ke toko:
   - dokumen `stores/toko-utama/members/{uid}` berisi `{ "role": "owner" }`,
     atau
   - custom claim `storeId = "toko-utama"` lewat Admin SDK/Cloud Function.
3. Buat layar masuk (Email/Password atau Google Sign-In). `firebase_auth` sudah
   ada di `pubspec.yaml`, tetapi belum dipakai di kode.
4. Uji aturan dengan Rules Playground: pengguna tanpa keanggotaan harus ditolak.

### Langkah 4 — Jadwalkan sinkronisasi

Tambahkan pemanggil `SyncEngine.flush()` pada:

- aplikasi dibuka setelah `FirebaseBootstrap.isReady == true`;
- setelah checkout berhasil;
- saat koneksi kembali (`connectivity_plus` — tambahkan lewat PR karena
  menambah dependensi);
- pengingat berkala, misalnya tiap 5 menit saat aplikasi di depan.

Contoh:

```dart
final engine = SyncEngine(
  queue: DriftSyncQueue(database),
  target: FirestoreSyncTarget(
    firestore: FirebaseFirestore.instance,
    storeId: FirebaseBootstrap.storeId,
  ),
);

final result = await engine.flush();
// result.status: offline | pending | synced
```

Tampilkan `result.status` pada `SyncPill`. Jangan pernah menampilkan
"Tersinkron" sebelum status benar-benar `synced`.

### Langkah 5 — Pemulihan di perangkat baru

1. Unduh produk memakai `fetchProductsFromFirestore()`.
2. Simpan ke SQLite lewat `DriftProductRepository.save()`.
3. Unduh nota terbaru dan isi tabel `transactions` + `transaction_items`.
4. Sediakan tombol "Pulihkan dari cloud" di layar Pengaturan, lengkap dengan
   state memuat, kosong, gagal, dan offline.

### Langkah 6 — Sebelum rilis

- [ ] `google-services.json` dan `firebase_options.dart` tidak ter-commit.
- [ ] API key dibatasi ke paket Android + Cloud Firestore API.
- [ ] Firestore mode produksi, aturan diuji.
- [ ] Budget alert aktif.
- [ ] `flutter analyze` bersih dan `flutter test` lulus.
- [ ] Persetujuan tim dicatat di `PROGRESS.md`.

---

## 3. Hal yang tidak boleh dilakukan

- Jangan menaruh service account JSON, private key, atau kata sandi di
  repositori, `.env` yang ter-commit, atau APK.
- Jangan menghapus dokumen produk secara permanen; pakai *soft delete*
  (`deletedAt`) seperti pada `FirestoreSchema.productDeletionDocument`.
- Jangan mengubah nama koleksi, nama bidang, atau `schemaVersion` tanpa
  menambah catatan migrasi di `docs/firestore-schema.md`.
- Jangan menampilkan status "Tersinkron", "Tersimpan di cloud", atau "Stok
  tersedia" tanpa data yang sudah dikonfirmasi.
- Jangan mengubah `pubspec.yaml` di luar pull request.
- Jangan mengaktifkan Firestore produksi tanpa persetujuan tim; `AGENTS.md`
  masih menetapkan cloud di luar cakupan tahap ini.

---

## 4. Verifikasi yang sudah dijalankan

- `flutter analyze`: tidak ada issue.
- `flutter test`: 141/141 lulus, termasuk 15 pengujian baru pada
  `mobile/test/core/data/sync_test.dart`.
- Cakupan uji baru: jalur dokumen, validasi cabang toko, pemetaan produk dan
  nota, *soft delete*, serialisasi outbox, antrean memori dan SQLite, urutan
  sinkronisasi, berhenti pada kegagalan, status offline, serta pembatalan
  checkout bila penulisan antrean gagal.

Belum diuji: koneksi ke proyek Firebase nyata dan perangkat Android dengan
`FIREBASE_ENABLED=true`.
