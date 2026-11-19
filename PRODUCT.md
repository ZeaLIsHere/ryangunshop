# RyanGunshop — Konteks Produk

Status berjalan: **19 November 2026**, branch `feat/ui-shell-owner-barcode`.
Basis kode terakhir dipush: `a85a159`.

## Produk dan pengguna

RyanGunshop adalah aplikasi kasir dan pengelolaan warung berbasis Flutter/Dart
untuk Android 8.0 ke atas (API 26). Pembacaan native bersifat cloud-first melalui
`CloudReadThrough`; SQLite/Drift menyimpan cache, produk, stok, draft keranjang,
nota tunai, dan outbox agar operasi lokal tetap tersedia saat offline. Database
lokal baru dimulai kosong dan dapat diisi dari cloud; web tetap pratinjau lokal.
Data presentasi yang diimpor memakai alur repository biasa, bukan pengganti error.

- **Pemilik:** mengelola produk, stok, barcode/label, laporan, serta analitik.
- **Kasir:** mencari atau memindai produk, mengatur keranjang, menerima tunai,
  dan melihat nota.

Peran dipilih lewat Pengaturan tanpa login atau PIN. Batas aksi pemilik sudah
ada di UI dan jalur simpan, tetapi pemilihan peran bukan autentikasi atau
jaminan keamanan. Denah dan panorama 360 disimpan sebagai arsip fitur, bukan
pengalaman utama POS.

## Pengalaman inti saat ini

1. **Pembuka dan orientasi.** Splash bermotion sekitar 1,45 detik, crossfade
   280 ms, onboarding tiga halaman, serta dukungan reduced motion.
2. **Beranda kasir.** Hero Omzet harian asli, laporan harian, empat bento
   Pindai Barcode/Buka Kasir/Stok/Riwayat Nota, dan transaksi terbaru.
3. **Beranda pemilik.** Penjualan Bersih, jumlah nota, rata-rata, grafik harian kurva halus (*Smooth Area Line Chart* bergradien violet interaktif dengan scrubbing tanggal dan kurva adaptif), Status Stok, **Bento Aksi Kelola** (kartu unggulan Monitor Toko 3D isometrik + 4 action pods), produk terlaris, nota periode.
   Periode Hari ini/7 hari/30 hari membaca repository nyata; hari kosong bernilai
   nol. Penjualan produk terlaris berlabel kotor sebelum diskon nota, bukan laba.
4. **Komponen bersama.** Kedua Beranda memakai Hero, pod aksi, dan baris nota
   bersama tanpa menyamakan tugas tiap peran. Pintasan Menu tersedia pada
   keduanya: Katalog produk, Keranjang, Riwayat transaksi, Pengaturan,
   Statistik, dan Chatbot. Izin tetap mengikuti layar tujuan.
5. **Produk.** Judul halaman `Produk`; pencarian, kategori, urutan, stok menipis,
   detail, dan formulir pemilik. Grid lazy mengikuti lebar tersedia: dua kolom
   pada 360 dp, tiga pada 600 dp, lima pada 1024 dp, termasuk text scale 1.3.
   Badge lokal di judul dihapus, bukan berarti sinkronisasi cloud sudah berhasil.
6. **Barcode.** Kamera nyata melalui `mobile_scanner`, senter, izin/error,
   pencarian manual, dan alur barcode asing. Pemilik dapat membuat kode internal
   RG dan label Code128; kode itu bukan EAN/GS1 resmi. Barcode kemasan yang ada
   tidak diganti. Label A4 berisi 16 label per halaman, cetak ukuran aktual 100%.
7. **Kasir dan pembayaran.** Kuantitas, diskon, total, nominal tunai cepat,
   uang pas, dan kembalian. Checkout menyimpan nota beserta snapshot item dan
   mengurangi stok dalam transaksi SQLite. QRIS tetap jalur simulasi;
   pembayaran QRIS nyata belum terverifikasi.
