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

## Kondisi terkini — 20 November 2026

- Basis kode `a85a159` sudah dipush pada `feat/ui-shell-owner-barcode`.
  Native mengutamakan Firestore melalui `CloudReadThrough`: reuse hasil 15 detik,
  backoff gagal 30 detik, timeout 8 detik, fallback SQLite. Outbox dan revisi data
  melindungi perubahan lokal serta memperbarui UI. Web masih preview lokal.
- Impor Firestore `iyangunshop` / `toko-utama` terverifikasi create-only/read-back:
  24 produk, 66 nota tunai, 394 unit, Rp3.035.800, 10–24 November 2026 inklusif
  (15 hari, 3–6 nota/hari). Data tampil normal tanpa label visual, metadata internal.
- Validasi tahap Monitor: analyzer bersih, 268 test Flutter dan 12 test Node lulus.
- APK debug cloud-first + Monitor berhasil dibangun (50 detik) dan telah dipasang
  ulang via `adb install -r` serta dijalankan pada Samsung SM_A366B (serial RRGYC07G09Z)
  tanpa menghapus data lokal. Logcat menunjukkan startup mulus dan klien Firestore
  aktif. Data 24 produk dan 66 nota yang telah diinjeksi ke Firestore siap
  disinkronkan/ditampilkan di perangkat. Render widget 360/1024 dp skala 1,3
  tersedia di build/monitor-previews.
- Akses baca publik HTTP 200 masih diketahui; rules tidak diubah. Peran Pengaturan
  bukan autentikasi. Stok lintas perangkat last-write-wins; snapshot lintas koleksi
  tidak atomik dan pembacaan dibatasi 10.000 dokumen/koleksi. Live Groq tetap dijeda.
- Monitor **mulai dibangun** atas izin pengguna. Fondasi model, tiga template,
  validasi grid/JSON, repository SQLite dan migrasi 6→7 tersedia. Tombol owner,
  setup template, editor isometrik/drag, penempatan massal dan alert stok tersedia.
  Jalur sync layout+lokasi bertoken tersedia di kode; live server/perangkat belum
  diverifikasi. Target lengkap mengikuti
  [docs/monitor-plan.md](docs/monitor-plan.md); navbar dan alur kasir tidak berubah.
- Semua dokumen operasional diselaraskan. Skill dan contoh desain tetap referensi,
  bukan catatan status fitur. Catatan tanggal lama di bawah adalah riwayat.

## Riwayat kondisi sebelum cloud-first — 15 November 2026

- Beranda kasir dan pemilik terpisah menurut peran Pengaturan, tanpa login/PIN.
  Hero, pod aksi, baris nota, serta Pintasan Menu memakai komponen bersama.
  Pemilik memantau periode Hari ini/7 hari/30 hari, stok, dan produk terlaris;
  kasir mempertahankan susunan operasional semula.
- Halaman Produk memakai grid lazy responsif: 2 kolom pada 360 dp, 3 pada
  600 dp, 5 pada 1024 dp. Tag “Tersimpan di perangkat” dihapus; penghapusan
  tag tidak mengubah persistensi SQLite maupun membuktikan unggah cloud.
- Kamera barcode native, label Code128 pemilik, transaksi lokal, serta ekspor
  PDF/XLSX tersedia. Berbagi Android bukan penyimpanan otomatis ke Downloads.
  Firebase memakai outbox dan pengurasan selama aplikasi berjalan; hasil unggah
  cloud belum diverifikasi. Uji API chatbot langsung tetap dijeda.
- Validasi ulang: `flutter analyze --no-pub` bersih (3,7 detik);
  `flutter test --no-pub --reporter expanded` 212/212 lulus (27 detik).
- APK terbaru berhasil dibangun (51 detik), diperbarui melalui `adb install -r`
  dan diluncurkan pada Samsung SM A366B. Tidak uninstall atau hapus data.
  Build memberi peringatan migrasi KGP plugin Firebase. Pemasangan dan launch
  bukan bukti verifikasi visual/alur lengkap, pemindaian fisik, cetak label,
  pembayaran QRIS nyata, API Groq, atau sinkronisasi cloud.
- Dokumen operasional diselaraskan dengan implementasi. `contoh-desain/` dan
  `.agents/skills/` tetap referensi desain/panduan, bukan status fitur produksi.
  Catatan per tugas di bawah adalah riwayat validasi pada saat tugas dikerjakan.

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
| Monitor pemilik (tata letak isometrik & stok) | `mobile/lib/features/monitor/` | Koordinasi pada `TEAM.md` | review |

## Editor Tata Letak Toko Fullscreen & Etalase — 20 November 2026, review

