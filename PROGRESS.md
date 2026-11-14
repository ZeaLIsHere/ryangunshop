# RyanGunshop — Status Pengerjaan

Papan status hidup proyek. `TEAM.md` berisi rencana, sedangkan berkas ini berisi
keadaan nyata, supaya anggota tim dan agen AI mereka tahu sudah sampai mana proyek
berjalan tanpa harus menebak dari riwayat commit.

## Aturan pembaruan

- Perbarui baris Anda di sini **pada pull request yang sama** dengan tugas yang
  diselesaikan. Jangan menumpuk pembaruan status sampai akhir fase.
- Satu orang hanya menyunting baris miliknya sendiri. Bila anggota yang bersangkutan
  belum sempat, pemilik berkas boleh memperbarui baris itu agar papan status tidak
  basi, dan menyebutkannya di ringkasan pull request.
- Legenda: `belum` · `jalan` · `review` · `selesai`. Pakai `review` bila kode dan
  pengujian sudah selesai tetapi verifikasi emulator atau tinjauan PR belum ada, dan
  `selesai` hanya bila seluruh poin "Definisi selesai" di `TEAM.md` terpenuhi.

## Ringkasan fase

| Fase | Tariq | Farel | Blessly |
|---|---|---|---|
| 0 — Fondasi UI dan aset | selesai | review | review |
| 1 — Kerangka aplikasi dan komponen dasar | review | review | review |
| 2 — Splash, onboarding, dan dashboard | review | review | review |
| 3 — Denah operasional dan pemindai | review | review | review |
| 4 — Pembayaran, panorama, dan laporan | review | review | review |
| 5 — Audit aksesibilitas dan rilis internal | review | review | review |

## Peta fitur

Tempat setiap fitur berada dan siapa pemiliknya. Statusnya mengikuti ringkasan fase di
atas. Bila Mini-SRS memiliki nomor FR/NFR, tambahkan kolomnya di tabel ini, bukan lewat
berkas checklist terpisah.

| Fitur | Folder | Pemilik | Status |
|---|---|---|---|
| Kerangka aplikasi, tema, komponen dasar | `mobile/lib/app/`, `mobile/lib/core/` | Tariq | review |
| Perkenalan (Onboarding 3 Fitur Utama) | `mobile/lib/features/onboarding/` | Tariq | review |
| Beranda (Dashboard POS & Aksi Cepat) | `mobile/lib/features/dashboard/` | Tariq | review |
| Pengaturan dan peran pengguna | `mobile/lib/features/settings/`, `core/session/` | Tariq | review |
| Riwayat dan laporan transaksi | `mobile/lib/features/reports/` | Tariq | review |
| Aset brand, logo & ikon 3D (01–10) | `mobile/assets/branding/`, `mobile/assets/icon/` | Farel | review |
| Denah dan objek ruang (dilepas dari UI utama) | `mobile/lib/features/floor_plan/` | Farel | diarsipkan |
| Panorama 360 (dilepas dari UI utama) | `mobile/lib/features/panorama/` | Farel | diarsipkan |
| Katalog produk & stok | `mobile/lib/features/catalog/` | Blessly | review |
| Formulir produk mobile | `mobile/lib/features/catalog/` | Blessly | review |
| Pemindai produk & barcode | `mobile/lib/features/scanner/` | Blessly | review |
| Keranjang dan pembayaran (Kasir) | `mobile/lib/features/checkout/`, `.../payment/` | Blessly | review |
| Chatbot asisten AI (IyanBoT) | `mobile/lib/features/chatbot/` | Tim | review |
| Analitik & statistik penjualan | `mobile/lib/features/statistics/` | Tim | review |

## Catatan per tugas

**Tariq — Koreksi dua permukaan Beranda menurut peran (2026-11-14), review.**

- Kasir dipulihkan dari visual `origin/main`: Hero Omzet gradien, cetak laporan,
  empat bento dengan aset asli, serta aktivitas transaksi terbaru. Tidak ada
  alat kelola pemilik. Angka dibaca dari repository dengan loading/error/retry,
  bukan nol pengganti kegagalan. Status data tetap lokal perangkat.
- `DashboardScreen` memilih `CashierDashboard` atau `OwnerDashboard` dari peran
  sesi langsung. Pengaturan tetap tanpa autentikasi/PIN; pergantian peran tidak
  menghapus katalog atau keranjang. Izin tambah/simpan ulang tetap diperiksa.
- Pemilik memakai urutan ringkasan bersih/jumlah/rata-rata, grafik harian,
  perhatian stok saat ini beserta aksi kelola, produk terlaris, dan nota periode.
  Hari ini/7 hari/30 hari memakai kalender lokal termasuk hari ini dan batas
  akhir eksklusif besok. `listForPeriod` memperluas query harian pada Drift dan
  memori, tanpa limit 50 atau dependensi baru. Grafik batang native memiliki
  tanggal, nilai rupiah, semantik, dan hari kosong bernilai nol. Nilai produk
  terlaris berlabel kotor sebelum diskon nota; tidak ada tren/laba historis.
- Design Read: operasional kasir lama dan tinjauan manajemen pemilik terpisah;
  Material 3/token violet, variasi 4, motion 3, kepadatan 6. Tidak mengubah
  katalog, ekspor, chatbot, scanner, dependensi, atau pemilihan peran.
- Validasi: `flutter analyze --no-pub` bersih; `flutter test --reporter expanded`
  205/205 lulus, termasuk batas tanggal 1/7/30, lebih dari 50 nota, jumlah grafik,
  snapshot/penjualan kotor, perubahan periode, pemulihan kasir, izin formulir,
  pergantian peran, error/retry/kosong, 360 dp/skala 1,3. APK debug berhasil
  dalam 138,5 detik dengan
  `JAVA_TOOL_OPTIONS=-Dorg.gradle.project.kotlin.incremental=false flutter build apk --debug --dart-define-from-file=../.env`.
  Peringatan KGP plugin Firebase lama tetap ada. APK tidak dipasang; visual
  emulator/perangkat Android belum diverifikasi. Tidak membuat branch/commit.

**Blessly / Tim — Pembatasan kelola produk berdasarkan peran (2026-11-14), review.**

