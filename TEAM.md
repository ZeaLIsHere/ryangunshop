# RyanGunshop — Pembagian Tugas Tim

Dokumen ini menetapkan peran, kepemilikan berkas, dan urutan pekerjaan tiga anggota
tim agar porsi kerja seimbang dan jejak kontribusinya terlihat jelas di GitHub.

**Cakupan berjalan — 19 November 2026:** tahap UI-only sudah dilewati. POS Android
memakai cloud-first native `CloudReadThrough` dengan cache/operasi offline
SQLite/Drift, kamera `mobile_scanner`, kelola produk pemilik dan label Code128,
laporan PDF/XLSX berbagi Android, serta analitik repository nyata. Firebase
native/outbox bersakelar dan IyanBoT/Groq terintegrasi. Impor Firestore sudah
terverifikasi; APK cloud-first dan unduh data lewat aplikasi nyata belum
terverifikasi. Pengujian live Groq dijeda pengguna; QRIS nyata belum terverifikasi.
Basis kode terakhir dipush: `a85a159`.

Branch `feat/ui-shell-owner-barcode` membantu Tariq. Pengguna menyetujui integrasi
lintas fitur pada branch ini; kepemilikan dan review PR tetap berlaku, bukan izin
umum mengubah berkas di luar tugas aktif. Pemilik/kasir dipilih di Pengaturan
tanpa login: pembatasan kelola produk bukan batas keamanan produksi.

`TEAM.md` adalah peta **siapa mengerjakan apa**, sedangkan papan status pengerjaan ada
di `PROGRESS.md`. Berkas itu mencatat tugas yang sudah selesai, yang sedang jalan,
serta peta fitur beserta statusnya.

## Anggota dan peran

| Anggota | NIM | Peran | Tanggung jawab utama |
|---|---|---|---|
| Tariq Rahmadari (Tariq) | 241401021 | Fondasi, Shell, dan Dashboard | Tema dan komponen dasar, kerangka aplikasi, navigasi, splash, onboarding, dashboard |
| M. Al Farel Azhar (Farel) | 241401009 | Pengalaman Spasial dan Aksesibilitas | Denah, objek ruang, mode lihat/edit, panorama 360, identitas visual, audit aksesibilitas |
| Blessly Victory Deo Silaban (Blessly) | 241401060 | Katalog dan Kasir | Katalog produk, formulir produk, pemindai, keranjang, pembayaran |

## Peta kepemilikan berkas

Satu berkas hanya boleh dimiliki satu orang. Perubahan pada berkas milik orang lain
memerlukan persetujuan eksplisit dan review lewat pull request. Persetujuan
integrasi pengguna tidak memindahkan kepemilikan permanen. Cakupan yang belum
tercantum harus disepakati sebelum diubah, bukan dianggap bebas dimiliki agen.

| Cakupan berkas | Pemilik |
|---|---|
| `mobile/lib/main.dart`, `mobile/lib/app/**` (shell, routing, navigasi) | Tariq |
| `mobile/lib/core/theme/**`, `mobile/lib/core/widgets/**` | Tariq |
| `mobile/lib/features/onboarding/**`, `mobile/lib/features/dashboard/**` | Tariq |
| `mobile/lib/features/reports/**`, `docs/COLOR_PALETTE.md` | Tariq |
| `mobile/pubspec.yaml`, `mobile/analysis_options.yaml`, `.vscode/**` | Tariq |
| `PROGRESS.md` (papan status) | Tariq |
| `mobile/lib/features/floor_plan/**`, `mobile/lib/features/panorama/**` | Farel |
| `mobile/assets/branding/**`, `mobile/tool/**`, `docs/a11y.md` | Farel |
| `mobile/lib/features/catalog/**`, `mobile/lib/features/scanner/**` | Blessly |
| `mobile/lib/features/checkout/**`, `mobile/lib/features/payment/**` | Blessly |
| `docs/ui-flow.md`, `README.md` | Blessly |
| `PRODUCT.md` | Tariq |
| `DESIGN.md` | Farel |

Data contoh untuk preview disimpan di dalam folder fitur masing-masing, bukan di satu
folder bersama, agar tidak ada berkas yang dipakai dua orang.