- Halaman Khusus Editor Fullscreen (`MonitorEditorScreen`):
  1. Kanvas Isometrik 100% Layar: menghilangkan kanvas terjepit; pan & pinch-zoom bebas serta drag & drop snap-to-grid langsung pada viewport penuh.
  2. Floating HUD Ukuran Toko: tombol mengambang di pojok atas membuka sheet penyesuaian ukuran ruang toko. Tersedia preset instan (Kecil `12×12`, Standar `16×16`, Luas `20×20`, Memanjang `12×24`) dan slider manual (`8–32` petak) dengan proteksi batas objek.
  3. Objek Baru "Etalase" (`MonitorFixtureType.showcase`): ukuran 2×1 dengan visual tinggi dan aksen khas etalase/kaca toko. Total 4 tipe objek: Rak, Kulkas, Etalase, Meja Kasir.
  4. Dock Bawah Ergonomis (Thumb-Zone Optimization):
     - Saat tidak ada objek dipilih: bar horizontal tambah objek (`+ Rak`, `+ Kulkas`, `+ Etalase`, `+ Meja Kasir`).
     - Saat objek dipilih: panel kontekstual memuat nama, tombol putar 90°, ubah nama, hapus, tombol atur produk langsung, dan pad geser 1 petak (*Nudge D-pad*) untuk presisi jempol tanpa harus drag.
  5. Top Bar Ringkas: tombol Batal dengan dialog konfirmasi jika kotor, dan tombol Simpan (FilledButton).
- Pembersihan `MonitorScreen` (Mode Pantau Murni):
  1. Halaman utama Monitor fokus 100% untuk memantau stok dan alert toko, dengan tombol `Edit Tata Letak` di AppBar.
  2. Mengetuk rak langsung membuka sheet/dialog rincian stok produk di rak tersebut.
  3. Chip alert stok di atas menyaring daftar peringatan secara instan.
- Validasi:
  - Analyzer bersih (0 peringatan/error).
  - 268/268 test Flutter dan 12/12 test Node lulus.
  - APK debug baru berhasil dibangun (137 detik) di `mobile/build/app/outputs/flutter-apk/app-debug.apk`.

## Penyempurnaan Bento Dashboard, Grafik Kurva dan Bento Statistik — 20 November 2026, review

- Beranda Owner:
  1. Tombol Monitor sendirian di atas dihapus. Area atas langsung mulai dari filter periode (`Hari ini`, `7 hari`, `30 hari`) dan kartu Penjualan Bersih.
  2. Tombol Monitor diintegrasikan ke dalam Bento Aksi Kelola di bawah sebagai kartu unggulan utama ("Monitor Toko — Pantau stok rak & tata letak 3D isometrik") dipadukan dengan 4 action pods (2x2).
  3. Grafik Penjualan Harian dirombak dari diagram batang kaku menjadi *Smooth Area Line Chart* bergradien violet interaktif dengan garis panduan, scrubbing tanggal, dan kurva adaptif (mulai dari Rp 0 saat mode "Hari ini").
  4. Pintasan Menu: Tinggi kartu berpasangan diratakan secara presisi menggunakan `IntrinsicHeight` & `crossAxisAlignment: CrossAxisAlignment.stretch`. Deskripsi Chatbot diselaraskan ("Bantuan tanya jawab") agar pas 1 baris sama dengan kartu Statistik.
- Layar Statistik:
  Dirombak total menjadi **Bento Grid Fungsional Asimetris** mengacu pada prinsip *Linear*, *unslop*, dan *design-taste-frontend*:
  1. Hero Bento Utama: Estimasi Nilai Total Aset Inventaris Toko (`inventoryValue`) dan Omzet/Aktivitas Hari Ini.
  2. 2-Up Bento Cards: Kesehatan Inventaris (item, varian, alert restok) & Efisiensi Margin Laba (rata-rata margin % dan produk termodal).
  3. Bento Komposisi Kategori: Progress bar multi-segment tonal dengan rincian kategori produk.
  4. Kontainer Bento Terstruktur: Tren penjualan, metode pembayaran, jam sibuk, peringkat produk terlaris/lambat laku, margin produk, dan daftar perlu restok.
- Validasi:
  - Analyzer bersih; 268/268 test Flutter dan 12/12 test Node lulus.
  - APK debug dibangun ulang (18,7 detik), diinstal via `adb install -r`, dan diluncurkan di Samsung SM_A366B (`RRGYC07G09Z`) tanpa menghapus data lokal.

## Audit teknis dan perbaikan Monitor — 20 November 2026, review