- `UserRole.canManageProducts` membatasi tambah/edit/hapus untuk pemilik.
  Kasir tanpa FAB/CTA tambah di katalog, edit/hapus detail, CTA barcode asing,
  serta shortcut dan kontrol draft produk chatbot. Pencarian, pindai, keranjang,
  dan pencatatan penjualan tetap tersedia; katalog kosong memberi arahan pemilik
  dan tindakan muat ulang.
- Formulir termasuk rute langsung menolak kasir. Izin dibaca ulang saat simpan,
  menerima hasil formulir di katalog/scanner/detail, konfirmasi hapus, serta
  setelah lookup async scanner sebelum persistensi. Pemeriksaan prepare/save
  chatbot dipertahankan dengan getter izin yang sama.
- Pemilihan peran tetap mode demo, bukan autentikasi; catatan Pengaturan diperjelas.
  Default pemilik tidak diubah. Dashboard pemilik, generator angka barcode,
  render label/PDF, autentikasi, dependensi, branch, dan commit tidak ditambahkan.
  Perubahan belum commit yang sudah ada dipertahankan.
- Validasi: `flutter analyze` tanpa isu; `flutter test --reporter expanded`
  185/185 lulus (batas 240 detik, selesai sekitar 29 detik). Delapan test baru
  mencakup kasir tanpa kontrol tambah, katalog kosong/pencarian/keranjang, rute
  langsung, perubahan peran sebelum simpan/hasil form/hapus, dan fallback scanner;
  test chatbot diperluas untuk kontrol tersembunyi serta penolakan simpan.
  APK dan emulator/perangkat Android tidak dijalankan pada tugas ini.

**Blessly — Pemindai barcode kamera Android nyata (2026-11-14), review.**

- Persetujuan eksplisit pengguna membuka integrasi kamera nyata. `mobile_scanner`
  7.5.0 memakai CameraX/ML Kit bundled, deteksi offline tanpa unggah bingkai.
  Preview, izin/retry/panduan Pengaturan Android, torch sesuai perangkat, fallback
  manual non-Android, dan pause/resume lifecycle/rute menggantikan simulasi.
- Lookup repository sesi, barcode terlihat, hasil terkunci sampai tindakan pengguna,
  konfirmasi eksplisit/jumlah/stok segar termasuk isi keranjang, error DB berbeda
  dari tidak ditemukan. Pemilik dapat membuka formulir dengan barcode terisi,
  menyimpan produk ke repository sesi, lalu mengonfirmasi ke keranjang. Detail
  baca-saja; checkout memakai layar Kasir. Tidak memakai ScannerSample produksi.
- Validasi: `flutter analyze` bersih; `flutter test --reporter expanded` 177/177
  lulus, termasuk 10 test scanner (kamera terinjeksi, DB kosong, lookup/error/retry,
  stok/harga/jumlah/dedup, simpan produk, izin, lifecycle/rute, 360 dp/skala 1,3).
  APK debug berhasil (102,2 detik; batas 240 detik) dengan
  `JAVA_TOOL_OPTIONS=-Dorg.gradle.project.kotlin.incremental=false flutter build apk --debug --dart-define-from-file=../.env`.
- APK tidak dipasang; scan fisik/izin/torch perangkat belum diverifikasi.
  Plugin tidak menyediakan pembeda penolakan permanen maupun pembuka Pengaturan;
  panduan OS diberikan. Pergantian kamera opsional tidak ditambahkan. Peringatan
  KGP Firebase lama tetap ada; konfigurasi Gradle/Firebase dan pekerjaan lain
  dipertahankan. Tidak membuat branch/commit atau membaca `.env`.

**Tim — Tambah produk baru lewat chat (2026-11-14), review.**

- Sapaan/contoh pesan, hint input, dan shortcut `Tambah produk` memperjelas
  pembuatan produk belum terdaftar. Prompt meminta enam nilai wajib yang kurang,
  memakai jawaban lanjutan dari riwayat terstruktur, dan tidak otomatis membuat
  produk dari barang terjual yang tidak ditemukan. Validasi/izin/duplikat dan
  konfirmasi simpan yang sudah ada dipertahankan.
- Fallback tanpa API atau saat API gagal menawarkan formulir dalam obrolan,
  bukan pengalihan Katalog atau klaim penafsiran/penyimpanan pesan.
- Lima tes baru: klarifikasi lintas pesan dan riwayat tool, simpan hanya setelah
  konfirmasi, penjualan produk tak dikenal, shortcut editor/izin kasir pada
  360 dp/skala 1,3, serta fallback tanpa API dan HTTP gagal.
- Validasi: `flutter analyze` bersih; `flutter test --reporter expanded`
  173/173 lulus. APK debug berhasil (60,5 detik) dengan
  `JAVA_TOOL_OPTIONS=-Dorg.gradle.project.kotlin.incremental=false flutter build apk --debug --dart-define-from-file=../.env`
  (batas 240 detik). Peringatan KGP plugin Firebase tetap ada. APK tidak dipasang;
  Groq nyata/perangkat Android belum diuji. Tidak mengubah konfigurasi Android,
  dependensi, pencatatan penjualan langsung, laporan, ekspor, atau startup.

**Tim — Aksi chatbot lokal disetujui pengguna (2026-11-14), review.**

- Groq Chat Completions memakai empat tool allowlist: pencarian terbatas,
  ringkasan lokal segar, draft produk, dan draft penjualan. Tidak mengirim seluruh
  katalog; ID tool dan riwayat turn utuh, batas ukuran/putaran, timeout HTTP,
  `parallel_tool_calls: false`, validasi argumen dan error tanpa body rahasia.
- Produk: modal wajib dicatat, lokasi/ambang default terlihat, izin pemilik dibaca
  ulang saat konfirmasi, barcode/nama serupa ditolak tanpa overwrite. ID operasi
  tetap, konfirmasi terkunci, edit/batal/gagal/retry dan status simpan lokal terpisah
  dari cloud. Penjualan: pilihan produk ambigu eksplisit, harga/stok segar,
  total deterministik, tombol `Catat Transaksi` menyimpan penjualan tunai langsung
  lewat repository atomik tanpa masuk/bergabung ke keranjang atau navigasi checkout.
  Default terlihat `Tunai uang pas` (uang diterima = total bersih, kembalian 0);
  nominal tunai valid yang diberikan tetap dipakai. Keranjang aktif ditolak tanpa
  diubah; `clearCartDraft: false` melindungi draft disk. Harga berubah perlu
  konfirmasi ulang. ID tetap, readback nota, dan kunci konfirmasi mencegah duplikasi
  saat retry/double tap. Refresh ringkasan gagal tidak membatalkan status nota sukses.
  Status perangkat SQLite dibedakan dari fallback memori; tidak mengklaim QRIS lunas.
