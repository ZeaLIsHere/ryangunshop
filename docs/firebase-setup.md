# Panduan Firebase & Firestore untuk RyanGunshop

Panduan langkah demi langkah membuat proyek Firebase, menyiapkan API key, dan
menghubungkannya ke aplikasi kasir RyanGunshop. Ikuti berurutan; setiap langkah
menyebutkan berkas yang berubah di repositori ini.

> **Status tahap ini.** Aplikasi tetap **offline-first**: semua transaksi dibaca
> dan ditulis ke SQLite (`Drift`). Firestore hanya menerima salinan lewat
> antrean outbox. Migrasi cloud masih menunggu persetujuan tim sesuai `AGENTS.md`
> dan belum boleh dianggap sebagai sinkronisasi produksi.

---

## 0. Ringkasan yang akan dibuat

| Kebutuhan | Nilai untuk proyek ini |
|---|---|
| Nama paket Android | `com.ryangunshop.ryangunshop` |
| Berkas konfigurasi Android | `mobile/android/app/google-services.json` |
| Koleksi Firestore | `stores/{storeId}/products`, `stores/{storeId}/transactions` |
| Toko bawaan | `toko-utama` (dapat diganti lewat `FIREBASE_STORE_ID`) |
| Sakelar integrasi | `--dart-define=FIREBASE_ENABLED=true` |
| Lokasi database | `asia-southeast2` (Jakarta) |
| Aturan keamanan | `firebase/firestore.rules` |
| Indeks | `firebase/firestore.indexes.json` |

Berkas kode yang sudah disiapkan:

- `mobile/lib/core/config/firebase_bootstrap.dart` — penyalaan Firebase yang aman.
- `mobile/lib/core/data/sync/firestore_schema.dart` — bentuk dokumen Firestore.
- `mobile/lib/core/data/sync/outbox.dart` — model antrean tulis.
- `mobile/lib/core/data/sync/sync_engine.dart` — penguras antrean.
- `mobile/lib/core/data/sync/firestore_sync_target.dart` — penulis ke Firestore.

---

## 1. Prasyarat

1. Akun Google (Gmail) yang boleh dipakai untuk aset toko.
2. Flutter 3.47+ dan Dart 3.13+ (sudah sesuai `pubspec.yaml`).
3. Firebase CLI dan FlutterFire CLI, dipasang sekali:

   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   ```

4. Perangkat Android dengan mode pengembang, atau emulator.

---

## 2. Membuat akun dan proyek Firebase

1. Buka <https://console.firebase.google.com> lalu masuk dengan akun Google.
   Bila belum punya, buat di <https://accounts.google.com/signup>.
2. Setujui syarat layanan. Akun Firebase gratis (paket **Spark**) sudah cukup
   untuk satu warung: 50.000 pembacaan dan 20.000 penulisan per hari, 1 GiB
   penyimpanan.
3. Tekan **Add project / Tambahkan proyek**.
4. Isi nama proyek, misalnya `ryangunshop-toko`. ID proyek akan ditambahkan
   angka di belakangnya (contoh `ryangunshop-toko-4f1a2`) dan **tidak dapat
   diubah** setelah dibuat.
5. Google Analytics boleh dimatikan untuk tahap ini. Bila dinyalakan, pilih
   lokasi akun Analytics di Indonesia.
6. Tunggu hingga proyek selesai dibuat, lalu masuk ke halaman proyek.

> Satu proyek Firebase dapat menampung beberapa warung. Setiap warung memakai
> cabang `stores/{storeId}` yang berbeda, bukan proyek terpisah.

---

## 3. Mendaftarkan aplikasi Android

1. Di halaman proyek, tekan ikon **Android** pada kartu "Get started".
2. **Android package name** wajib sama persis dengan
   `applicationId` di `mobile/android/app/build.gradle.kts`:
   `com.ryangunshop.ryangunshop`
3. **App nickname**: `RyanGunshop Android`.
4. **Debug signing certificate SHA-1**: isi sekarang agar login dan App Check
   tidak gagal di kemudian hari. Ambil dari komputer pengembang:

   ```powershell
   keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" `
     -alias androiddebugkey -storepass android -keypass android
   ```

   Salin baris `SHA1:`. Untuk APK rilis, ulangi dengan keystore rilis dan
   tambahkan juga SHA-1-nya lewat **Project settings → Your apps → Add
   fingerprint**.
5. Tekan **Register app**, lalu **Download google-services.json**.
6. Letakkan berkas itu di `mobile/android/app/google-services.json`.
   Berkas ini **tidak di-commit** (lihat `.gitignore`); bagikan lewat kanal
   internal tim.

### 3a. Mendaftarkan plugin Gradle

Tambahkan plugin Google Services. Ini hanya perlu sekali.

`mobile/android/settings.gradle.kts`:

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
    id("com.google.gms.google-services") version "4.4.3" apply false
}
```

`mobile/android/app/build.gradle.kts`, di blok `plugins` paling atas:

```kotlin
plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}
```

