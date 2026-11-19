# AGENTS.md — Panduan Kerja RyanGunshop

Berkas ini adalah pintu masuk bagi setiap orang dan setiap agen AI yang mengerjakan
proyek ini. Baca berkas ini lebih dahulu sebelum membaca berkas lain atau menulis kode.

Berkas ini melengkapi, bukan menggantikan:

- `PRODUCT.md` — apa yang dibangun, untuk siapa, dan batasannya.
- `DESIGN.md` — aturan visual, komponen, dan aturan interaksi.
- `README.md` — struktur proyek dan cara menjalankan.
- `TEAM.md` — siapa mengerjakan apa dan siapa pemilik berkas mana.
- `PROGRESS.md` — status pengerjaan terkini, peta fitur, dan langkah berikutnya.
- [docs/monitor-plan.md](docs/monitor-plan.md) — rencana dan status tahapan Monitor;
  implementasi fondasi lokal sudah disetujui pengguna.

## 1. Ringkasan proyek

RyanGunshop adalah aplikasi kasir dan pengelolaan warung untuk Android berbasis
Flutter/Dart. Inti pengalamannya adalah efisiensi kasir dan pencatatan transaksi:
Beranda kasir mempertahankan Hero Omzet harian, laporan, empat bento Aksi Cepat,
dan nota terkini. Beranda pemilik menyediakan analitik Hari ini/7 hari/30 hari,
perhatian stok, produk terlaris, dan aksi kelola. Keduanya memakai komponen Hero,
aksi, nota, serta Pintasan Menu bersama. Pembacaan native memakai cloud-first
melalui `CloudReadThrough`; SQLite/Drift tetap menyimpan data lokal, draft
keranjang, transaksi tunai, dan outbox untuk operasi offline. Web hanya pratinjau
lokal; QRIS nyata belum terverifikasi.

Karakter produk: praktis, tenang, jelas, dapat dipercaya. Violet modern (`#7C3AED`)
menjadi identitas tindakan dan navigasi. Antarmuka harus dapat dipakai tanpa pelatihan
teknis pada perangkat kelas bawah.

## 2. Cakupan berjalan — 19 November 2026

Tahap UI-only sudah dilewati. Cakupan yang disetujui pengguna mencakup:

- Native cloud-first melalui `CloudReadThrough`: hasil server digunakan ulang
  15 detik, backoff kegagalan 30 detik, timeout 8 detik dengan fallback cache
  SQLite/Drift. Perubahan tertunda dilindungi; revisi data sesi memperbarui UI.
  Migrasi, repository, transaksi lokal, dan pengujian tetap tersedia.
- Kamera barcode nyata melalui `mobile_scanner`, fallback manual, kelola produk
  pemilik, generator kode internal, dan label Code128.
- Analitik repository nyata, laporan harian PDF/XLSX dengan berbagi Android.
  Berbagi bukan penyimpanan otomatis ke Downloads; laba historis belum dihitung
  karena snapshot harga modal transaksi belum tersedia.
- Firebase native bersakelar `FIREBASE_ENABLED`, outbox SQLite, dan pengurasan
  saat startup, perubahan sesi, serta tiap 15 detik selama aplikasi berjalan.
  Bukan layanan sinkronisasi latar belakang Android. Produk lama tidak otomatis
  di-backfill; SDK siap bukan bukti unggah cloud berhasil.
- Impor Firestore proyek `iyangunshop`, toko `toko-utama`, terverifikasi:
  90 dokumen dibuat dan terbaca ulang, terdiri dari 24 produk dan 66 nota tunai,
  394 unit, Rp3.035.800. Rentang 10–24 November 2026 inklusif: 15 hari,
  3–6 nota/hari. Data presentasi tanpa label visual; asalnya tetap metadata internal.