- Ringkasan tanpa model membaca repository produk dan nota tanggal perangkat,
  bukan cache sesi; kegagalan tidak dianggap kosong. Profil: Belum diatur,
  tanpa klaim laba. Formulir lokal dan Kasir tersedia ketika AI tidak tersambung.
- Validasi akhir pencatatan langsung: `flutter analyze` bersih;
  `flutter test` 168/168 lulus.
  Test chatbot mencakup HTTP mock/ID/riwayat, tool
  tidak dikenal/JSON rusak/parallel/loop, izin berubah, nilai wajib, duplikat,
  retry simpan/double tap, ambiguitas/jumlah wajib/stok/total/diskon, harga berubah,
  rollback SQLite, hasil commit/readback hilang, refresh ringkasan gagal sesudah
  commit, keranjang aktif tetap utuh, penolakan QRIS, serta kartu pencatatan
  tanpa input tunai ulang pada 360 dp/skala teks 1,3.
- APK debug berhasil dengan `JAVA_TOOL_OPTIONS=-Dorg.gradle.project.kotlin.incremental=false`
  dan `--dart-define-from-file=../.env`; `.env` tidak dibaca agen. Peringatan KGP
  plugin Firebase lama tetap ada; konfigurasi Android tidak diubah.
- Batas produksi: kunci Groq dalam APK dapat diekstrak; perlu pemindahan ke layanan
  tepercaya sebelum distribusi produksi, tidak menambah server pada tugas ini.
  Data hasil pencarian/agregat yang diminta dikirim ke Groq. Belum diuji dengan
  Groq nyata/perangkat Android. Pencatatan tunai adalah konfirmasi pengguna atas
  barang terjual, bukan verifikasi gateway. Draft/ID retry hanya hidup dalam sesi
  obrolan; belum ada pemulihan draft chat setelah aplikasi ditutup. Tidak mengubah nota historis,
  menambahkan layanan cloud, dependensi, branch, atau commit.


**Tariq — Ekspor Excel laporan harian (2026-11-14), review.**

- CSV diganti workbook `.xlsx` lokal: Ringkasan (kotor, diskon, bersih, jumlah,
  rata-rata, pembayaran, tanggal, waktu pembuatan, cakupan perangkat), Transaksi
  (satu baris per nota), dan Barang Terjual (semua produk, kotor sebelum diskon nota).
  Sel nominal/jumlah berupa angka, format rupiah, header tebal, lebar kolom praktis;
  teks tidak dipercaya tetap sel teks, bukan formula. PDF tidak diubah.
- Dependensi langsung `excel_plus 2.29.3`: `excel 4.0.6` tidak kompatibel dengan
  `xml ^7.0.1` milik PDF; tanpa override, downgrade PDF, atau OOXML buatan sendiri.
  Nama berkas mengikuti tanggal terpilih; MIME `.xlsx` dan berbagi native Android.
- Verifikasi: `flutter analyze` bersih; `flutter test` 149/149 lulus, termasuk decode
  workbook nyata, 250 nota/700 produk tanpa pemotongan, Unicode/teks bukan formula,
  angka/rata-rata pecahan/pembayaran, kosong, PDF multipage, dan widget gagal/retry.
  APK debug berhasil dibangun dengan Kotlin incremental dinonaktifkan:
  `mobile/build/app/outputs/flutter-apk/app-debug.apk`. Peringatan plugin Firebase
  terkait KGP dan unchecked operations tetap ada; konfigurasi Android tidak diubah.
- Belum: uji ekspor/tujuan berbagi pada perangkat Android dan membuka workbook di
  Excel/LibreOffice; tinjauan PR. Status tetap `review`.

Catatan umum: Fase 0–4 Tariq sudah di-merge ke `main`, dan aplikasi sudah dipasang serta
dijalankan pada perangkat Android SM A366B. Sisa poin definisi selesai adalah tinjauan
silang anggota lain dan verifikasi text scale 1.3 yang masuk audit Fase 5. Karena itu
statusnya `review`, bukan `selesai`.

**Pembaruan integrasi (2026-10-02) — Farel dan Blessly.**

- Fitur Farel dan Blessly yang sebelumnya masih di branch/berkas kerja sudah disatukan ke
  `main` dalam satu lintasan integrasi: `StoreFloorPlan` (mode lihat dan edit, `SyncPill`),
  viewer panorama 360 per zona, `ProductForm`, layar detail produk, pencarian dan filter
  katalog, `ProductScanner`, keranjang `CartCheckout`, `PaymentSheet` tunai/QRIS, dan
  `PaymentSuccessScreen`.
- Mode edit denah dilengkapi sesuai Fase 2: selain drag, putar, ganti nama, dan hapus,
  kini tersedia kontrol ukuran (perbesar/perkecil) dan duplikat objek di
  `mobile/lib/features/floor_plan/view_model/floor_plan_view_model.dart` dan
  `.../view/store_floor_plan.dart`.
- Kerangka aplikasi disambungkan: tab Kasir memakai `CartCheckoutScreen`, aksi utama
  dashboard dan tombol Scan membuka `ProductScannerScreen`, dan "Lihat di Denah" pada hasil
  pemindaian membuka denah dengan rak yang sesuai tersorot.
- Verifikasi: `flutter analyze` bersih dan `flutter test` 55/55 lulus pada Flutter 3.47.4 /
  Dart 3.13.3, termasuk state kosong, memuat, error, dan offline, target sentuh, serta
  lebar 360 dp pada skala teks 1,3. Belum ada verifikasi emulator atau perangkat Android
  dan belum ada tinjauan PR, jadi status tetap `review`.

**Pembaruan Redesain Beranda, Aset 3D, dan Alur Kasir (2026-11-07)**