8. **Laporan dan statistik.** Laporan harian PDF dan XLSX dari transaksi repository,
   dibagikan lewat Android (bukan auto-save ke Downloads). Layar **Statistik** berbasis
   **Bento Grid Asimetris**: Hero nilai aset inventaris toko dan omzet, 2-up kesehatan
   stok & efisiensi margin laba, komposisi kategori produk, tren, dan daftar restok.
   Tidak mengklaim laba historis transaksi lama karena harga modal belum disnapshot.
9. **IyanBoT.** Integrasi Groq memakai tool baca serta draft transaksi/produk.
   LLM tidak langsung menulis: pengguna harus mengonfirmasi draft sebelum
   repository menyimpan. Draft produk hanya untuk pemilik. Uji API langsung
   belum terverifikasi; kelanjutan pengujian dijeda atas permintaan pengguna.

## Monitor — UI lokal dan penempatan tersedia, cloud belum diverifikasi

Rujukan kanonis: [docs/monitor-plan.md](docs/monitor-plan.md).
Tiga template, editor drag/grid, kanvas isometrik, penempatan massal, detail
rak dan alert stok repository tersedia. Penyimpanan lokal SQLite 6→7 atomik
bersama proyeksi lokasi produk, tanpa mengubah stok/harga. Jalur outbox/cloud
layout+lokasi bertoken ditulis; operasi live dan visual perangkat belum diuji.
Detail status/batas mengikuti rencana kanonis.

- **Masuk:** tombol pada Beranda pemilik membuka halaman baru, bukan tab baru.
  Navigasi yang ada tetap; tanpa login baru. Tampilan isometrik 2.5D ringan dari
  atas memakai Flutter native, tanpa engine atau dependensi baru.
- **Penyiapan dua langkah:** pilih template, lalu tempatkan produk. Tiga template:
  rak sepanjang dinding, dua baris rak, serta rak dinding + tengah. Penempatan
  massal memakai filter dan konfirmasi manual; produk tanpa lokasi boleh ditunda.
- **Data:** satu fixture utama per produk memakai `fixtureId`, `locationLabel`,
  dan ambang stok yang sudah ada. Stok dibaca dari repository, tanpa salinan
  hitungan. Belum mendukung kuantitas fisik per lokasi atau deteksi otomatis.
- **Pantau dan Edit:** mode terpisah. Editor sederhana memakai snap ke grid;
  tambah, beri nama, pindah, putar 90°, atau hapus rak, kulkas, dan meja kasir.
  Simpan/Batal berlaku pada draft; keluar dengan perubahan belum disimpan perlu
  konfirmasi. Menghapus fixture melepas penempatan, bukan menghapus produk;
  memindahkan fixture tidak mengubah stok.
- **Interaksi:** bottom sheet pada ponsel, panel samping pada tablet; target
  minimal 48 dp, lebar 360 dp dan text scale 1.3, state kosong/memuat/error/offline.
- **Arsip:** kode `floor_plan` hanya kandidat penggunaan ulang setelah audit,
  bukan mengaktifkan kembali layar data contoh. Usulan pembagian tugas ada di
  `TEAM.md`; belum menetapkan kepemilikan permanen.

## Cloud dan batas keamanan

Firebase native sudah dikonfigurasi dan diaktifkan lewat `FIREBASE_ENABLED` pada
build yang memakai konfigurasi privat. Outbox SQLite menampung perubahan produk
dan transaksi yang dicatat saat jalur sinkronisasi aktif. Pengurasan dijalankan
saat startup, perubahan sesi, serta berkala 15 detik selama aplikasi berjalan;
bukan layanan latar belakang Android.

`CloudReadThrough` mengutamakan server, memakai ulang hasil selama 15 detik,
backoff kegagalan 30 detik, serta timeout 8 detik dengan fallback cache lokal.
Perubahan produk/hapus dan transaksi yang masih tertunda dilindungi dari hasil
cloud usang. Revisi data sesi menyegarkan dashboard, katalog, statistik, dan
laporan. Stok lintas perangkat masih last-write-wins, bukan atomik. Tidak ada
snapshot atomik lintas halaman/koleksi; batas 10.000 dokumen per koleksi.
Pemindaian koleksi tetap memakai read Firestore sesuai jumlah dokumen.