- Monitor mulai dibangun: model, tiga template, validasi grid/JSON, repository
  layout lokal dan migrasi SQLite 6→7 tersedia. Setup/editor ortografik lokal
  serta tombol owner aktif. Penempatan massal, drag Edit, isometrik dan alert stok
  tersedia. Jalur sync layout+lokasi bertoken sudah ditulis, belum terverifikasi live. Target akhir tombol Beranda pemilik
  membuka halaman isometrik 2.5D ringan dari atas, Flutter native tanpa engine
  atau dependensi baru; bukan tab baru dan tidak mengubah navigasi yang ada.
  Detail dan batas cakupan mengikuti [rencana Monitor](docs/monitor-plan.md).
  `floor_plan` tetap arsip: kandidat penggunaan ulang wajib diaudit, bukan
  mengaktifkan kembali layar dengan data contoh.
- IyanBoT/Groq dengan tool baca dan draft yang perlu konfirmasi pengguna sebelum
  transaksi atau perubahan produk disimpan. Produk hanya dapat dikelola pemilik.
  Uji API langsung belum terverifikasi dan dijeda atas permintaan pengguna.

Belum menjadi jaminan produksi: autentikasi/login/PIN, isolasi tenant yang
terverifikasi, pemulihan cloud, pembayaran QRIS nyata, cetak fisik, foto koreksi
privat, model TFLite, dan rencana restok. `backend-agent` bukan syarat POS lokal.
Pergantian pemilik/kasir di Pengaturan adalah mode aplikasi, bukan batas keamanan.
Web memakai jalur pratinjau lokal tanpa SQLite/sinkronisasi native.

Akses baca tanpa autentikasi diketahui mengembalikan HTTP 200. Rules tidak
diubah; pengguna menolak penambahan login/PIN/Anonymous Auth. Jangan menganggap
impor berhasil sebagai bukti keamanan. Stok lintas perangkat masih
last-write-wins, bukan atomik; tidak ada snapshot atomik lintas halaman/koleksi,
dan pembacaan dibatasi 10.000 dokumen per koleksi.

Basis kode terakhir `a85a159` sudah dipush. Validasi terakhir yang dilaporkan:
analyzer bersih, 268 test Flutter dan 12 test Node impor lulus. APK cloud-first
+ Monitor berhasil dibangun, belum dipasang karena tidak ada Android tersambung.
Render widget tersedia pada 360/1024 dp skala 1,3; visual Android dan unduh data
cloud lewat aplikasi nyata belum terverifikasi.
Pembaruan dokumentasi bukan eksekusi ulang validasi.

Jangan membaca atau menyalin isi `.env`, kredensial, maupun konfigurasi privat
untuk memperbarui dokumentasi. Jangan commit rahasia. `--dart-define` bukan
penyimpanan rahasia yang aman dalam APK. Penambahan dependensi, layanan, atau
perluasan cakupan baru tetap memerlukan persetujuan dan pengujian.

## 3. Konteks peran

- Pemilik dan kasir dipilih melalui Pengaturan tanpa login. Kelola produk hanya
  untuk pemilik; pemeriksaan izin dibaca ulang saat penyimpanan. Denah/panorama
  adalah arsip, bukan navigasi utama.
- Setiap anggota tim hanya mengubah berkas dalam cakupan miliknya pada `TEAM.md`.
  Perubahan lintas pemilik memerlukan persetujuan eksplisit dan review lewat PR.
  Pengguna sudah menyetujui integrasi lintas fitur pada
  `feat/ui-shell-owner-barcode`; persetujuan itu bukan izin mengubah berkas di
  luar tugas aktif.
- Periksa `PROGRESS.md` sebelum mulai bekerja untuk mengetahui tugas yang sudah selesai,
  lalu perbarui baris Anda pada pull request yang sama saat tugas selesai.
- Tentukan Anda membantu siapa dari nama branch yang aktif: `feat/ui-shell-*`
  (Tariq), `feat/ui-spatial-*` (Farel), `feat/ui-commerce-*` (Blessly), atau
  `feat/backend-*` (fondasi backend). Bila tidak jelas, tanyakan sebelum menulis kode.