- **Redesain Beranda (Home POS Dashboard):**
  - Halaman utama resmi dinamai **"Beranda"** (`ShellDestination.floorPlan` / `home`).
  - Kartu Hero Omzet diperbarui: omzet harian dinamis dari sesi lokal, indikator nota dan rata-rata penjualan, tombol utama "Mulai pindai" responsif tanpa overflow di layar 360 dp / text scale 1.3, badge shift dinonaktifkan atas arahan pengguna.
  - Modul Bento Aksi Cepat 4-up murni operasional kasir: `Pindai Barcode`, `Buka Kasir`, `Stok`, dan `Riwayat Nota`.
  - Kartu "Aktivitas Transaksi Terbaru" menampilkan daftar transaksi terkini lengkap dengan jam transaksi, nominal rupiah, dan wadah placeholder gambar produk siap pakai untuk fitur penambahan foto mendatang.
  - Tautan "Semua Nota" disederhanakan menjadi "Semua".

- **Pelepasan Fitur Denah dari Antarmuka Utama:**
  - Fitur kanvas denah 2D dan panorama 360 dilepas dari antarmuka utama (AppBar, Beranda, pemindai, formulir produk, dan rute fallback) untuk memprioritaskan efisiensi kasir dan pencatatan transaksi cepat.
  - Kode pustaka `features/floor_plan/` dan `features/panorama/` tetap dipertahankan terisolasi dengan pengujian unit utuh.

- **Pemasangan Aset Ikon 3D Lengkap (`assets/icon/` & `assets/branding/`):**
  - Seluruh ikon fitur kini memakai aset 3D claymorphic violet seragam:
    `01_katalog_produk.png`, `02_keranjang.png`, `03_riwayat_transaksi.png`, `04_pengaturan.png`,
    `05_statistik.png`, `06_chatbot.png`, `07_denah_warung.png`, `08_pindai_barcode.png`,
    `09_stok_produk.png`, `10_printer_bluetooth.png`, dan `beranda.png`.
  - Logo 3D utama `ryangunshop_logo.png` terpasang di AppBar dan otomatis dibuatkan seluruh varian launcher icon Android & splash screen.

- **Penyempurnaan Alur Kasir & Penyimpanan Transaksi:**
  - `CartCheckoutScreen`: Hero order card violet, 3 pod kasir cepat, item belanja dengan penanda SKU, dan rincian biaya.
  - `PaymentSheet`: Pilihan uang pas & pecahan cepat, perhitungan kembalian mint green instan.
  - `AppSession`: Metode `recordTransaction()` otomatis mencatat nota transaksi baru, mengupdate omzet hari ini dan rata-rata, menambah riwayat nota, serta mengosongkan keranjang belanja.
  - `PaymentSuccessScreen`: Struk ringkasan simulasi dilengkapi tombol `Cetak Struk (Bluetooth)`.

- **Pembaruan Splash & Onboarding 3 Fitur Utama:**
  - 3 Halaman perkenalan persuasif dan santai:
    1. *Kasir Sat-Set, Anti Ribet* (`02_keranjang.png`)
    2. *Bayar Bebas, Tunai Maupun QRIS* (`08_pindai_barcode.png`)
    3. *Pantau Cuan & Stok Real-Time* (`05_statistik.png`)
  - Tag pill dihapus untuk tampilan kartu ilustrasi 3D yang bersih dan elegan.

- **Pemasangan Tipografi Plus Jakarta Sans Offline:**
  - Font Plus Jakarta Sans resmi dibundel langsung ke dalam paket lokal offline (`assets/fonts/PlusJakartaSans-Regular.ttf`, `SemiBold.ttf`, `Bold.ttf`).
  - Font terdaftar di `mobile/pubspec.yaml` dan dipasang global di `AppTheme.light()` serta `AppTypography.total`.
  - Digit angka dan nominal kasir menggunakan `tabularFigures` agar sejajar presisi tanpa geser.

- **Verifikasi Komprehensif:**
  - `flutter analyze`: 0 issues / bersih.
  - `flutter test`: 90/90 tests passed (termasuk pengujian alur lengkap pengguna di `complete_user_flow_test.dart` dan audit aksesibilitas 360 dp / text scale 1.3).

### Fase 0 — Fondasi UI dan aset

**Tariq — selesai (2026-09-25)**

- Lingkup: proyek Flutter Android (minSdk 26), struktur `lib/`, token tema,
  `docs/COLOR_PALETTE.md`, konfigurasi pratinjau Android di `.vscode/`, `AGENTS.md`,
  dan `TEAM.md`.
- Berkas penting: `mobile/lib/core/theme/app_theme.dart`,
  `mobile/lib/core/theme/app_colors.dart`, `docs/COLOR_PALETTE.md`.
- Verifikasi: `flutter analyze` bersih, `flutter test` 4/4 lulus.
- Belum: tampilan belum dijalankan di emulator atau perangkat Android.

**Farel — review (2026-10-02).** Skema koordinat relatif 2D, `FixtureTile`, dan
konstanta template area warung sudah ada. Aset brand ditambahkan:

- `mobile/assets/branding/ryangunshop_logo.png` sebagai logo produksi, dipakai
  `RyanAppLogo` lewat `RyanAppLogo.defaultAssetPath`.
- `mobile/tool/generate_brand_assets.dart` membuat ulang launcher icon dan gambar
  native splash dari PNG sumber tanpa mengubah proporsi, memakai zlib `dart:io`
  tanpa menambah dependensi. Logo bawaan dibuat bila sumber tidak dioper.
- Verifikasi: `flutter analyze` bersih dan uji `test/tool/brand_assets_test.dart`
  (round-trip PNG, logo bawaan, dan generasi aset) lulus. Belum dijalankan di
  perangkat Android untuk melihat launcher icon hasilnya.

**Blessly — review (2026-09-27)**

- Lingkup Fase 0: model UI katalog, snapshot keranjang, state pembayaran dan data
  contoh masing-masing fitur; `ProductCatalog` statis dengan harga rupiah, lokasi,
  status stok, dan `SampleBadge`; dokumentasi `docs/ui-flow.md`.
- Skenario daftar, memuat, kosong, gagal, dan offline dapat dicoba lewat pemilih
  skenario. Tombol pemulihan mengembalikan daftar contoh; reduced motion memakai
  indikator memuat statis.
- Branch `feat/ui-commerce-ui-catalog` sudah di-push dan di-merge ke `main` lewat PR #4.
  Commit-nya memakai identitas Git Blessly.
- Pratinjau mandiri: `mobile/lib/features/catalog/sample/catalog_preview.dart`,
  dibuka lewat CodeLens Debug ekstensi Flutter di VS Code pada Android. Tab Produk
  di app shell belum disambungkan karena berkasnya milik Tariq.