`mobile/pubspec.yaml` dipakai bertiga, tetapi pemiliknya Tariq karena ia yang menyiapkan
dependensi. Perubahan dependensi baru atau pendaftaran aset (misalnya `assets/branding/`
dan `assets/models/`) diajukan lewat pull request agar tidak berbenturan.

Lapisan `core/config/**`, `core/data/**`, `core/session/**`, `core/format/**`,
fitur baru di luar tabel, pengujian terkait, serta dokumen `AGENTS.md`, `TEAM.md`,
dan `instruksi.md` harus ditetapkan penanggung jawabnya dalam tugas/PR integrasi;
tabel lama tidak otomatis memberi kepemilikan baru. Tugas dokumentasi
19 November ini mencakup seluruh dokumen operasional dan rencana kanonis
`docs/monitor-plan.md`, tanpa mengubah pemilik permanen. Referensi desain di
`contoh-desain/` dan panduan `.agents/skills/` tetap sebagai referensi.
Kode aplikasi, migrasi, rules, dan dependensi di luar cakupan tugas ini.
Tidak ada commit/push dalam tugas ini.

`PROGRESS.md` dikecualikan dari aturan satu pengubah: setiap anggota hanya menyunting
baris tugasnya sendiri, dan pembaruan itu dilakukan pada pull request tugas tersebut.

## Monitor — usulan koordinasi, bukan kepemilikan baru

Pengguna sudah menyetujui pembangunan; UI isometrik/editor/penempatan/alert lokal
tersedia. Jalur cloud layout belum diuji live; validasi perangkat masih diperlukan. Rujukan kanonis:
[docs/monitor-plan.md](docs/monitor-plan.md). Tombol Beranda pemilik membuka
halaman isometrik 2.5D ringan Flutter native, tanpa engine/dependensi, login,
atau tab baru; navigasi yang ada tetap.

| Usulan penanggung jawab | Cakupan yang perlu disepakati sebelum implementasi |
|---|---|
| Farel | Tampilan spasial, tiga template, editor fixture, audit arsip `floor_plan`, aksesibilitas |
| Tariq | Tombol/routing Beranda pemilik serta koordinasi data bersama dan persistensi draft |
| Blessly | Review penempatan produk, filter massal/konfirmasi, `fixtureId`, `locationLabel`, ambang stok, dan dampak katalog/kasir |

Usulan ini tidak memindahkan kepemilikan permanen. Perubahan lintas pemilik
memerlukan persetujuan eksplisit dan review PR. Arsip `floor_plan` hanya kandidat
penggunaan ulang setelah audit, bukan layar data contoh yang langsung diaktifkan.

Batas review: pilih template lalu tempatkan produk; produk tanpa lokasi boleh
ditunda. Satu fixture utama per produk, stok dari repository tanpa hitungan
salinan. Pantau/Edit terpisah; snap ke grid, tambah/nama/pindah/putar 90°/hapus
rak, kulkas, meja kasir. Draft Simpan/Batal dan konfirmasi keluar; hapus fixture
melepas penempatan, bukan menghapus produk; pindah tidak mengubah stok.
Tidak ada kuantitas fisik per lokasi atau deteksi otomatis. Bottom sheet ponsel,
panel samping tablet; ≥48 dp, 360 dp/text scale 1.3, state kosong/memuat/error/offline.

## Alur kerja Git

Tujuan alur ini adalah membuat riwayat repository menunjukkan tiga kontributor dengan
volume setara, bukan satu akun yang mengerjakan semuanya.

- `main` selalu dapat dijalankan. Setiap orang bekerja di branch sendiri:
  `feat/ui-shell-<topik>` (Tariq), `feat/ui-spatial-<topik>` (Farel),
  `feat/ui-commerce-<topik>` (Blessly); fondasi backend memakai `feat/backend-*`
  dengan penanggung jawab yang disepakati pada tugas/PR.
- Commit dan push hanya atas permintaan tugas aktif. Jangan sertakan perubahan
  pengguna atau pekerjaan lain tanpa pemeriksaan cakupan.
- Setiap anggota melakukan commit dengan akun Git masing-masing
  (`git config user.name` / `user.email` pada perangkat masing-masing).