Impor Firestore `iyangunshop` / `stores/toko-utama` terverifikasi pada
19 November 2026: 90 dokumen dibuat dan terbaca ulang, 24 produk, 66 nota tunai,
394 unit, Rp3.035.800. Data presentasi mencakup 10–24 November 2026 inklusif
(15 hari, 3–6 nota/hari), termasuk tanggal setelah hari verifikasi; bukan klaim
penjualan aktual. Tidak ada label visual demo; metadata asal tetap internal.

Bukti impor bukan bukti unduh data lewat aplikasi nyata atau pemulihan perangkat
baru. APK cloud-first belum dibangun/dipasang. Produk lama sebelum outbox aktif
tidak otomatis di-backfill. Web tidak memakai SQLite atau cloud-first native.

Akses baca tanpa autentikasi diketahui menghasilkan HTTP 200. Rules tidak diubah;
pengguna menolak tambahan login/PIN/Anonymous Auth. Autentikasi dan isolasi tenant
belum terjamin. Pemilihan peran bukan pengaman data.

Rahasia tidak boleh masuk repository atau dokumentasi. Konfigurasi build di APK
bukan tempat aman bagi secret server. Groq/cloud memerlukan jaringan dan dapat
mengirim konteks toko ke penyedia; kegagalan layanan tidak boleh menghilangkan
transaksi SQLite. QRIS produksi memerlukan provider resmi, konfirmasi server,
dan webhook tervalidasi; jangan menyimpan secret pembayaran di aplikasi.

## Karakter dan prinsip

Praktis, tenang, jelas, dapat dipercaya. Identitas violet `#7C3AED` dan
`#6D28D9`, permukaan netral, aset 3D konsisten, serta token `DESIGN.md` dipertahankan.

- Alur kasir singkat; operasi POS lokal tidak bergantung pada cloud/Groq.
- Angka usaha berasal dari repository, bukan nilai contoh pengganti error.
- Nominal memakai `int` rupiah; tampilkan lewat `formatRupiah`.
- State kosong, memuat, error, dan offline harus jelas serta punya jalan lanjut.
- Target sentuh minimal 48 dp, lebar 360 dp dan text scale 1.3 tetap dapat dipakai.
- Data sintetis yang diimpor untuk presentasi tampil seperti data repository
  lainnya, tanpa label contoh/sintetis/demo; ID atau metadata internal menyimpan
  asalnya untuk impor ulang dan pembersihan. QRIS simulasi tetap dijelaskan
  sebagai simulasi; status cloud hanya berdasarkan bukti.

## Bukti dan pekerjaan berikutnya

Validasi terakhir yang dilaporkan pada 19 November 2026: analyzer bersih,
240 test Flutter dan 12 test Node lulus; tidak dijalankan ulang untuk pembaruan
dokumen ini. APK debug 15 November pernah dibangun/dipasang/diluncurkan pada
Samsung SM_A366B, tetapi bukan APK cloud-first terbaru. Build/install cloud-first,
unduh data cloud melalui aplikasi nyata, audit UI/alur penuh, pemindaian fisik,
cetak label/struk, dan live Groq belum terverifikasi.

Langkah berikutnya: verifikasi build/install dan pembacaan cloud di Android,
outbox, pemulihan serta backfill, cetak/pindai label, dan pematangan rencana
Monitor. Pengamanan akses tetap celah produksi; login/PIN/Anonymous Auth tidak
boleh ditambahkan tanpa persetujuan baru. QRIS resmi, restok prediktif, snapshot
modal untuk laba historis, foto koreksi privat, TFLite, serta WhatsApp/Ollama
`backend-agent` bukan fitur produksi yang dijanjikan.