- Verifikasi proyek: `flutter analyze` dan `flutter test` sudah dicoba, keduanya
  berhenti pada resolusi dependensi karena Dart lokal 3.9.2 tidak memenuhi
  `sdk: ^3.13.3`. `mobile/pubspec.yaml` tidak diubah.
- Pemeriksaan tambahan: salinan sementara di luar repository memakai batas SDK
  `^3.9.2` dengan Flutter 3.35.7/Dart 3.9.2; `flutter analyze` bersih dan
  `flutter test` 43/43 lulus (10 test baru). Cakupan meliputi state, pemulihan,
  lebar 360 dp, skala teks 1,3, target sentuh, reduced motion, serta model kasir.
  Hasil salinan ini belum menggantikan verifikasi pada SDK yang diminta proyek.
- Sudah dilanjutkan Tariq: `ProductCatalog` disambungkan ke tab Katalog pada branch
  `feat/ui-shell-integrasi-katalog`, beserta test integrasinya.
- Belum: verifikasi pada SDK sesuai proyek dan pratinjau pada perangkat Android.
  Pencarian, filter, dan formulir kini dicatat pada Fase 1–2 di bawah.

### Fase 1 — Kerangka aplikasi dan komponen dasar

**Tariq — review (2026-09-25)**

- Lingkup: app shell, routing, navigasi bawah empat tab, dan komponen dasar di
  `core/widgets` (`PrimaryAction`, `AppCard`, `AppTextField`, `AppBottomSheet`,
  `AppDialog`, `BrandSpinner`, `RyanAppLogo`).
- Berkas penting: `mobile/lib/app/shell/app_shell.dart`,
  `mobile/lib/app/routing/app_router.dart`,
  `mobile/lib/core/widgets/widgets.dart`.
- Verifikasi: `flutter analyze` bersih, `flutter test` 15/15 lulus.
- Belum: tampilan belum dijalankan di emulator Android dan PR belum ditinjau.
- Catatan: `RyanAppLogo` kini memuat aset brand dari
  `RyanAppLogo.defaultAssetPath` pada splash dan app bar, dengan penanda sementara
  sebagai cadangan bila aset gagal dimuat.

**Farel — review (2026-10-02)**

- Lingkup: `StoreFloorPlan` mode lihat (zoom/pan, interaktif) dan `ModeSwitch` (opsi 360° nonaktif saat belum tersedia panorama).
- Berkas penting: `mobile/lib/features/floor_plan/view/store_floor_plan.dart`, `mobile/lib/features/floor_plan/view/mode_switch.dart`.
- Verifikasi: (segera diuji dengan analyzer).
- Belum: Tinjauan PR.

**Blessly — review (2026-11-06).** Pencarian, filter, dan urutan katalog sudah
tersedia; kerangka `ProductForm` sudah terhubung ke alur tambah/edit produk. Widget
test katalog dan validasi formulir berjalan pada salinan pratinjau sementara.
Belum: verifikasi dengan SDK proyek dan tinjauan PR.

### Fase 2 — Splash, onboarding, dan dashboard

**Tariq — review (2026-09-25)**

- Lingkup: splash dengan signature motion 1,45 detik dan crossfade 280 ms,
  `OnboardingCarousel` tiga halaman yang dapat dilewati, serta dashboard bento dengan
  satu aksi utama dan tiga pintasan.
- Berkas penting: `mobile/lib/app/splash/splash_screen.dart`,
  `mobile/lib/features/onboarding/view/onboarding_screen.dart`,
  `mobile/lib/features/dashboard/view/dashboard_screen.dart`.
- Verifikasi: `flutter analyze` bersih, `flutter test` 23/23 lulus, termasuk pengujian
  pada lebar layar 360 dp.
- Belum: tampilan belum dijalankan di emulator Android dan PR belum ditinjau.
- Catatan: penanda "sudah melihat perkenalan" masih ada di memori
  (`AppStartupState`), jadi perkenalan muncul sekali per sesi; penyimpanan tetap
  menyusul bersama lapisan data. Tab Denah kini menampilkan dashboard, dan kanvas denah
  Farel disambungkan di sana pada Fase 3.

**Farel — review (2026-10-02)**

- Lingkup: Mode edit denah interaktif (drag memindahkan objek, tombol kontrol rotasi,
  perbesar/perkecil ukuran, duplikasi objek, penamaan, dan hapus objek), pencegahan geser
  tak sengaja pada mode lihat, serta indikator status sinkronisasi `SyncPill` (offline,
  antre sinkronisasi, dan tersinkron).
- Berkas penting: `mobile/lib/features/floor_plan/view_model/floor_plan_view_model.dart`,
  `mobile/lib/features/floor_plan/view/store_floor_plan.dart`,
  `mobile/lib/features/floor_plan/view/sync_pill.dart`.
- Verifikasi: `flutter test test/features/floor_plan_test.dart` lulus (kontrol ukuran,
  duplikasi, dan batasan kanvas).
- Belum: Verifikasi sentuh pada perangkat fisik Android.

**Blessly — review (2026-11-06).** Layar detail dan formulir produk sudah ada.
Formulir kini punya bagian pratinjau foto contoh, validasi angka dan barcode ganda,
serta susunan input satu kolom untuk layar kecil. Pratinjau foto belum memilih atau
menyimpan berkas gambar. Pada salinan sementara dengan Dart 3.9.2,
`flutter analyze` bersih dan `flutter test` 71/71 lulus; pratinjau Chrome dapat
dijalankan. Pada proyek utama, kedua perintah belum dapat melewati resolusi
dependensi karena SDK lokal 3.9.2 tidak memenuhi syarat `^3.13.2`.
Belum: verifikasi pada SDK proyek, perangkat Android, dan tinjauan PR.

### Fase 3 — Denah operasional dan pemindai

**Tariq — review (2026-09-25), kecuali penyambungan ke kasir**

- Lingkup yang selesai: keadaan sesi peran pengguna di `core/session/`, halaman
  pengaturan, dan status ketersediaan mode edit denah. Aksi "Mulai pindai" sudah
  ditempatkan di dashboard pada Fase 2.
- Berkas penting: `mobile/lib/core/session/app_session.dart`,
  `mobile/lib/features/settings/view/settings_screen.dart`.
