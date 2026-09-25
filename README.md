# RyanGunshop

Aplikasi kasir dan pengelolaan warung untuk Android berbasis Flutter/Dart, disusun dari
Mini-SRS RyanGunshop. Mini-SRS dipakai sebagai sumber requirement, bukan sebagai
instruksi langsung.

## Tim

| Nama | NIM |
|---|---|
| M. Al Farel Azhar | 241401009 |
| Tariq Rahmadari | 241401021 |
| Blessly Victory Deo Silaban | 241401060 |

Peran dan porsi kerja masing-masing ada di [TEAM.md](TEAM.md).

## Cakupan tahap ini: UI

Tahap ini hanya mengerjakan **tampilan dan interaksi (frontend)**. Seluruh layar memakai
data contoh lokal, dan belum ada basis data, sinkronisasi, autentikasi, maupun integrasi
pembayaran nyata. Rencana pekerjaan selanjutnya dipisahkan pada bagian
[Tahap berikutnya](#tahap-berikutnya) agar tidak terbaca sebagai instruksi sekarang.

Mulai membaca dari berkas berikut:

| Berkas | Isi |
|---|---|
| `AGENTS.md` | Aturan kerja untuk anggota tim dan agen AI |
| `PRODUCT.md` | Apa yang dibangun, untuk siapa, dan batasannya |
| `DESIGN.md` | Aturan visual, komponen, dan aturan interaksi |
| `TEAM.md` | Pembagian tugas, pemilik berkas, dan alur kerja Git |
| `PROGRESS.md` | Status pengerjaan, peta fitur, dan langkah berikutnya |

## Struktur

```text
mobile/
├── lib/
│   ├── main.dart
│   ├── app/                 # shell, routing, splash, dan keadaan awal
│   ├── core/
│   │   ├── session/         # keadaan sesi lintas fitur, misalnya peran pengguna
│   │   ├── format/          # pemformatan bersama, misalnya nominal rupiah
│   │   ├── theme/           # token warna, tipografi, jarak, dan radius
│   │   └── widgets/         # komponen dasar yang dipakai lintas fitur
│   └── features/<nama_fitur>/
│       ├── model/           # model UI dan enum state
│       ├── view_model/      # satu ViewModel per fitur
│       ├── view/            # layar dan widget fitur
│       └── sample/          # data contoh untuk pratinjau
├── test/                    # pengujian unit dan widget, mengikuti susunan lib/
└── android/                 # proyek Android (min API 26)
docs/
└── COLOR_PALETTE.md         # palet warna dan aturan kontras
```

## Menjalankan aplikasi

### Pratinjau Android dari VS Code

1. Pasang extension rekomendasi **Dart** dan **Flutter** saat VS Code menawarkan
   rekomendasi workspace.
2. Buka Command Palette, jalankan `Flutter: Launch Emulator`, lalu pilih salah satu
   emulator Android.
3. Pilih konfigurasi **RyanGunshop — Android Preview** pada panel Run and Debug,
   kemudian tekan `F5`.
4. Gunakan hot reload dan `Flutter: Open DevTools` untuk membuka Widget Inspector di
   samping editor.

Konfigurasi berada di `.vscode/extensions.json` dan `.vscode/launch.json`. Pratinjau web
tidak dipakai untuk memvalidasi UI Android.

### Terminal

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

Belum ada langkah code generation pada tahap ini karena belum ada basis data.

## Tahap berikutnya

Bagian ini adalah rencana, bukan instruksi untuk sekarang. Berkas dan dependensinya
belum ada di dalam repository.

### Lapisan data dan sinkronisasi

- Drift/SQLite sebagai sumber kebenaran UI saat offline, Firestore untuk sinkronisasi.
- Outbox untuk perubahan produk dan tata letak, beserta penanganan konflik.
- Rencana restok dihitung lokal dari rata-rata penjualan 28 hari, lead time pemasok,
  stok pengaman, dan target persediaan tujuh hari setelah barang tiba.
- Peran pengguna ditentukan dari klaim akun, bukan dari pilihan di halaman pengaturan.

### Pembayaran QRIS

QRIS dinamis memerlukan akun merchant dan API payment gateway resmi. Rahasia, pembuatan
charge, signature, serta penerimaan webhook tidak boleh berada di aplikasi. Transaksi
QRIS baru dianggap berhasil setelah webhook provider tervalidasi.

### `backend-agent`

Node/TypeScript untuk WhatsApp, Ollama, dan Firestore. Agent tidak menerima path
collection atau `storeId` dari LLM; seluruh angka bisnis berasal dari tool registry yang
membaca Firestore.

```bash
cd backend-agent
npm install
npm run check
npm run test:firebase
```

Salin `.env.example` menjadi `.env`, lalu isi kredensial WhatsApp, Ollama, dan Firebase.
Berkas `.env` tidak boleh masuk repository.

### Foto koreksi privat

Foto koreksi hanya diambil setelah consent eksplisit. Aplikasi menghapus EXIF/GPS,
membatasi sisi terpanjang menjadi 1280 px, menyimpannya di direktori privat, lalu
mengantrekan upload tenant-scoped saat perangkat kembali online. Penolakan consent atau
kegagalan foto tidak membatalkan produk yang sudah dipilih kasir.

Sebelum mengaktifkannya di produksi, aktifkan Firebase Storage pada paket Blaze, deploy
rules, lalu pasang lifecycle penghapusan 30 hari pada bucket yang benar:

```bash
firebase deploy --only storage
gcloud storage buckets update gs://BUCKET_NAME \
  --lifecycle-file=firebase/storage.lifecycle.json
```

Gunakan Firebase Console untuk memantau request App Check sebelum menyalakan
enforcement Storage.

### Klasifikasi produk di perangkat

1. Tambahkan model float32 `[1,H,W,3]` ke
   `mobile/assets/models/product_classifier.tflite`.
2. Isi `mobile/assets/models/labels.txt`, satu label per baris.
3. Daftarkan aset model di `mobile/pubspec.yaml`.
4. Kalibrasi normalisasi input dan confidence threshold pada perangkat target.

Classifier dibuat lazy sehingga aplikasi dasar tetap dapat dibuka tanpa model.

## Prinsip data

Prinsip berikut berlaku saat lapisan data dikerjakan, dan belum diterapkan pada tahap UI.

- Nominal memakai `int` rupiah, bukan floating point. Pemformatannya sudah tersedia di
  `mobile/lib/core/format/rupiah.dart`.
- Checkout, item snapshot, dan pengurangan stok berada dalam satu transaksi SQLite.
- Password tidak disimpan aplikasi; autentikasi memakai Firebase Authentication.
- Foto koreksi tidak dapat dibaca kembali oleh client; akses dataset hanya melalui
  backend Admin SDK yang diaudit, dan objek otomatis dihapus setelah 30 hari.

Dokumen keputusan dashboard ada di [PRODUCT.md](PRODUCT.md) dan
[DESIGN.md](DESIGN.md).