- Satu pull request untuk satu tugas pada tabel fase di bawah, sehingga setiap orang
  menyelesaikan jumlah PR yang sama. PR wajib punya minimal satu reviewer dari anggota
  lain; rotasi reviewer agar setiap orang meninjau sejumlah PR yang seimbang.
- Kerja berpasangan diperbolehkan, tetapi commit tetap milik penulis aslinya dan
  ditambah trailer `Co-authored-by:` bila memang dikerjakan bersama.
- Tidak ada force-push ke `main`. Gunakan squash merge agar satu tugas setara satu
  kontribusi.
- Setiap akhir fase, ketiga anggota merge PR masing-masing pada minggu yang sama agar
  grafik kontribusi tidak menumpuk pada satu orang.
- Setiap tugas yang selesai memperbarui `PROGRESS.md` pada pull request yang sama, agar
  anggota lain dan agen AI mereka tahu kemajuan tanpa menunggu akhir fase.

## Riwayat pembagian tugas UI — Fase 0–5

Tabel fase berikut menyimpan pembagian awal tahap UI, bukan larangan integrasi
nyata saat ini dan bukan daftar pekerjaan baru. Kata data contoh/simulasi pada
tabel merujuk tahap tersebut. Status mutakhir dan bukti kerja ada di `PROGRESS.md`.

Setiap fase menyediakan satu tugas utama per anggota, sehingga porsi dan jumlah PR
tetap seimbang sampai akhir. Penyeimbangnya adalah besar usaha, bukan jumlah berkas,
karena satu kanvas denah dan satu layar pemindai berbobot lebih besar daripada
beberapa komponen kecil.

### Urutan ketergantungan

Fase 0 milik Tariq adalah prasyarat keras: tanpa proyek Flutter dan token tema, berkas
Dart anggota lain tidak dapat dikompilasi. Karena itu PR bootstrap Tariq di-merge lebih
dahulu, lalu Farel dan Blessly bercabang dari `main`. Urutan ini tidak mengubah porsi
kontribusi karena setiap fase tetap satu PR per orang. Pekerjaan murni dokumen
(`docs/a11y.md`, `docs/ui-flow.md`) boleh berjalan paralel tanpa menunggu bootstrap.

### Integrasi berjalan setelah tahap UI

Selain tugas fasenya, Tariq memegang `mobile/lib/app/**`, jadi ia yang menyambungkan
fitur anggota lain ke kerangka aplikasi begitu fiturnya di-merge. Tugas ini tidak muncul
di tabel fase padahal nyata, dan itulah sebabnya jumlah tugas fase Tariq lebih sedikit.

Beranda kasir mempertahankan Hero Omzet, empat bento, laporan, dan nota; Beranda
pemilik menampilkan analitik Hari ini/7 hari/30 hari, perhatian stok, produk
terlaris, serta aksi kelola. Hero/aksi/nota dibagi lewat komponen bersama.
Pintasan Menu katalog/keranjang/riwayat/pengaturan/statistik/chatbot dipulihkan
pada keduanya. `ProductCatalog` berjudul Produk memakai grid lazy responsif
2/3/5 kolom pada 360/600/1024 dp, text scale 1.3; badge lokal judul dihapus.
`CartCheckoutScreen` mencatat tunai ke SQLite; QRIS tetap simulasi.

Laporan harian PDF/XLSX berasal dari repository dan dibagikan Android, bukan
auto Downloads; laba historis belum tersedia tanpa snapshot modal. Firebase
menguras outbox saat startup/perubahan sesi dan tiap 15 detik selama aplikasi
berjalan, bukan layanan latar belakang. `CloudReadThrough` memakai ulang hasil
server 15 detik, backoff kegagalan 30 detik, timeout 8 detik dengan fallback
cache. Perubahan tertunda dilindungi; revisi data sesi memperbarui UI. Produk
lama tidak otomatis di-backfill. Web tetap pratinjau lokal tanpa SQLite/cloud-first
native; SDK siap bukan bukti semua data tersimpan di cloud.
Draft IyanBoT perlu konfirmasi dan produk hanya pemilik; live API belum diuji.

### Fase 0 — Fondasi UI dan aset