- Verifikasi: `flutter analyze` bersih, `flutter test` 28/28 lulus.
- Belum: tampilan belum dijalankan di emulator Android dan PR belum ditinjau.
- Ditunda sesuai urutan kerja: "menyambungkan navigasi ke kasir" menunggu pemindai
  Blessly, karena rute pemindai didaftarkan bersamanya.

**Farel — review (2026-10-02)**

- Lingkup: `FixtureProductSheet` menampilkan bottom sheet daftar produk per fixture yang
  dapat dicari dan menampilkan stok contoh, serta penyorotan rak (*highlight*) pada kanvas
  denah saat pengguna menekan "Lihat di Denah" dari hasil pemindai.
- Berkas penting: `mobile/lib/features/floor_plan/view/fixture_product_sheet.dart`,
  `mobile/lib/features/floor_plan/view/floor_plan_screen.dart`.
- Verifikasi: `flutter test test/features/floor_plan_test.dart` lulus (uji pembukaan sheet
  saat fixture ditekan).
- Belum: Verifikasi pada perangkat fisik Android.

**Blessly — review (2026-11-06).** `ProductScanner` kini memakai simulasi yang
dimulai lewat tombol, dengan state siap, memuat, hasil, kosong, izin ditolak,
gagal, offline, dan produk masuk keranjang. Pencarian manual tidak memilih
produk lain ketika kata kunci tidak cocok; hasil harus dikonfirmasi sebelum
masuk keranjang. Lampu dan keyakinan hasil diberi label simulasi.
- Berkas penting: `mobile/lib/features/scanner/view/product_scanner_screen.dart`,
  `.../view/manual_product_search_screen.dart`, dan
  `.../view_model/scanner_view_model.dart`.
- Verifikasi salinan sementara dengan Dart 3.9.2: `flutter analyze` bersih,
  `flutter test` 75/75 lulus, termasuk lebar 360 dp, skala teks 1,3, dan target
  sentuh. Pada proyek utama, kedua perintah masih tertahan karena SDK lokal
  3.9.2 tidak memenuhi syarat `^3.13.2`.
- Belum: verifikasi pada SDK proyek, perangkat Android, tinjauan PR, serta
  kamera dan deteksi nyata yang memang di luar cakupan UI tahap ini.

### Fase 4 — Pembayaran, panorama, dan laporan

**Tariq — review (2026-11-14)**

- Lingkup disetujui pengguna: laporan harian SQLite lokal, pemilih tanggal awal hari
  ini, seluruh nota pada rentang waktu lokal `[tengah malam, tengah malam berikutnya)`
  tanpa batas 50 nota. Ringkasan kotor/diskon/bersih, jumlah dan rata-rata nota,
  rincian metode pembayaran sesuai nilai tersimpan, 5 produk terlaris berdasarkan
  kuantitas dengan aksi lihat semua, dan detail nota dari snapshot barang tersimpan.
- Cakupan perangkat dan waktu lokal dijelaskan tanpa WIB tetap; dapat dibuka offline.
  State memuat, gagal dengan coba lagi, kosong dengan pilih tanggal/beranda tersedia.
- Berkas penting: `mobile/lib/features/reports/`,
  `mobile/lib/core/data/transaction_repository.dart`,
  `mobile/lib/core/data/in_memory_transaction_repository.dart`,
  `mobile/test/features/reports_test.dart`.
- Verifikasi: `flutter analyze --no-pub` bersih;
  `flutter test --no-pub test/features/reports_test.dart` 6/6 lulus;
  `flutter test --no-pub` 144/144 lulus. Meliputi batas hari, 62 nota, aritmetika,
  metode pembayaran, snapshot, permintaan usang, retry, pemilih tanggal, layout
  360 dp/skala teks 1,3, detail nota dan target tombol minimal 48 dp.
- Belum: verifikasi emulator/perangkat Android dan tinjauan PR. Tidak menambahkan
  laba, retur, printer native, sinkronisasi cloud, atau dependensi.
- Catatan: akses tetap melalui rute `/riwayat` yang sudah ada; perubahan app shell,
  startup test, Gradle, dan pengaturan milik pengguna dipertahankan.
- Ekspor disetujui pengguna (2026-11-14): PDF A4 multipage berisi cakupan perangkat,
  tanggal/jam lokal, kotor/diskon/bersih, jumlah/rata-rata nota, metode pembayaran,
  dan seluruh ringkasan produk sebelum diskon nota. Font memakai aset lokal.
  CSV UTF-8 BOM memakai satu baris per nota, angka rupiah utuh, seluruh snapshot
  barang dalam kolom JSON, escaping CSV dan perlindungan formula spreadsheet.
  Nama berkas `laporan-harian-YYYY-MM-DD.pdf` / `.csv` mengikuti tanggal terpilih.
- Tombol `Bagikan PDF` / `Bagikan CSV` membuka tujuan berbagi native Android lewat
  `share_plus`; tidak mengklaim cache sebagai berkas tersimpan. Penyimpanan permanen
  bergantung tujuan yang dipilih pengguna. PDF dibuat dengan `pdf`; tanpa encoder
  buatan sendiri, dependensi CSV, atau layanan jaringan ekspor.
- Ekspor memblokir aksi tanggal/muat ulang/ekspor lain, menangani gagal dan retry,
  memakai snapshot laporan; hari kosong menghasilkan PDF kosong berlabel dan CSV
  header saja. Data contoh tanpa snapshot lokal tidak diekspor.
- Verifikasi ekspor: `flutter analyze --no-pub` bersih; `flutter test --no-pub`
  148/148 lulus. Uji meliputi CSV 250 nota, Unicode, koma/kutip/CRLF, formula,
  aritmetika, tanggal/nama berkas, PDF A4 700 produk/71 halaman, laporan kosong,
  berbagi terinjeksi tanpa platform, gagal/retry, serta 360 dp/skala teks 1,3.
- Build `flutter build apk --debug --no-pub` gagal pada cache inkremental Kotlin
  lintas drive (`firebase_core` dan `share_plus`). Percobaan
  `./gradlew.bat assembleDebug -Pkotlin.incremental=false --no-daemon` dari
  `mobile/android` berhasil tanpa mengubah Gradle. Belum menguji lembar berbagi,
  pilihan tujuan simpan, dan tampilan PDF secara manual pada perangkat Android.

**Farel — review (2026-10-02)**