Versi plugin `4.4.3` adalah versi yang stabil saat panduan ini ditulis; periksa
rilis terbaru di <https://developers.google.com/android/guides/google-services-plugin>
bila Gradle menolak versinya.

Jalankan `flutter clean` lalu `flutter run` setelah perubahan Gradle.

---

## 4. Menyiapkan API key

Firebase membuat API key otomatis. Ada dua tempat melihatnya:

- `google-services.json` → `client[].api_key[].current_key`.
- Firebase Console → **Project settings** (ikon gerigi) → **General** →
  **Your apps** → **API key**, atau Google Cloud Console → **APIs & Services**
  → **Credentials**.

### 4a. Pilih cara memasukkan konfigurasi

**Cara A — `google-services.json` (paling sederhana, khusus Android).**
Cukup taruh berkas pada langkah 3 dan nyalakan sakelar:

```powershell
flutter run --dart-define=FIREBASE_ENABLED=true
```

**Cara B — `dart-define` dari `.env` (dipakai proyek ini, tanpa berkas
rahasia di repositori).** Tambahkan baris berikut ke `.env` di akar repositori
(berkas ini sudah di-.gitignore):

```dotenv
FIREBASE_ENABLED=true
FIREBASE_API_KEY=AIza...
FIREBASE_PROJECT_ID=ryangunshop-toko-4f1a2
FIREBASE_APP_ID=1:1234567890:android:abcdef123456
FIREBASE_MESSAGING_SENDER_ID=1234567890
FIREBASE_STORAGE_BUCKET=ryangunshop-toko-4f1a2.firebasestorage.app
FIREBASE_STORE_ID=toko-utama
```

Jalankan dengan:

```powershell
flutter run --dart-define-from-file=../.env
```

`.vscode/launch.json` sudah memakai `--dart-define-from-file=../.env`, jadi
tombol Run di VS Code langsung membaca berkas itu. Untuk APK:

```powershell
flutter build apk --dart-define-from-file=../.env
```

`FIREBASE_APP_ID` diambil dari `mobilesdk_app_id` pada `google-services.json`.
Aplikasi memilih cara B lebih dahulu; bila tiga nilai wajib
(`FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`, `FIREBASE_APP_ID`) kosong, aplikasi
memakai `google-services.json`.

**Cara C — FlutterFire CLI (untuk menambah iOS/web nanti).**

```bash
cd mobile
flutterfire configure --project=ryangunshop-toko-xxxxx
```

Perintah ini membuat `mobile/lib/firebase_options.dart` dan mendaftarkan
aplikasi iOS/web. Berkas hasilnya **di-.gitignore** karena memuat ID proyek dan
API key. Kode saat ini belum mengimpor berkas itu; bila memakai cara C, ubah
`FirebaseBootstrap.options` agar membaca
`DefaultFirebaseOptions.currentPlatform`. Untuk Android saja, cara A atau B
lebih sederhana.

### 4b. Membatasi API key (wajib sebelum rilis)

API key Firebase pada aplikasi klien **bukan rahasia** — ia ikut terkirim di
APK. Yang melindungi data adalah aturan Firestore (langkah 6). Meski begitu,
batasi kunci agar tidak disalahgunakan:

1. Buka Google Cloud Console → **APIs & Services → Credentials**.
2. Klik API key yang dipakai aplikasi Android.
3. **Application restrictions** → *Android apps* → tambahkan
   `com.ryangunshop.ryangunshop` beserta SHA-1 debug dan rilis.
4. **API restrictions** → *Restrict key* → pilih hanya **Cloud Firestore API**
   (tambahkan **Firebase Installations API** bila memakai App Check).
5. Simpan, lalu uji ulang aplikasi.

Yang **tidak boleh** dilakukan: menaruh service account JSON, private key, atau
kata sandi akun Firebase di repositori/APK. Jangan pernah memakai kunci server
di aplikasi klien.

### 4c. Anggaran dan kuota

- Firebase Console → **Usage and billing** → **Details & settings** → atur
  **Budget alert** (mis. 5 USD) agar tidak terkejut bila kuota gratis habis.
- Tahap ini sengaja tetap di paket Spark; jangan mengaktifkan Blaze tanpa
  persetujuan tim.

---

## 5. Membuat database Firestore

1. Menu kiri → **Build → Firestore Database** → **Create database**.
2. Pilih **Production mode** (bukan test mode) agar tidak ada data terbuka.
3. **Location**: `asia-southeast2` (Jakarta). Lokasi tidak dapat diubah setelah
   dibuat.
4. Setelah database aktif, buka tab **Rules** dan tempel isi
   `firebase/firestore.rules`, lalu **Publish**.
5. Buka tab **Indexes** → **Composite** → impor `firebase/firestore.indexes.json`
   atau biarkan Firestore menawarkan tautan pembuatan indeks saat kueri pertama
   dijalankan.

### 5a. Deploy aturan dengan CLI (opsional, disarankan)

Dari akar repositori:

```bash
firebase login
firebase use --add          # pilih proyek, beri alias "default"
firebase deploy --only firestore:rules,firestore:indexes
```