- Audit komprehensif mengacu pada `audit.native.md` dan `craft-floor.md`:
  1. Concurrency/Race condition: pencegahan permintaan stok lama menimpa hasil
     stok terbaru via sequence counter `_productsRequest`.
  2. Keamanan token: pembangkitan token layout memakai kriptografis `Random.secure()`,
     bukan timestamp microsecond yang dapat ditebak.
  3. Aksesibilitas dan dialog hierarchy: saat peran pengguna berubah di Pengaturan
     sementara dialog/sheet Monitor masih terbuka, seluruh rute Monitor dan modal
     di atasnya ditutup tuntas dengan `popUntil`.
  4. Visual kanvas & clutter: rendering nomor urut ringkas pada kotak atap fixture
     isometrik dengan deteksi overlap untuk mencegah tabrakan label teks pada rak rapat.
  5. Layout form keyboard insets: lembar penempatan produk mengadaptasi `viewInsetsOf`
     sehingga kolom pencarian dan tombol tidak tertutup keyboard virtual.
  6. Idempotensi sinkronisasi: layout jarak jauh yang identik tidak memicu penulisan
     ulang database atau peningkatan revisi lokal yang mubazir.
- Validasi: analyzer bersih (3,9 detik); seluruh 268 Flutter test lulus (24 detik);
  seluruh 12 Node test lulus (0,3 detik). APK dibangun ulang dalam 50 detik.
  Tidak build/install di HP (perangkat belum terhubung), tidak commit/push.

## Build dan verifikasi lanjutan Monitor — 20 November 2026

- APK debug berhasil memakai flag Kotlin incremental nonaktif dan konfigurasi
  privat build tanpa mencetak nilainya. Peringatan migrasi KGP Firebase tetap ada.
- ADB kosong; Flutter juga melaporkan tidak ada emulator Android. Tidak install
  atau menghapus data aplikasi. Jalur APK: `mobile/build/app/outputs/flutter-apk/app-debug.apk`.
- GET layout server `stores/toko-utama/layouts/main` menghasilkan 404 NOT_FOUND;
  belum ada layout tersimpan. GET daftar produk HTTP 200 (26 dokumen saat probe).
  Tidak membuat layout rekaan, mengubah rules, atau menulis data untuk uji ini.
  Hasil baca bukan bukti write/layout transaction native berhasil.
- Dua render widget baru 360/1024 dp skala 1,3 dibuat ke folder build yang tidak
  di-commit. Pemeriksaan gambar melalui tool tidak memberi bukti visual yang dapat
  diandalkan; uji fisik Android masih wajib. Tidak mengklaim audit visual selesai.
- Regresi dashboard yang memakai satu jam lalu gagal setelah tengah malam;
  waktu test disetel ke tengah hari pada tanggal yang sama agar deterministik
  terhadap batas hari. Tidak mengubah logika dashboard produksi.
- Validasi akhir: analyzer bersih; 265/265 Flutter test dan 12/12 Node test lulus.
  Tugas berikutnya: hubungkan Android USB, install -r, simpan layout owner nyata,
  verifikasi layout/read-back/cloud+offline dan role guard. Belum commit/push.

## Monitor isometrik, penempatan dan jalur sinkronisasi — 19 November 2026, review

- Tanpa sub-agent. Isometrik CustomPainter, hit-test, pan/zoom/reset, pemilihan,
  drag snap hanya Edit; gesture editor dipisah dari InteractiveViewer agar drag
  tidak kalah arena gesture. Daftar objek sebagai alternatif aksesibel.
- Penempatan massal pencarian/kategori, lokasi utama satu produk, detail stok dan
  alert habis/menipis/belum ditempatkan. Stok dibaca ulang dari repository/revisi
  sesi; draft penempatan tidak menyalin stok. Hapus objek melepas penempatan.
- Layout+penempatan atomik SQLite, proyeksi lokasi produk tanpa perubahan stok/harga.
  Outbox layout token/baseToken, precondition konflik, retry idempoten dan transaksi
  Firestore memperbarui layout+lokasi saja. Maksimal 400 penempatan/450 lokasi per save.
  Layout pending menjaga lokasi saat cache stok segar masuk. Antrean produk/nota
  didahulukan dan kegagalan layout tidak memblokir operasi POS.
- Jalur cloud belum diuji live. Tidak mengubah rules/deploy atau menulis Firestore;
  koleksi layout dapat ditolak rules server. Status lokal/pending/gagal tidak
  disamakan tersinkron. Browser tanpa SQLite tetap menjelaskan batas native.
- Validasi akhir: analyzer bersih (3,7 detik), seluruh 263 Flutter test lulus
  (22 detik), termasuk detail stok reaktif. Tidak build/install/commit/push.

## Setup dan editor lokal Monitor — 19 November 2026, review

- Tanpa sub-agent. Beranda owner membuka Monitor; akses kasir diblokir dan peran
  dibaca ulang sebelum/sesudah write dalam transaksi agar role berubah membatalkan save.