| Pemilik | Tugas | Bukti kontribusi |
|---|---|---|
| Tariq | Menyiapkan proyek Flutter `mobile/` (min API 26), struktur `lib/`, dependensi UI, `.gitignore`, `.vscode/extensions.json` dan `launch.json` untuk pratinjau Android, serta token tema di `core/theme/**` dan `docs/COLOR_PALETTE.md` | PR scaffold + aplikasi kosong berjalan di emulator |
| Farel | Menetapkan skema koordinat relatif 2D dan konstanta template area warung (dinding, lorong, rak, lemari, kulkas, meja kasir), membuat komponen `FixtureTile` dasar, menambahkan aset brand dan `tool/generate_brand_assets.dart` | PR model denah + launcher icon tergenerasi |
| Blessly | Menyusun model UI katalog, keranjang, dan state pembayaran dengan data contoh, membuat layar `ProductCatalog` daftar statis, dan menulis `docs/ui-flow.md` | PR katalog statis + daftar alur layar |

### Fase 1 — Kerangka aplikasi dan komponen dasar

| Pemilik | Tugas | Bukti kontribusi |
|---|---|---|
| Tariq | Membangun app shell, routing, dan navigasi bawah, serta komponen dasar di `core/widgets` (`PrimaryAction`, sheet, input, kartu, dialog, `BrandSpinner`, dan `RyanAppLogo`) | PR shell + komponen dasar siap dipakai fitur lain |
| Farel | Membangun `StoreFloorPlan` mode lihat (zoom dan pan, koordinat relatif 2D) serta `ModeSwitch` Denah dan 360° yang tidak aktif saat panorama zona belum tersedia | PR kanvas denah + widget test zoom/pan |
| Blessly | Menyelesaikan `ProductCatalog` (pencarian, filter stok menipis, kartu ringkas, empty state dengan CTA tambah) dan kerangka `ProductForm` dengan section bertahap | PR katalog + form + test validasi |

### Fase 2 — Splash, onboarding, dan dashboard

| Pemilik | Tugas | Bukti kontribusi |
|---|---|---|
| Tariq | Membangun splash dengan motion 1,45 detik, crossfade 280 ms, dan perilaku `disableAnimations`, lalu `OnboardingCarousel` tiga halaman dengan indikator progres dan tombol Lewati, Lanjut, serta Mulai (mendukung reduced motion), serta dashboard home bergaya bento dengan satu aksi utama dan shortcut | PR splash + onboarding + dashboard |
| Farel | Menambahkan mode edit denah (drag objek, kontrol rotasi, ukuran, duplikasi, hapus, penamaan), semantic label, target sentuh 48 dp, serta `SyncPill` dengan state offline, antre, dan tersinkron | PR mode edit + uji tanpa geser tak sengaja |
| Blessly | Menyelesaikan `ProductForm` (foto, identitas, harga dan stok, lokasi, validasi inline, tombol simpan terjangkau) dan layar detail produk | PR form + test validasi inline |

### Fase 3 — Denah operasional dan pemindai

| Pemilik | Tugas | Bukti kontribusi |
|---|---|---|
| Tariq | Membuat halaman pengaturan dan state peran (mode edit hanya untuk owner, akses kasir), menyambungkan navigasi ke kasir, dan menempatkan `PrimaryAction` "Mulai pindai" | PR pengaturan + state peran |
| Farel | Menyambungkan denah ke daftar produk per fixture lewat bottom sheet yang dapat dicari (dengan empty dan error state) serta menampilkan sorot rak dari hasil pemindaian | PR interaksi denah + widget test |
| Blessly | Membangun `ProductScanner` lengkap (preview kamera layar penuh, bingkai panduan, panel hasil bawah, konfirmasi eksplisit, indikator confidence, lampu, barcode, pencarian manual, permission dan error state dengan jalan keluar tanpa kamera); deteksi disimulasikan karena AI ditunda | PR pemindai + uji state tanpa izin kamera |

### Fase 4 — Pembayaran, panorama, dan laporan