`firebase.json` di akar repositori sudah menunjuk ke `firebase/firestore.rules`
dan `firebase/firestore.indexes.json`.

---

## 6. Menyiapkan akses pengguna

Aturan pada `firebase/firestore.rules` mensyaratkan pengguna terautentikasi dan
terdaftar sebagai anggota toko.

1. Menu **Build → Authentication → Get started**.
2. Aktifkan **Anonymous** untuk uji coba awal di perangkat.
3. Daftarkan perangkat ke toko dengan salah satu cara:
   - **Custom claim** (disarankan untuk produksi): set
     `storeId = "toko-utama"` dan `role = "owner"` lewat Admin SDK/Cloud
     Function, atau
   - **Dokumen anggota**: buat dokumen
     `stores/toko-utama/members/{uid}` berisi `{ "role": "owner" }`.
     Aturan sudah menerima cara ini tanpa server tambahan.
4. Untuk produksi, ganti Anonymous dengan **Email/Password** atau
   **Google Sign-In** agar akun pemilik dan kasir dapat dibedakan.

`firebase_auth` sudah ada di `pubspec.yaml`, tetapi layar masuk belum dibuat.
Sampai layar itu ada, aplikasi hanya menulis ke antrean lokal.

---

## 7. Menyalakan sinkronisasi di aplikasi

Ringkasan alur yang sudah tersedia:

```text
kasir menekan bayar
   └─ SQLite: nota + stok + entri outbox (satu transaksi)
        └─ SyncEngine.flush()
             └─ FirestoreSyncTarget.apply()
                  └─ Firestore: stores/{storeId}/transactions/{TRX-...}
```

Yang perlu ditambahkan saat integrasi resmi disetujui:

1. Panggil `FirebaseBootstrap.ensureInitialized()` (sudah dipanggil di
   `mobile/lib/main.dart`) dan pastikan `FirebaseBootstrap.isReady` bernilai
   `true`.
2. Buat mesin sinkronisasi dan jalankan saat aplikasi dibuka, saat checkout
   berhasil, dan saat koneksi kembali:

   ```dart
   final engine = SyncEngine(
     queue: DriftSyncQueue(database),
     target: FirestoreSyncTarget(
       firestore: FirebaseFirestore.instance,
       storeId: FirebaseBootstrap.storeId,
     ),
   );

   final result = await engine.flush();
   ```

3. Tampilkan `result.status` (`offline`, `pending`, `synced`) pada `SyncPill`
   di Beranda atau Pengaturan. Jangan pernah menampilkan "Tersinkron" sebelum
   `flush()` mengembalikan `SyncStatus.synced`.

---

## 8. Verifikasi

1. Jalankan aplikasi dengan `FIREBASE_ENABLED=true`.
2. Tambah satu produk, lalu lakukan pembayaran tunai.
3. Buka Firestore Console dan pastikan muncul:
   `stores/toko-utama/products/{id}` dan
   `stores/toko-utama/transactions/TRX-...` dengan `items` terisi.
4. Putuskan internet, lakukan satu transaksi lagi, lalu sambungkan kembali dan
   panggil `flush()`. Nota harus muncul tanpa duplikat.
5. Jalankan pemeriksaan proyek:

   ```bash
   cd mobile
   flutter analyze
   flutter test
   ```

### Masalah yang sering muncul

| Gejala | Penyebab umum | Tindakan |
|---|---|---|
| `[core/not-initialized]` | Firebase belum menyala | Pastikan `FIREBASE_ENABLED=true` dan tiga nilai wajib terisi |
| `PERMISSION_DENIED` | Belum login atau belum jadi anggota toko | Aktifkan Anonymous, daftarkan `members/{uid}` atau custom claim |
| `No Firebase App '[DEFAULT]'` | `ensureInitialized()` belum selesai | Panggil sebelum memakai `FirebaseFirestore.instance` |
| `google-services.json` tidak ditemukan | Berkas belum diletakkan | Salin ke `mobile/android/app/` lalu `flutter clean` |
| `ApiException: 10` di Android | SHA-1 / package name tidak cocok | Daftarkan ulang fingerprint di Firebase Console |
| Kueri minta indeks | Indeks komposit belum dibuat | Ikuti tautan pada pesan galat atau deploy `firestore.indexes.json` |
| Data ganda | ID nota tidak unik | Nota memakai `TRX-<microsecondsSinceEpoch>`; jangan membuat ID acak baru saat retry |

---

## 9. Checklist sebelum rilis

- [ ] `google-services.json` tidak ikut ter-commit.
- [ ] API key dibatasi ke paket Android dan Cloud Firestore API.
- [ ] Firestore dalam mode produksi, bukan test mode.
- [ ] Aturan keamanan diuji (Rules Playground) untuk pengguna tanpa izin.
- [ ] Budget alert aktif.
- [ ] Sinkronisasi tidak pernah menampilkan status "Tersinkron" tanpa bukti.
- [ ] `flutter analyze` dan `flutter test` lulus.
- [ ] Persetujuan tim untuk keluar dari tahap lokal dicatat di `PROGRESS.md`.
