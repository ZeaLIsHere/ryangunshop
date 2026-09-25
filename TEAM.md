# RyanGunshop — Pembagian Tugas Tim

Dokumen ini menetapkan peran, kepemilikan berkas, dan urutan pekerjaan tiga anggota
tim agar porsi kerja seimbang dan jejak kontribusinya terlihat jelas di GitHub.

**Cakupan tahap ini adalah seluruh UI aplikasi (frontend).** Pekerjaan backend,
sinkronisasi, dan integrasi pembayaran nyata ditunda sampai UI selesai. Semua layar
memakai data contoh lokal agar dapat dipreview tanpa layanan eksternal.

Dokumen ini berbeda dari `TODO.md`: `TODO.md` adalah checklist fitur berdasarkan
FR/NFR, sedangkan `TEAM.md` adalah peta **siapa mengerjakan apa**.

Papan status pengerjaan ada di `PROGRESS.md`. Berkas itu mencatat tugas yang sudah
selesai, yang sedang jalan, dan langkah berikutnya.

## Anggota dan peran

| Anggota | Peran | Tanggung jawab utama |
|---|---|---|
| Tariq | Fondasi, Shell, dan Dashboard | Tema dan komponen dasar, kerangka aplikasi, navigasi, splash, onboarding, dashboard |
| Farel | Pengalaman Spasial dan Aksesibilitas | Denah, objek ruang, mode lihat/edit, panorama 360, identitas visual, audit aksesibilitas |
| Blessly | Katalog dan Kasir | Katalog produk, formulir produk, pemindai, keranjang, pembayaran |

## Peta kepemilikan berkas

Satu berkas hanya boleh dimiliki satu orang. Perubahan pada berkas milik orang lain
dilakukan lewat pull request, bukan commit langsung.

| Cakupan berkas | Pemilik |
|---|---|
| `mobile/lib/main.dart`, `mobile/lib/app/**` (shell, routing, navigasi) | Tariq |
| `mobile/lib/core/theme/**`, `mobile/lib/core/widgets/**` | Tariq |
| `mobile/lib/features/onboarding/**`, `mobile/lib/features/dashboard/**` | Tariq |
| `mobile/lib/features/reports/**`, `docs/COLOR_PALETTE.md`, `TODO.md` | Tariq |
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

`PROGRESS.md` dikecualikan dari aturan satu pengubah: setiap anggota hanya menyunting
baris tugasnya sendiri, dan pembaruan itu dilakukan pada pull request tugas tersebut.

## Alur kerja Git

Tujuan alur ini adalah membuat riwayat repository menunjukkan tiga kontributor dengan
volume setara, bukan satu akun yang mengerjakan semuanya.

- `main` selalu dapat dijalankan. Setiap orang bekerja di branch sendiri:
  `feat/ui-shell-<topik>` (Tariq), `feat/ui-spatial-<topik>` (Farel),
  `feat/ui-commerce-<topik>` (Blessly).
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

## Pembagian tugas per fase

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
| Tariq | Menyelaraskan `PRODUCT.md`, `DESIGN.md`, dan `README.md` dengan hasil UI, menutup checklist UI di `TODO.md`, dan menyiapkan konfigurasi `.vscode` akhir | PR dokumentasi + checklist UI tuntas |
| Farel | Mengaudit aksesibilitas lintas layar (text scale 1.3, lebar 360 dp, kontras, semantic label, tooltip ikon), menulis `docs/a11y.md`, dan menambahkan golden test widget | PR audit + golden test |
| Blessly | Menguji alur kasir pada perangkat kecil, membangun APK untuk pengujian internal, dan mendokumentasikan cara mempratinjau UI di `README.md` | PR rilis internal + APK terpasang |

## Definisi selesai

Sebuah tugas dianggap selesai bila seluruh poin berikut terpenuhi:

1. Layar dapat dipreview di emulator atau perangkat Android dan tidak menimbulkan
   error analyzer.
2. Semua state terlihat, bukan hanya jalur bahagia: kosong, memuat, error, dan status
   offline memakai state lokal atau data contoh.
3. Layout aman pada text scale 1.3 dan lebar 360 dp, target sentuh minimal 48 dp, dan
   status memakai kombinasi ikon, teks, serta warna.
4. Tidak ada layar yang menampilkan pembayaran berhasil atau data tersinkron seolah
   nyata, sesuai prinsip "data nyata atau status jujur".
5. Pull request sudah ditinjau minimal satu anggota lain dan di-merge ke `main`.

## Di luar cakupan tahap ini

Pekerjaan berikut sengaja ditunda dan tidak dihitung dalam pembagian tugas UI:

- Drift/SQLite, Firestore, outbox, serta sinkronisasi dan penanganan konflik.
- `backend-agent` (WhatsApp, Ollama, tool registry) dan webhook QRIS yang tervalidasi.
- Firebase Authentication, rules, index, Storage, dan App Check.
- Foto koreksi privat, dataset AI, dan klasifikasi TFLite nyata.
- Perhitungan rencana restok dan laporan berbasis data nyata.

Komponen yang bergantung pada pekerjaan di atas tetap dibangun sekarang, tetapi hanya
sebatas tampilan dan state UI dengan data contoh.

## Catatan penyelarasan dokumen

Temuan berikut muncul saat menyamakan `PRODUCT.md`, `DESIGN.md`, dan `README.md`, lalu
disepakati sebagai keputusan bersama. Karena tahap ini berfokus UI, hanya temuan yang
menyentuh tampilan yang ditutup sekarang.

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
- **Rujukan berkas yang belum ada.** `docs/COLOR_PALETTE.md`, `docs/ui-flow.md`,
  `docs/a11y.md`, `TODO.md`, `.vscode/**`, serta aset branding dibuat pada Fase 0 dan
  Fase 5 agar klaim dokumen terpenuhi.
- **Nama repositori** `ryangunshp` berbeda dari nama produk `RyanGunshop`. Sepakati satu
  penulisan sebelum rilis internal agar nama paket, launcher, dan dokumentasi konsisten.
- **Perubahan `README.md` menyusul.** Blok struktur di `README.md` masih menyebut
  `mobile/lib/data/`, `mobile/lib/domain/`, dan `mobile/lib/di/` yang tidak dipakai pada
  tahap UI ini. Struktur resmi sekarang ada di `AGENTS.md` (`app/`, `core/theme/`,
  `core/widgets/`, dan `features/`), dan penyelarasan `README.md` dikerjakan Blessly
  sebagai pemilik berkas pada fase berikutnya.
- **Kepemilikan `mobile/pubspec.yaml`.** Berkas ini dipakai bertiga, jadi ditetapkan milik
  Tariq dengan perubahan lewat pull request. Tanpa penetapan ini, dua orang bisa menambah
  aset di saat yang sama dan berbenturan.
- **Komponen dasar `core/widgets`.** Sebelumnya sudah dipetakan ke Tariq tetapi tidak
  muncul di fase mana pun, sehingga berisiko tidak pernah dibangun. Sekarang menjadi
  bagian Fase 1 bersama shell.