- Setup tiga preview template, editor ortografik, daftar objek, tambah/nama/pindah
  satu petak/rotasi/hapus, Simpan/Batal dan konfirmasi keluar. Draft gagal save
  dipertahankan; revisi conflict memerlukan batal/muat ulang. Tidak ada stok palsu.
- Penyimpanan tetap lokal. Browser tanpa DB menjelaskan batas native; tidak
  mengaku berhasil simpan. Penempatan produk, drag, isometrik dan cloud menyusul.
- Analyzer bersih; seluruh 253 test Flutter lulus (38 detik).
  Enam test editor mencakup draft/retry/conflict, rollback izin, kembali/buang,
  role guard, serta 360/1024 dp skala 1,3. Visual Android belum diperiksa.
  Tidak build/install, commit/push atau tulis Firestore.

## Fondasi Monitor tahap 0–1 — 19 November 2026, review

- Implementasi langsung tanpa sub-agent sesuai permintaan. Audit arsip menemukan
  ViewModel berbasis sample; tidak diaktifkan kembali. Model baru immutable,
  validasi versi/payload, ID unik, footprint rotasi, batas area dan overlap.
- Tiga template deterministik; penyimpanan satu layout lokal dengan revisi optimistic.
  Migrasi Drift 6→7 hanya menambah tabel; kode generated dibangun dengan build_runner.
  Data rusak tidak direset diam-diam. Simpan layout tidak menyentuh produk/POS/outbox.
- Untuk tahap fondasi, menghapus objek terpakai diblokir; pelepasan penempatan atomik
  dan cloud conflict/save tetap tahap berikutnya. Belum UI/editor/isometrik/routing.
- Analyzer bersih, 247/247 test Flutter lulus (40 detik), termasuk tujuh test baru
  template/JSON/grid, conflict/rollback, reopen, migrasi dan preservasi POS.
  Tidak menambah dependensi, build/install APK, commit/push atau menulis Firestore.

## Perencanaan Monitor dan sinkronisasi dokumentasi — 19 November 2026

- Rencana lengkap disimpan di `docs/monitor-plan.md`: scope, trade-off template,
  setup dua langkah, Pantau/Edit, draft, penempatan massal, kontrak data/offline,
  tahapan implementasi, ownership usulan dan kriteria penerimaan.
- Kandidat arsip `floor_plan` diaudit awal: ViewModel memakai data sample sehingga
  tidak boleh diaktifkan langsung. Renderer/data Monitor belum ditulis.
- Dokumen aktif membedakan fitur berjalan, impor cloud terverifikasi, keterbatasan,
  dan Monitor terencana. Pemeriksaan 13 dokumen operasional: tautan lokal dan
  pagar kode valid; `git diff --check` bersih. Analyzer/test tidak dijalankan ulang
  karena tugas ini hanya dokumentasi. Referensi skill/desain tidak diubah. Tidak mengakses rahasia,
  menulis Firestore, mengubah kode, build/install APK, atau commit/push dalam tugas ini.

## Validasi sebelum commit cloud-first — 19 November 2026

- `flutter analyze --no-pub` bersih; seluruh 240 test Flutter lulus.
- 12 test Node alat impor lulus. Nama akumulator test diselaraskan agar tidak
  berbenturan dengan simbol Drift. Tidak mengubah perilaku aplikasi.
- Commit mencakup kode cloud-first, tool impor, test dan dokumentasi; tidak
  memasukkan kredensial lokal Google. APK belum dibangun/dipasang ulang.

## Impor Firestore terverifikasi — 19 November 2026

- Google Cloud CLI dipasang di komputer, pengguna mengotorisasi akun melalui
  browser. Token OAuth hanya dipakai di memori proses, tidak dicetak/disimpan
  ke repository. Tidak menambahkan login aplikasi atau mengubah rules Firestore.
- Tool impor dijalankan dengan akses OAuth: `read-back-verified`, 90 dokumen
  dibuat, 0 dilewati, 90 terbaca ulang sesuai rencana pada proyek `iyangunshop`,
  `stores/toko-utama`. Hasil: 24 produk, 66 nota tunai, 394 unit, Rp3.035.800,
  tanggal 10–24 November 2026. Tidak menimpa dokumen lama.
- Data memakai komponen normal tanpa label visual; metadata asal tetap internal.
  Belum membangun/memasang APK cloud-first atau memverifikasi tampilan data ini
  di HP. Browser aplikasi tetap jalur preview tanpa cloud-first native.
