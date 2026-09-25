# AGENTS.md — Panduan Kerja RyanGunshop

Berkas ini adalah pintu masuk bagi setiap orang dan setiap agen AI yang mengerjakan
proyek ini. Baca berkas ini lebih dahulu sebelum membaca berkas lain atau menulis kode.

Berkas ini melengkapi, bukan menggantikan:

- `PRODUCT.md` — apa yang dibangun, untuk siapa, dan batasannya.
- `DESIGN.md` — aturan visual, komponen, dan aturan interaksi.
- `README.md` — struktur proyek dan cara menjalankan.
- `TEAM.md` — siapa mengerjakan apa dan siapa pemilik berkas mana.
- `PROGRESS.md` — status pengerjaan terkini dan langkah berikutnya.
- `TODO.md` — checklist fitur berdasarkan FR/NFR.

## 1. Ringkasan proyek

RyanGunshop adalah aplikasi kasir dan pengelolaan warung untuk Android berbasis
Flutter/Dart. Inti pengalamannya adalah denah warung: dashboard menampilkan tata letak
ruang, dan setiap objek ruang seperti rak, lemari, kulkas, atau meja kasir dapat dipilih
untuk melihat produk dan status stok di lokasi tersebut. Alur kasir berjalan dari
pindai atau pilih produk, konfirmasi, keranjang, lalu pembayaran tunai atau QRIS.

Karakter produk: praktis, tenang, jelas, dapat dipercaya. Slate blue menjadi identitas
tindakan dan navigasi. Antarmuka harus dapat dipakai tanpa pelatihan teknis pada
perangkat kelas bawah.

## 2. Cakupan tahap ini: UI saja

Tahap ini hanya mengerjakan **tampilan dan interaksi (frontend)**. Rancang seluruh layar
dengan data contoh lokal, bukan layanan nyata.

Dilarang dikerjakan sekarang:

- Drift/SQLite, Firestore, outbox, dan sinkronisasi.
- `backend-agent` (WhatsApp, Ollama, tool registry) dan webhook QRIS.
- Firebase Authentication, rules, index, Storage, dan App Check.
- Foto koreksi privat, dataset AI, dan model TFLite nyata.
- Perhitungan rencana restok dan laporan berbasis data nyata.

Komponen yang nantinya bergantung pada pekerjaan di atas tetap dibangun sekarang, tetapi
hanya sebatas tampilan dan state UI. Jika sebuah tugas terasa menuntut backend, hentikan
dan tanyakan, jangan diam-diam membuat lapisan data.

Panduan bagi agen AI: jangan menambahkan dependensi database, HTTP client, Firebase, atau
model machine learning. Jangan menulis kode inisialisasi layanan eksternal. Jangan
menambahkan kredensial, kunci API, atau berkas `.env`. Bila dokumen lain seperti
`README.md` menyebut komponen backend, perlakukan itu sebagai rencana tahap berikutnya,
bukan instruksi untuk sekarang.

## 3. Konteks peran

- Pemilik dan kasir adalah dua peran pengguna. Mode edit denah hanya untuk pemilik.
- Setiap anggota tim hanya mengubah berkas dalam cakupan miliknya pada `TEAM.md`.
  Perubahan pada berkas milik orang lain dilakukan lewat pull request.
- Periksa `PROGRESS.md` sebelum mulai bekerja untuk mengetahui tugas yang sudah selesai,
  lalu perbarui baris Anda pada pull request yang sama saat tugas selesai.
- Tentukan Anda membantu siapa dari nama branch yang aktif: `feat/ui-shell-*`
  (Tariq), `feat/ui-spatial-*` (Farel), `feat/ui-commerce-*` (Blessly). Bila tidak
  jelas, tanyakan sebelum menulis kode.

## 4. Struktur berkas yang disepakati

```text
mobile/lib/
├── main.dart
├── app/                       # shell, routing, navigasi
├── core/
│   ├── session/               # keadaan sesi lintas fitur, misalnya peran pengguna
│   ├── format/                # pemformatan bersama, misalnya nominal rupiah
│   ├── theme/                 # token warna, tipografi, spacing, radius
│   └── widgets/               # komponen dasar yang dipakai lintas fitur
└── features/<nama_fitur>/
    ├── model/                 # model UI dan enum state
    ├── view_model/            # satu ViewModel per fitur
    ├── view/                  # layar dan widget fitur
    └── sample/                # data contoh untuk preview
```

- Model UI dan data contoh disimpan di dalam folder fitur masing-masing, bukan di
  folder bersama.
- Keadaan yang dipakai lintas fitur, misalnya peran pemilik atau kasir, disimpan di
  `core/session/` dan dibaca lewat `AppSessionScope.of(context)`. Jangan menyalin peran
  ke variabel lokal fitur.
- Nominal rupiah ditampilkan lewat `formatRupiah` di `core/format/rupiah.dart`, dan
  setiap nilai contoh ditandai `SampleBadge` dari `core/widgets/`.
- Nama berkas memakai `snake_case`, kelas memakai `PascalCase`.
- Gunakan satu ViewModel per fitur. Gunakan `ChangeNotifier` bawaan Flutter kecuali tim
  menyepakati pustaka lain, agar tidak menambah dependensi tanpa kebutuhan.
- Seluruh istilah produk dan nama berkas yang sudah ada dipertahankan. Jangan mengganti
  nama produk, nama komponen pada `DESIGN.md`, atau istilah domain tanpa persetujuan tim.
- Perubahan pada `mobile/pubspec.yaml` (dependensi baru atau pendaftaran aset) diajukan
  lewat pull request karena berkas ini dipakai bersama, bukan ditulis langsung.

## 5. Istilah domain