- Lingkup: Viewer panorama 360 per zona warung (`PanoramaViewerScreen`) menggunakan foto
  equirectangular contoh, navigasi swipe interaktif, chip pemilih zona, serta integrasi
  tombol alih mode di kanvas denah.
- Berkas penting: `mobile/lib/features/panorama/view/panorama_viewer_screen.dart`,
  `mobile/lib/features/panorama/model/panorama_zone.dart`.
- Verifikasi: `flutter test test/features/panorama_test.dart` lulus (uji rendering kanvas
  360 dan chip pemilih zona).
- Belum: Pengujian pada perangkat fisik Android.

**Blessly — review (2026-11-06).** `CartCheckout` kini mencakup state kosong,
memuat, gagal, dan offline, serta perubahan kuantitas dan total keranjang. `PaymentSheet`
mempratinjau pembayaran tunai dengan kembalian dan seluruh state QRIS; QRIS contoh tidak
menyelesaikan transaksi atau mengosongkan keranjang. Ringkasan tunai menandai transaksi
dan stok sebagai belum tercatat.

- Verifikasi: `flutter analyze` bersih dan `flutter test` 79/79 lulus pada salinan
  sementara dengan Dart 3.9.2. Batas SDK hanya disesuaikan pada salinan; `pubspec.yaml`
  repository tidak diubah.
- Belum: verifikasi dengan SDK proyek, perangkat Android, dan tinjauan PR.

### Fase 5 — Audit aksesibilitas dan rilis internal

**Tariq — review (2026-11-06)**

- Lingkup: Menyelaraskan dokumen `PRODUCT.md` dengan pengalaman UI operasional aktual
  (splash motion 1,45 detik, onboarding carousel 3 langkah dengan reduced motion,
  pengaturan peran, dan laporan transaksi), menutup peta fitur, serta memastikan
  kelengkapan berkas konfigurasi `.vscode` untuk pratinjau Android.
- Berkas penting: `PRODUCT.md`, `PROGRESS.md`, `README.md`.
- Verifikasi: Dokumen telah diselaraskan; `flutter analyze` bersih tanpa peringatan.
- Belum: Tinjauan PR.

**Farel — review (2026-11-06)**

- Lingkup: Mengaudit aksesibilitas menyeluruh pada lebar sempit 360 dp dan skala teks
  1.3, target sentuh minimal 48×48 dp, kontras warna WCAG AA, penanda status non-warna,
  semantic label TalkBack untuk denah dan kontrol, penanganan reduced motion, menyusun
  dokumen acuan `docs/a11y.md`, serta menambahkan pengujian widget audit aksesibilitas.
- Berkas penting: `docs/a11y.md`, `mobile/test/features/accessibility_audit_test.dart`.
- Verifikasi: `flutter test test/features/accessibility_audit_test.dart` 5/5 lulus,
  bebas error analyzer.
- Belum: Pengujian manual TalkBack pada perangkat Android fisik.

**Blessly — review (2026-11-06)**

- Lingkup: Menguji alur belanja dan kasir pada viewport 360 dp, memperbarui dokumen
  alur UI pada `docs/ui-flow.md`, menambahkan panduan uji perangkat kecil serta
  catatan rilis internal (v0.5.0-ui) pada `README.md`.
- Berkas penting: `docs/ui-flow.md`, `README.md`.
- Verifikasi: Seluruh pengujian alur kasir lulus tanpa overflow pada skala teks 1.3.
- Belum: Tinjauan PR dan pembuatan paket APK internal.

## Rencana Pengembangan Menuju Produksi (Production-Ready Roadmap)

Rencana kerja teknis terstruktur untuk membawa prototipe UI RyanGunshop menjadi aplikasi kasir warung yang siap dirilis dan digunakan di lapangan:

### Fase 1: Persistensi Data Lokal (Offline-First Database) — *Prioritas Tertinggi*
- **Status 2026-11-12 — berjalan di `feat/backend-persistence`:** Drift sudah memiliki
  tabel produk, nota, item nota, draft keranjang, repository lokal, migrasi versi 1–5,
  dan checkout tunai atomik dengan validasi stok, harga, total, diskon, serta
  kembalian. Produk tanpa barcode serta metadata katalog tersimpan di SQLite.
  Pada Android, katalog, draft keranjang (barang, diskon, catatan), pembayaran tunai,
  dan ringkasan omzet membaca data lokal; katalog awalnya kosong sampai pengguna
  menambah produk. Checkout menghapus draft di transaksi SQLite yang sama dengan nota.
  Preview web tetap memakai data contoh. QRIS belum mencatat pembayaran.
- **Verifikasi otomatis:** Migrasi dari skema v1–v3, pembukaan ulang file database,
  kategori katalog lokal, pencarian manual pemindai, dan checkout tunai diuji.
  Alur tambah/edit produk dari formulir sampai SQLite serta pemuatan ulang nota,
  omzet, dan stok pada sesi baru juga lulus uji. Formulir lokal menandai foto sebagai
  contoh dan tetap dapat mengedit kategori/satuan produk lama.
  Migrasi v4–v5, pemulihan draft setelah file SQLite dibuka ulang, penulisan perubahan
  cepat, dan draft yang tetap ada saat checkout gagal juga diuji.
- **Berikutnya:** Verifikasi alur tersebut di perangkat Android. Laporan masih memakai
  contoh; kamera barcode dan printer Bluetooth tetap ditunda.
- **Tujuan:** Data produk, stok, dan riwayat nota penjualan tersimpan permanen di HP tanpa risiko hilang saat aplikasi ditutup atau HP mati.
- **Implementasi:**
  - Pasang SQLite via Drift / Isar untuk Flutter.
  - Tabel `products`: id, barcode, nama, harga modal, harga jual, stok, kategori, threshold stok menipis, path foto lokal.
  - Tabel `transactions`: id (format TRX-XXXX), waktu timestamp, total belanja, metode pembayaran, uang diterima, uang kembalian.
  - Tabel `transaction_items`: id transaksi, id produk, kuantitas, harga satuan, subtotal.
  - Mekanisme transaksi ACID (atomic): pengurangan stok dan penulisan nota penjualan dieksekusi bersamaan.
  - Penggantian state `AppSession` dan `sample/` dengan repository lokal berbasis database ini.