- Rules masih mempunyai risiko akses baca publik; impor berhasil tidak berarti
  keamanan tenant atau stok bersamaan lintas perangkat sudah terverifikasi.
  Catatan penghambat akses OAuth sebelumnya di bawah adalah riwayat, kini teratasi.

## Impor dan transaksi lanjutan — 19 November 2026

- Pengguna menegaskan tampilan data tanpa label dan transaksi baru tetap normal;
  tidak menyetujui tambahan login/PIN/Anonymous Auth. Rules tidak diubah.
- Regresi baru memakai seluruh 24 produk/66 nota dari generator, lalu checkout
  nyata lewat Drift: 67 nota, stok berkurang sesuai jumlah, nominal dan outbox
  benar. Refresh cloud usang tidak menimpa penjualan tertunda; impor ulang tidak
  menggandakan nota atau mengurangi stok ulang. Test cloud read-through 19/19 lulus.
- Injeksi tetap belum berjalan: tidak tersedia OAuth admin lokal. Jalur dipilih
  adalah Cloud Shell dengan akun pengguna yang memiliki izin proyek; token tidak
  dikirim lewat chat atau dimasukkan ke repository. Upload tool dan otorisasi akun
  memerlukan interaksi pengguna. Tidak mengubah rules publik atau menguji tulis
  tanpa autentikasi sebagai jalan pintas.

## Lanjutan cloud-first — 19 November 2026, menunggu akses cloud

- Perbaikan setelah jeda sudah tersimpan: hasil server digunakan ulang 15 detik,
  kegagalan diberi backoff 30 detik, timeout 8 detik memakai cache. Request native
  yang terlambat tetap dilacak agar tidak overlap; hasil terlambat tidak diimpor.
- Ack outbox nota lama kini atomik dengan antrean rekonsiliasi stok terkait.
  Perubahan produk/hapus yang masih tertunda tetap dilindungi dari cache cloud.
  Revisi data sesi memperbarui dashboard, katalog, statistik, dan laporan tanpa
  bergantung hanya pada jumlah nota hari ini; tidak mengulang checkout impor.
- Validasi ulang: `flutter analyze --no-pub` bersih (6 detik),
  `flutter test --no-pub --reporter expanded` 239/239 lulus (45 detik).
  `node --test mobile/tool/seed_firestore_november.test.mjs` 12/12 lulus;
  `node mobile/tool/seed_firestore_november.mjs --check-only` berhasil tanpa tulis.
  Dataset tetap 24 produk dan 66 transaksi selama 10–24 November 2026.
- Probe tanpa autentikasi masih HTTP 200 untuk koleksi produk. Credential OAuth
  lokal/ADC/CLI belum tersedia pada lokasi yang diperiksa. Injeksi belum dijalankan;
  jangan melaporkan statistik cloud terisi. Perlu persetujuan autentikasi perangkat
  tanpa layar login dan pemberian izin anggota toko, serta akses admin lokal yang sah.
- Batas yang belum diselesaikan: stok multi-device masih last-write-wins, snapshot
  lintas koleksi/page tidak atomik, batas 10.000 dokumen/koleksi, fetch native tidak
  dapat dibatalkan (retry menunggu selesai), dan web masih preview lokal. Full scan
  memakai read Firestore sesuai jumlah dokumen meskipun dibatasi reuse 15 detik.
  Tidak build/install APK, commit/push, mengubah rules, atau menulis Firestore.

## Checkpoint jeda — 16 November 2026

Pengguna meminta berhenti dan melanjutkan nanti. Perubahan tetap di working tree,
belum commit/push. Branch `feat/ui-shell-owner-barcode`; commit terakhir yang
sudah di-push: `8231ce9` (`Rapikan navigasi dan antarmuka laporan`).

### Keputusan yang sudah disetujui

- Isi Firestore proyek `iyangunshop`, toko `toko-utama`, dengan produk dan
  transaksi 10–24 November 2026 inklusif (15 hari, termasuk tanggal mendatang).
  Minimal tiga transaksi per hari; ID yang sudah ada dilewati, bukan diperbarui.
- Tidak ada label visual contoh/sintetis/demo untuk data impor. Asal tetap
  tercatat internal lewat ID/metadata; aturan aktif dokumentasi sudah diselaraskan.
- Cloud-first saat online, SQLite sebagai cache dan fallback offline. Tanpa
  penambahan login UI; autentikasi/rules baru memerlukan konfirmasi pengguna.

### Berkas dan hasil sementara

- Implementasi awal `mobile/lib/core/data/sync/cloud_read_through.dart`, parser
  Firestore, repository, outbox, serta wiring app/session sudah ditulis.
  Perubahan lanjutan invalidasi UI/reuse refresh mungkin sudah sebagian tersimpan
  saat agen dibatalkan; tinjau diff aktual sebelum meneruskan.