## 4. Struktur berkas yang disepakati

```text
mobile/lib/
├── main.dart
├── app/                       # shell, routing, navigasi
├── core/
│   ├── config/                # konfigurasi build dan bootstrap Firebase
│   ├── data/                  # SQLite/Drift, repository, outbox, sinkronisasi
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
- Nominal rupiah ditampilkan lewat `formatRupiah` di `core/format/rupiah.dart`.
  Data sintetis yang sengaja dimasukkan ke repository untuk presentasi tidak
  memerlukan label visual contoh, sintetis, atau demo.
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
| Beranda | Dashboard menurut peran: operasional kasir atau analitik/kelola pemilik |
| Kasir | Halaman transaksi belanja kasir: rincian barang, kuantitas, diskon, dan total bayar |
| Aksi Cepat | 4 Modul bento cepat di Beranda: Pindai Barcode, Buka Kasir, Stok, dan Riwayat Nota |
| SyncPill | Penanda status offline, antre sinkronisasi, atau tersinkron |
| QRIS | Pembayaran QR; statusnya `creating`, `awaitingPayment`, `paid`, `expired`, `failed` |
| Denah (arsip) | Pustaka tata letak 2D dan panorama 360 yang diarsipkan dari antarmuka utama |
| Monitor (rencana) | Pantau stok repository menurut lokasi utama produk pada tata letak isometrik 2.5D; bukan hitungan fisik per lokasi atau deteksi otomatis |

## 6. Aturan UI yang wajib dipatuhi

Bersumber dari `DESIGN.md`. Detail lengkap ada di sana, ringkasan ini untuk pekerjaan
harian.

**Warna.** Selalu ambil dari token tema, jangan menulis nilai heksadesimal langsung di
widget. Primary `#7C3AED` (Violet), primary dark `#6D28D9`, primary light `#EDE9FE`,
primary subtle `#F5F3FF`, accent `#A855F7`, canvas `#FAF8FE`, surface `#FFFFFF`,
ink `#0F172A`, muted `#64748B`, success `#10B981`, warning `#F59E0B`, error `#EF4444`.
Warna violet untuk aksi, pilihan, dan status aktif; permukaan pasif tetap netral bersih.

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
tersinkron yang belum dikonfirmasi. Data sintetis yang disimpan untuk presentasi
boleh tampil melalui komponen dan perhitungan biasa tanpa label contoh, sintetis,
atau demo. Asal data tetap dicatat secara internal melalui ID atau metadata agar
impor bisa diulang dan dibersihkan dengan aman. Pengecualian label ini tidak
mengizinkan status pembayaran atau sinkronisasi palsu. Badge lokal pada judul
Produk sudah dihapus; itu tidak berarti produk sudah tersimpan di cloud.

**Motion.** Splash memakai satu signature motion sekitar 1,45 detik dengan crossfade 280
ms, dan `disableAnimations` menghasilkan transisi instan. Sediakan reduced motion pada
onboarding. Kamera dilepas selama checkout dan disiapkan ulang bila kasir memindai lagi.

**Bahasa.** Seluruh teks antarmuka dan dokumentasi memakai bahasa Indonesia, dengan istilah
teknis yang lazim dipertahankan.

## 7. Cara menjalankan dan memverifikasi

Pratinjau validasi memakai emulator atau perangkat Android melalui ekstensi Flutter di VS
Code. Pratinjau web (`flutter run -d chrome`) hanya untuk melihat susunan layar dengan
cepat dan tidak dipakai untuk memvalidasi UI Android.

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
  `feat/ui-spatial-*`, `feat/ui-commerce-*`, atau `feat/backend-*` sesuai tugas.
- Commit dan push hanya bila diminta dalam tugas aktif; jangan memasukkan
  perubahan pengguna atau pekerjaan lain tanpa meninjau cakupannya.
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