### Fase 2: Integrasi Perangkat Keras Kasir (Hardware POS)
- **Tujuan:** Memfungsikan kamera HP sebagai pemindai barcode fisik dan printer struk Bluetooth kasir.
- **Implementasi:**
  - **Scanner Barcode Nyata:** Pasang `mobile_scanner` (Google ML Kit) untuk deteksi barcode kemasan produk fisik (EAN-13, UPC, QR) secara instan (< 200 ms).
  - **Printer Thermal Bluetooth:** Pasang pustaka ESC/POS printer (`blue_thermal_printer` / `esc_pos_utils_plus`) untuk mendeteksi printer thermal 58mm/80mm di meja kasir dan mencetak nota fisik saat transaksi selesai.

### Fase 3: Pengambilan & Kompresi Foto Produk Lokal
- **Tujuan:** Mengisi wadah placeholder gambar produk di Beranda dan Katalog dengan foto barang nyata.
- **Implementasi:**
  - Integrasi kamera & galeri menggunakan `image_picker`.
  - Kompresi gambar lokal (resolusi maks 512×512 piksel, WebP/JPEG kualitas 75%) agar hemat memori pada perangkat kelas bawah.
  - Penyimpanan file foto di direktori privat aplikasi (`path_provider`).

### Fase 4: Proteksi Hak Akses & Kunci PIN Keamanan
- **Tujuan:** Mencegah kasir atau pihak lain melihat laba kotor toko atau mengubah harga barang.
- **Implementasi:**
  - Kunci PIN 4–6 digit untuk akses akun Pemilik, pengaturan harga modal, dan ekspor laporan keuangan.
  - Pembatasan mode Kasir: hanya memindai, memasukkan keranjang, dan menerima pembayaran.

### Fase 5: Sinkronisasi Cloud Berkala & Pembayaran QRIS Nyata
- **Tujuan:** Cadangan data cloud dan integrasi pembayaran QRIS resmi Bank Indonesia.
- **Implementasi:**
  - Sinkronisasi latar belakang menggunakan *outbox pattern* ke Firebase Firestore / Supabase saat perangkat terhubung internet.
  - Integrasi payment gateway (Xendit / Midtrans / DOKU) untuk menerbitkan QRIS dinamis berlisensi dan validasi webhook otomatis.

**Persiapan migrasi Firestore (2026-11-13) — belum tersambung ke alur kasir.**

- Lapisan cloud ditambahkan tanpa mengubah perilaku bawaan:
  `core/data/sync/firestore_schema.dart` (kontrak dokumen produk dan nota,
  nominal bulat rupiah, *soft delete*), `outbox.dart`, `sync_queue.dart`
  (antrean memori dan SQLite), `sync_engine.dart`, `drift_sync_queue.dart`, dan
  `firestore_sync_target.dart`.
- Tabel `sync_outbox_entries` ditambahkan pada skema SQLite v6. Bila
  `AppSession` menerima `SyncQueue`, penyimpanan produk dan checkout tunai
  menulis entri antrean di transaksi SQLite yang sama; kegagalan penulisan
  antrean membatalkan checkout sehingga nota tidak pernah tercatat tanpa
  rencana pengiriman.
- `core/config/firebase_bootstrap.dart` menyalakan Firebase hanya bila
  `--dart-define=FIREBASE_ENABLED=true`, dengan opsi dari `dart-define` atau
  `google-services.json`. Tanpa sakelar itu aplikasi tetap 100% lokal.
- Aturan keamanan `firebase/firestore.rules`, indeks
  `firebase/firestore.indexes.json`, dan `firebase.json` disiapkan untuk
  `firebase deploy --only firestore`.
- Panduan lengkap: `docs/firebase-setup.md`; skema dan rencana bertahap:
  `docs/firestore-schema.md`.
- Verifikasi: `flutter analyze` bersih dan `flutter test` 141/141 lulus,
  termasuk 15 pengujian baru untuk pemetaan dokumen, antrean, mesin
  sinkronisasi, dan pembatalan checkout saat antrean gagal.
- Belum: layanan autentikasi dan layar masuk, penjadwalan `flush()`, pemulihan
  data di perangkat baru, serta verifikasi pada proyek Firebase nyata.

### Fase 6: Optimasi Perangkat Kelas Bawah & Rilis Paket APK
- **Tujuan:** Aplikasi berjalan ringan dan stabil di ponsel Android dengan RAM 2–3 GB (Android 8.0 - 14).
- **Implementasi:**
  - Build rilis APK terpisah per arsitektur CPU (`flutter build apk --split-per-abi`) dengan ukuran berkas hemat (~15–20 MB).
  - Profiling performa: memori RAM stabil di bawah 150 MB dan animasi 60 FPS.

## Catatan untuk agen AI

- Baca `AGENTS.md` lebih dahulu, lalu `TEAM.md`, lalu berkas ini untuk mengetahui posisi
  proyek sebelum menulis kode.
- Token tema sudah tersedia sejak Fase 0. Pakai `Theme.of(context)`, `AppColors`,
  `AppSpacing`, dan `AppRadius`; jangan menulis warna, ukuran teks, atau jarak langsung.
- Setelah Fase 1 di-merge, komponen dasar dapat diimpor dari
  `package:ryangunshop/core/widgets/widgets.dart`. Pakai komponen itu, jangan membuat
  versi tandingan di dalam folder fitur.
- `mobile/lib/app/**` dan `mobile/lib/core/**` milik Tariq. Jangan menyuntingnya tanpa
  pull request.
- Halaman utama aplikasi adalah **"Beranda"** (`ShellDestination.floorPlan` / `home`). Fitur denah telah dilepas dari antarmuka operasional harian.
- Aset ikon 3D resmi tersedia lengkap di `mobile/assets/icon/` (`01` s/d `10` dan `beranda.png`). Selalu gunakan aset ini.
- Nominal rupiah lewat `formatRupiah` di `core/format/rupiah.dart`, dan data contoh
  ditandai `SampleBadge` dari `core/widgets/widgets.dart`.
- Alur pembuka aplikasi: splash menuju perkenalan (sekali per sesi), lalu kerangka utama.
  Rutenya terdaftar di `mobile/lib/app/routing/app_router.dart`.
- Tab Kasir memakai `CartCheckoutScreen`; pada Android, nota tunai dan stok disimpan
  lewat repository SQLite, lalu ringkasan Beranda dibaca ulang dari database.