- Hasil uji terakhir yang dilaporkan agen sebelum review lanjutan: analyzer bersih,
  231/231 test Flutter lulus. Ini bukan validasi final semua perubahan saat jeda.
- Tool `mobile/tool/seed_firestore_november.mjs` beserta test sudah dibuat:
  24 produk, 66 nota tunai, 394 unit, total Rp3.035.800; 3–6 nota per hari.
  Default dry-run, create-only, skip existing, read-back wajib. Agen melaporkan
  12/12 test Node lulus. Belum menjalankan `--apply` atau menulis data Firestore.
- Belum build/install APK, commit, atau push untuk perubahan cloud/data ini.

### Penghambat dan langkah lanjut

1. Probe GET REST produk tanpa autentikasi menghasilkan HTTP 200; konten dokumen
   tidak dicetak. Ini membuktikan koleksi produk dapat dibaca publik, bukan bukti
   izin tulis publik. Rules repository mensyaratkan anggota terautentikasi,
   sehingga konfigurasi deployment perlu diperiksa sebelum injeksi.
2. Firebase CLI, gcloud, ADC, dan konfigurasi credential environment tidak ditemukan
   pada lokasi yang diperiksa. Jangan meminta token/key lewat chat. Siapkan akses
   OAuth lokal atau Cloud Shell yang sah dan konfirmasi rancangan auth/rules.
   Jangan membuka rules publik demi menjalankan aplikasi tanpa login UI.
3. Review cloud-first menemukan pembacaan seluruh dua koleksi pada setiap read
   berurutan: perlu reuse refresh/backoff agar tidak boros read dan menunggu 8 detik
   berulang saat offline. Pastikan timeout tidak melahirkan fetch tumpang tindih.
4. Pastikan outbox transaksi lama yang belum membawa snapshot stok direkonsiliasi
   sebelum acknowledgment; jangan sampai cache cloud mengembalikan stok lama.
5. Periksa invalidasi dashboard berdasarkan revisi data, bukan hanya jumlah nota
   hari ini, agar stok dan nota periode lama yang diunduh memperbarui layar.
6. Stok lintas perangkat masih last-write-wins; upload stok absolut dapat kehilangan
   pengurangan bersamaan. Snapshot lintas koleksi/page bukan snapshot server atomik.
   Batas fetch awal 10.000 dokumen per koleksi. Jangan klaim konsistensi multi-device
   atau kesiapan produksi sebelum masalah ini ditangani dan diuji.
7. Setelah perbaikan, jalankan analyzer, seluruh test Flutter, serta test Node tool;
   baru lakukan dry-run/import autentikasi dan verifikasi read-back. Web masih jalur
   preview, bukan cloud-first native yang sudah diverifikasi.

## Catatan per tugas

**Tariq / aturan lintas fitur disetujui pengguna — Data presentasi (2026-11-16).**

- Kewajiban label visual contoh/sintetis/demo dihapus untuk data sintetis yang
  diimpor ke repository. Komponen, angka, dan perhitungan memakai alur biasa.
  ID atau metadata internal tetap menyimpan asal untuk impor ulang aman dan
  pembersihan; ini bukan izin status pembayaran/sinkronisasi palsu.
- Aturan aktif pada AGENTS, DESIGN, PRODUCT, TEAM dan panduan terkait diselaraskan.
  Catatan historis di bawah tetap merekam keputusan saat tugasnya dikerjakan.
  Perubahan ini hanya dokumentasi: belum membuat/mengimpor data atau mengubah
  pembacaan Firestore menjadi cloud-first. Tidak commit/push pada tugas ini.

**Tariq / lingkup lintas fitur disetujui pengguna — Perapian antarmuka (2026-11-16), review.**

- Navbar: Beranda, Chatbot, Kasir, Produk, Statistik. Dashboard pemilik tanpa
  header Kelola warung, keterangan perangkat, rentang tanggal, serta teks kosong
  dan tombol Buka Kasir di bawah grafik. Judul perhatian stok menjadi Status Stok.
- Laporan harian memakai hierarki UI baru; keterangan perangkat di bawah panel
  tanggal dihapus sesuai permintaan. Cakupan lokal tetap dijelaskan lewat bantuan
  dan berkas ekspor; penanda data contoh tetap. Tag lokal Statistik dihapus.
- Teks panduan tambah produk di atas chat dan contoh panjang pada sapaan awal
  dihapus. Fungsi chatbot, konfirmasi, dan pembatasan peran tidak diubah.
- Validasi ulang sebelum commit: `flutter analyze --no-pub` bersih (3,7 detik);
  `flutter test --no-pub --reporter expanded` 220/220 lulus (28 detik).
  APK belum dibangun/dipasang ulang untuk perubahan ini. Konfigurasi model agent
  Zed berada di luar repository dan tidak masuk commit aplikasi.