| Pemilik | Tugas | Bukti kontribusi |
|---|---|---|
| Tariq | Membuat layar riwayat dan laporan transaksi (UI dengan data contoh) serta merapikan state kosong, memuat, dan error pada layar miliknya | PR laporan + uji state kosong |
| Farel | Membangun viewer panorama 360 per zona memakai foto equirectangular contoh dan merapikan motion serta reduced motion | PR panorama + uji 360 dari denah |
| Blessly | Membangun `CartCheckout` (stepper kuantitas, total sticky, uang cepat dan kembalian), `PaymentSheet` yang memisahkan tunai dan QRIS beserta state `creating`, `awaitingPayment`, `paid`, `expired`, `failed` sebagai UI, serta layar status berhasil | PR kasir + uji alur tunai |

### Fase 5 — Audit aksesibilitas dan rilis internal

| Pemilik | Tugas | Bukti kontribusi |
|---|---|---|
| Tariq | Menyelaraskan `PRODUCT.md`, `DESIGN.md`, dan `README.md` dengan hasil UI, menutup peta fitur di `PROGRESS.md`, dan menyiapkan konfigurasi `.vscode` akhir | PR dokumentasi + peta fitur tuntas |
| Farel | Mengaudit aksesibilitas lintas layar (text scale 1.3, lebar 360 dp, kontras, semantic label, tooltip ikon), menulis `docs/a11y.md`, dan menambahkan golden test widget | PR audit + golden test |
| Blessly | Menguji alur kasir pada perangkat kecil, membangun APK untuk pengujian internal, dan menambahkan catatan rilis serta panduan uji perangkat kecil di `README.md` | PR rilis internal + APK terpasang |

## Definisi selesai

Sebuah tugas dianggap selesai bila seluruh poin berikut terpenuhi:

1. Layar dapat dipreview di emulator atau perangkat Android dan tidak menimbulkan
   error analyzer.
2. Semua state terlihat, bukan hanya jalur bahagia: kosong, memuat, error, dan status
   offline. Data dibaca dari repository; data sintetis untuk presentasi tidak
   memerlukan label visual. Asalnya tetap tercatat lewat ID/metadata internal.
   Simulasi pembayaran dan status integrasi tetap disampaikan sesuai bukti.
3. Layout aman pada text scale 1.3 dan lebar 360 dp, target sentuh minimal 48 dp, dan
   status memakai kombinasi ikon, teks, serta warna.
4. Tidak ada layar yang menampilkan pembayaran berhasil atau data tersinkron seolah
   nyata, sesuai prinsip "data nyata atau status jujur".
5. `flutter analyze` dan `flutter test` lulus; hasil, cakupan perangkat, serta
   pemeriksaan yang belum dijalankan dicatat tanpa klaim integrasi palsu.
6. Pull request sudah ditinjau minimal satu anggota lain dan di-merge ke `main`.

## Pekerjaan lanjutan dan batas verifikasi

SQLite, kamera, laporan nyata, Firebase native/outbox, dan tool/draft Groq bukan
lagi pekerjaan yang dilarang. Perluasan layanan/dependensi tetap perlu persetujuan.
Pekerjaan produksi berikut belum selesai atau belum terverifikasi:

- Akses baca tanpa autentikasi diketahui HTTP 200; rules tidak diubah. Pengguna
  menolak tambahan login/PIN/Anonymous Auth. Identitas/keanggotaan toko dan isolasi
  tenant belum terjamin; perubahan autentikasi perlu persetujuan baru.
- Build/install APK cloud-first, unduh data dan unggah outbox lewat aplikasi,
  backfill produk lama, serta pemulihan perangkat baru belum terverifikasi.
  Stok lintas perangkat masih last-write-wins, bukan atomik; tidak ada snapshot
  atomik lintas halaman/koleksi, batas 10.000 dokumen/koleksi. Layanan sinkronisasi
  latar belakang memerlukan persetujuan terpisah.
- Monitor mulai dibangun atas izin pengguna. Model/template, validasi dan
  persistensi dan UI lokal tersedia; jalur cloud belum diuji live/perangkat.
- QRIS provider resmi/webhook tervalidasi, cetak fisik label/struk, snapshot
  harga modal untuk laba historis, dan perhitungan restok.
- Foto koreksi privat, dataset AI, TFLite, serta WhatsApp/Ollama `backend-agent`.