| Istilah | Arti |
|---|---|
| Denah | Kanvas 2D tata letak warung memakai koordinat relatif, bukan piksel tetap |
| Fixture | Objek ruang pada denah: dinding, lorong, rak, lemari, kulkas, meja kasir |
| Zona | Area denah yang dipetakan ke satu panorama 360 derajat |
| Mode lihat | Mode normal; tap objek membuka daftar produk, gesture mengubah viewport |
| Mode edit | Mode khusus pemilik; drag memindahkan objek, tombol khusus mengubah objek |
| SyncPill | Penanda status offline, antre sinkronisasi, atau tersinkron |
| QRIS | Pembayaran QR; statusnya `creating`, `awaitingPayment`, `paid`, `expired`, `failed` |

## 6. Aturan UI yang wajib dipatuhi

Bersumber dari `DESIGN.md`. Detail lengkap ada di sana, ringkasan ini untuk pekerjaan
harian.

**Warna.** Selalu ambil dari token tema, jangan menulis nilai heksadesimal langsung di
widget. Primary `#565C9D`, primary dark `#34385F`, primary light `#E9EAF6`, accent
`#8B91D4`, canvas `#F7F7FB`, surface `#FFFFFF`, ink `#191A2E`, muted `#62657A`, success
`#287A66`, warning `#A86616`, error `#B44252`. Slate blue hanya untuk aksi, pilihan, dan
status; permukaan pasif tetap netral.

**Tipografi dan jarak.** Ukuran 28 sp untuk judul halaman, 20 sp judul bagian, 16 sp label
penting, 14 sp metadata. Jarak dasar 4 dp dengan kelipatan 8, 12, 16, 24, 32. Padding
layar ponsel 16 dp. Radius kontrol dan sheet 10–14 dp, objek denah 6–10 dp.

**Aksesibilitas dan layout.** Target sentuh minimal 48x48 dp. Status selalu memakai
kombinasi ikon, teks, dan warna, tidak boleh warna saja. Semua objek denah punya semantic
label yang menyebut jenis, nama, dan jumlah produk. Ikon yang tindakannya tidak universal
harus punya tooltip atau label. Layout harus tetap dapat dipakai pada text scale 1.3 dan
lebar 360 dp.

**State dan kejujuran data.** Setiap layar yang menampilkan data wajib punya state kosong,
memuat, error, dan offline, bukan hanya jalur bahagia. Empty state selalu menyediakan
tindakan lanjutan. Jangan pernah menampilkan pembayaran berhasil, stok tersedia, atau data
tersinkron yang belum dikonfirmasi. Karena tahap ini memakai data contoh, tandai status
sebagai contoh dan jangan membuatnya tampak seperti integrasi nyata.

**Motion.** Splash memakai satu signature motion sekitar 1,45 detik dengan crossfade 280
ms, dan `disableAnimations` menghasilkan transisi instan. Sediakan reduced motion pada
onboarding. Kamera dilepas selama checkout dan disiapkan ulang bila kasir memindai lagi.

**Bahasa.** Seluruh teks antarmuka dan dokumentasi memakai bahasa Indonesia, dengan istilah
teknis yang lazim dipertahankan.

## 7. Cara menjalankan dan memverifikasi

Pratinjau hanya lewat emulator atau perangkat Android melalui ekstensi Flutter di VS Code.
Pratinjau web tidak dipakai untuk memvalidasi UI Android.

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

Sebelum mengirim pull request, jalankan `flutter analyze` dan `flutter test`. Jangan
mengklaim pekerjaan sudah benar tanpa menjalankan keduanya.

## 8. Alur kerja Git

- `main` selalu dapat dijalankan. Bekerja di branch `feat/ui-shell-*`,
  `feat/ui-spatial-*`, atau `feat/ui-commerce-*` sesuai peran.
- Satu tugas sama dengan satu pull request. Setiap PR ditinjau minimal satu anggota lain
  dan di-merge dengan squash merge.
- Tidak ada force-push ke `main`.
- Commit ditulis dengan akun Git masing-masing anggota. Gaya pesan commit: baris subjek
  dalam kalimat imperatif, maksimal 50 karakter, tanpa tanda baca di akhir; isi pesan
  hanya bila memberi informasi yang tidak tampak dari subjek, dibungkus pada 72 karakter.
- Kerja berpasangan memakai trailer `Co-authored-by:` dan tetap di-commit oleh penulis
  utamanya.

## 9. Definisi selesai

Sebuah tugas selesai bila seluruh poin berikut terpenuhi:

1. Layar berjalan di emulator atau perangkat Android tanpa error analyzer.
2. State kosong, memuat, error, dan offline tersedia dan dapat dicoba.
3. Layout aman pada text scale 1.3 dan lebar 360 dp, target sentuh minimal 48 dp, dan
   status memakai ikon, teks, serta warna.
4. Tidak ada status palsu yang tampak seperti integrasi nyata.
5. `flutter analyze` dan `flutter test` lulus, dan hasilnya dicatat di deskripsi PR.
6. Berkas yang disentuh sesuai peta kepemilikan `TEAM.md`, dan PR sudah ditinjau serta
   di-merge.

## 10. Yang harus selalu dihindari

- Menambah pekerjaan backend atau dependensi baru tanpa persetujuan tim.
- Menulis warna, ukuran teks, atau jarak secara langsung di luar token tema.
- Menampilkan status berhasil, tersinkron, atau stok tersedia tanpa dasar data.
- Mengubah berkas milik anggota lain tanpa pull request dan review.
- Mengganti nama produk, nama komponen pada `DESIGN.md`, atau istilah domain.
- Memasukkan kredensial, kunci API, atau data pribadi ke dalam repository.
- Menyelesaikan lebih dari satu tugas dalam satu pull request.