**Tariq — Penyempurnaan UI laporan harian berbasis HCI (2026-11-16), review.**

- Hierarki tanggal → ringkasan penjualan → rincian → ekspor mengikuti prinsip
  status terlihat, pengenalan alih-alih mengingat, konsistensi, minimalisme dan
  pemulihan dari heuristik NN/g (`https://www.nngroup.com/articles/ten-usability-heuristics/`).
  Ini penerapan pedoman, bukan hasil usability testing pengguna.
- Tanggal menjadi tombol berikon minimal 48 dp dalam satu panel dengan Hari ini
  dan muat ulang bertooltip. Scope perangkat ini/offline/waktu lokal tetap terlihat;
  penjelasan lengkap lewat disclosure. Ringkasan bersih memakai panel violet tonal,
  angka kotor/diskon, pembayaran, produk dan nota dikelompokkan. Empty/error
  berkartu dengan satu CTA utama. Ekspor PDF/Excel dalam panel khusus, proses/gagal
  tetap terlihat, penjelasan Downloads dan berbagi tetap jujur. Laporan kosong
  tetap dapat diekspor. Konten tablet dibatasi 768 dp. Date picker lebar ≥768 dp
  memakai input native awal untuk menghindari assertion pembulatan PageView Flutter
  pada rentang 1970–9999; toggle kalender dan rentang tanggal tidak dihapus.
- Query harian, repository, pembentukan/berbagi PDF/XLSX, pemeriksaan peran
  sebelum/sesudah async tetap; kasir hanya riwayat/detail. Tidak menambah dependensi.
- Validasi: `flutter analyze --no-pub` bersih (3,8 detik);
  `flutter test --no-pub --reporter expanded` 220/220 lulus (27 detik).
  Lima test UI baru mencakup 360/600/1024 dp skala 1,3, tanggal, Hari ini,
  empty/help/export dan laporan terisi/detail. Test ekspor/izin lama tetap
  memeriksa PDF/XLSX nyata, penguncian, error/retry dan perubahan peran.
  Capture PNG widget sementara timeout 90 detik dan dibuang; gambar/render
  langsung serta perangkat Android belum diverifikasi. Tidak build/install,
  commit/push, atau mengubah pekerjaan navigasi/dashboard pengguna.

**Tariq — Lima tombol navigasi bawah (2026-11-16), review.**

- Urutan akhir sesuai koreksi pengguna: Beranda, Chatbot, Kasir terangkat
  di tengah, Produk, Statistik. Label tab Katalog diganti Produk; rute tetap.
  Validasi ulang setelah koreksi: analyzer bersih, 215/215 test lulus.
  Aset Chatbot/Statistik dan callback rute lama dipakai tanpa menambah tab enum
  atau halaman baru. Kembali dari rute mempertahankan tab sebelumnya;
  Pengaturan tetap melalui app bar. Statistik kasir tetap Riwayat Nota melalui
  guard router lama, bukan analitik/laporan pemilik.
- Lima slot seimbang, tooltip, semantik tombol/state aktif dan aksi aksesibilitas;
  target minimal 48 dp. Blueprint `FloatingBottomNav` pada `DESIGN.md`
  diselaraskan. Perubahan pengguna pada header/empty state pemilik dipertahankan.
- Validasi: `flutter analyze --no-pub` bersih (3,8 detik); sembilan test shell
  lulus termasuk tiga regresi baru pada 360/1024 dp skala 1,3, urutan/posisi
  Kasir/target, navigasi asli, kembali, Pengaturan dan pembatasan kasir.
  Suite `flutter test --no-pub --reporter expanded` selesai sekitar 26 detik:
  215/215 lulus setelah ekspektasi `Kelola warung` pada test alur lengkap
  diselaraskan dengan penghapusan header yang diminta pengguna.
  Header tidak dikembalikan. Tanpa dependensi
  baru, commit/push, build/install APK; visual perangkat belum diperiksa.

**Tariq — Pulihkan Pintasan Menu kedua dashboard (2026-11-14), review.**

- Blok pintasan hilang saat dashboard dipisah. Tata letak dua kolom dan kartu
  `_ShortcutTile` dari `origin/main` (juga tersedia sebelum `cce1409`) dipulihkan
  melalui `DashboardShortcutsSection`, dipakai kasir dan pemilik setelah nota.
  Isi asli: Katalog produk, Keranjang, Riwayat transaksi, Pengaturan, Statistik,
  Chatbot; label/deskripsi/aset dari `DashboardSample.shortcuts` dipertahankan.