Impor Firestore `iyangunshop` / `stores/toko-utama` terverifikasi: 90 dokumen
dibuat dan terbaca ulang, 24 produk, 66 nota tunai, 394 unit, Rp3.035.800.
Rentang 10–24 November 2026 inklusif: 15 hari, 3–6 nota/hari. Data presentasi
tanpa label visual, metadata asal internal; bukan bukti penjualan aktual atau
keberhasilan unduh data lewat aplikasi.

Validasi terakhir yang dilaporkan pada 19 November: analyzer bersih, 240 test
Flutter dan 12 test Node lulus, bukan eksekusi ulang pada tugas dokumen ini.
APK debug 15 November pernah dibangun/dipasang/diluncurkan pada Samsung SM_A366B
tanpa menghapus data; APK cloud-first terbaru belum dibangun/dipasang.
Audit UI fisik, pemindaian penuh, cetak, dan live Groq tetap belum terverifikasi.

## Riwayat penyelarasan dokumen tahap UI

Temuan berikut dicatat pada tahap UI awal. Penyebutan pekerjaan mendatang di
bagian historis ini mengikuti waktu tersebut; status berjalan mengikuti bagian
integrasi dan batas verifikasi di atas.

- **Alur transaksi kurang terwakili di `PRODUCT.md`.** `DESIGN.md` memuat katalog,
  formulir, pemindai, keranjang, dan pembayaran secara rinci, sedangkan Core Experience
  `PRODUCT.md` hanya menyinggung sorot lokasi rak. `PRODUCT.md` dilengkapi pada Fase 3.
- **Model peran belum ada di `README.md`.** `PRODUCT.md` dan `DESIGN.md` membedakan
  pemilik dan kasir, termasuk batas mode edit. State peran dan tampilannya dibuat pada
  Fase 3 dan dicatat di `README.md`.
- **Layar restok dan laporan belum punya komponen.** Prinsip data `README.md` menyebut
  rencana restok, sedangkan `DESIGN.md` belum punya layarnya. Layar laporan dibuat pada
  Fase 4, sedangkan perhitungan restok menunggu backend.
- **Splash dan onboarding belum ada di `PRODUCT.md`.** `DESIGN.md` sudah merinci durasi
  dan jumlah halaman, jadi Core Experience `PRODUCT.md` ditambah bagian ringkas di
  Fase 5.
- **Rujukan berkas yang belum ada.** `docs/COLOR_PALETTE.md` dan `.vscode/**` sudah
  dibuat pada Fase 0, sedangkan `docs/ui-flow.md` dan `docs/a11y.md` menyusul pada fase
  masing-masing.
- **`TODO.md` dibatalkan.** Checklist fitur sudah tercakup oleh `PROGRESS.md` lewat
  ringkasan fase dan peta fitur, jadi tidak perlu berkas terpisah. Rujukan `TODO.md`
  sudah dibersihkan dari `AGENTS.md`, `TEAM.md`, dan `README.md`.
- **Nama repositori** `ryangunshp` berbeda dari nama produk `RyanGunshop`. Sepakati satu
  penulisan sebelum rilis internal agar nama paket, launcher, dan dokumentasi konsisten.
- **`README.md` sudah diselaraskan.** Blok struktur dan bagian backendnya diperbarui
  Tariq lewat pull request sebelum Blessly mulai bekerja, karena isi lamanya menyebut
  `lib/data/`, `lib/domain/`, `lib/di/`, dan `backend-agent/` yang belum ada. Rencana
  tahap berikutnya kini berada di satu bagian tersendiri supaya tidak terbaca sebagai
  instruksi sekarang. Kepemilikan berkas tetap pada Blessly.
- **Kepemilikan `mobile/pubspec.yaml`.** Berkas ini dipakai bertiga, jadi ditetapkan milik
  Tariq dengan perubahan lewat pull request. Tanpa penetapan ini, dua orang bisa menambah
  aset di saat yang sama dan berbenturan.
- **Komponen dasar `core/widgets`.** Sebelumnya sudah dipetakan ke Tariq tetapi tidak
  muncul di fase mana pun, sehingga berisiko tidak pernah dibangun. Sekarang menjadi
  bagian Fase 1 bersama shell.