- Navigasi tetap callback/router lama. Kasir tidak memperoleh aksi kelola produk;
  laporan tetap mengikuti izin layar tujuan. Hero, bento, monitoring/periode,
  query dan perubahan katalog yang belum commit tidak diubah. Deskripsi kartu
  boleh membungkus penuh, ikon memakai footprint 48 dp dan token tema lama.
- Validasi: `flutter analyze --no-pub` bersih;
  `flutter test --no-pub --reporter expanded` 212/212 lulus (sekitar 31 detik).
  Dua regresi baru menggulir dan menekan semua item pada kedua peran di 360 dp,
  skala 1,3, memeriksa callback, aset, label, dan ukuran target. Ekspektasi test
  alur lokal yang masih mencari badge katalog lama diselaraskan dengan judul
  Produk; penghapusan badge pengguna tidak dibatalkan. Tidak ada commit/push,
  build/install APK atau verifikasi visual langsung perangkat Android.

**Tariq / lingkup katalog disetujui pengguna — Grid Produk responsif (2026-11-14), review.**

- Hanya judul halaman `Katalog Produk` diganti `Produk`; istilah katalog lain
  tetap. Kartu memakai permukaan tema violet, ikon kategori tonal, nama,
  kategori/lokasi, barcode bila ada, harga, status stok berikon, dan tombol Kasir.
- `CustomScrollView`/`SliverList.builder` membangun baris sesuai viewport secara
  lazy. Dua kolom pada ponsel 360 dp, tiga pada 600 dp, lima pada 1024 dp;
  jumlah mengikuti lebar tersedia. Tinggi kartu alami, tanpa aspect ratio atau
  pemotongan teks. Tidak menambah dependensi. Pencarian/filter/urutan, detail,
  formulir/izin, dan state kosong/loading/error/offline dipertahankan. Tombol
  tambah membaca perubahan keranjang dan berhenti pada jumlah stok kartu.
- Validasi: `flutter analyze --no-pub` bersih;
  `flutter test --no-pub --reporter expanded` 210/210 lulus (sekitar 30 detik).
  Empat test baru mencakup 360/600/1024 dp skala 1,3, nama/barcode/harga panjang,
  kolom sejajar, lazy build, target 48 dp, batas stok, pencarian/detail dan izin.
  Perubahan dashboard belum commit dipertahankan tanpa disentuh. Tidak membuat
  commit/push, build APK, atau pemasangan. Visual Android fisik belum diperiksa.

**Tariq — Penyelarasan komponen Beranda pemilik dan kasir (2026-11-14), review.**

- `dashboard_components.dart` mengekstrak Hero, pod aksi, dan baris transaksi
  asli kasir. Kasir memakai nilai bawaan yang sama; tata letak, aset, CTA pindai,
  query, serta state tetap. Nilai rata-rata dibatasi secara fleksibel agar
  membungkus saat ruang sempit, tanpa mengubah ukuran huruf.
- Pemilik memakai Hero gradien yang sama untuk Penjualan Bersih, jumlah nota,
  rata-rata, dan CTA Lihat laporan. Aksi kelola memakai pod dua kolom, daftar
  nota memakai baris bersama dalam satu kartu, ikon perhatian stok memakai
  wadah tonal. Mengikuti geometri, tipografi, dan ritme kedua `DESIGN.md`, dengan
  identitas violet proyek tetap mengalahkan contoh palet biru. Hierarki monitoring
  dan periode Hari ini/7 hari/30 hari, data lokal, izin, serta query tidak diubah.
- Validasi: `flutter analyze --no-pub` tanpa isu;
  `flutter test --no-pub --reporter expanded` 206/206 lulus (sekitar 25 detik).
  Test memastikan Hero/desain bersama, CTA menurut peran, nilai periode,
  target tombol 48 dp, dan layout 360 dp/skala 1,3. Ekspektasi integrasi Beranda
  diselaraskan dengan label Hero baru. Tidak menambah dependensi/backend/login.
  Tidak menjalankan build APK, emulator/perangkat, pemasangan, commit, atau push;
  pemeriksaan visual Android langsung masih diperlukan.

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
- Nominal rupiah lewat `formatRupiah` di `core/format/rupiah.dart`. Data sintetis
  yang diimpor untuk presentasi tidak perlu label visual; asal tetap tercatat
  melalui ID atau metadata internal.
- Alur pembuka aplikasi: splash menuju perkenalan (sekali per sesi), lalu kerangka utama.
  Rutenya terdaftar di `mobile/lib/app/routing/app_router.dart`.
- Tab Kasir memakai `CartCheckoutScreen`; pada Android, nota tunai dan stok disimpan
  lewat repository SQLite, lalu ringkasan Beranda dibaca ulang dari database.
