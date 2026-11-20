# Monitor — Rencana implementasi

Status: **20 November 2026 — Monitor isometrik, editor fullscreen & penempatan produk selesai**.
Halaman utama Monitor berfokus murni untuk pemantauan stok 2.5D, detail rak, dan alert.
Halaman khusus `MonitorEditorScreen` menyediakan kanvas fullscreen, pengaturan ukuran toko
(preset & slider), 4 tipe objek (Rak, Kulkas, Etalase, Meja Kasir), penempatan produk massal,
kontrol jempol (dock bawah), dan proteksi simpan/batal/konflik.
Jalur cloud layout ditulis tetapi belum diuji pada server/perangkat nyata.
Tidak ada dependensi baru/deployment. Browser tanpa SQLite memberi penjelasan,
bukan penyimpanan sementara yang disamarkan sebagai layout permanen.

Fondasi saat ini: `MonitorLayout`/`MonitorFixture`, empat tipe fixture (termasuk Etalase),
tiga `MonitorTemplate`, validasi grid dan JSON, `MonitorLayoutRepository`, tabel Drift
`monitor_layouts` (migrasi 6→7), serta revisi lokal optimistic untuk menolak edit usang.
Penyimpanan layout dan penempatan atomik, tidak mengubah stok/harga/nota/keranjang.
Penempatan kanonis di snapshot layout; `fixtureId`/`locationLabel` produk menjadi proyeksi lokasi utama.
Maksimum 400 penempatan, maksimum 450 perubahan lokasi per operasi untuk batas transaksi Firestore.
Outbox jenis layout menyimpan token/baseToken; cloud target `stores/{storeId}/layouts/main`.
Transaksi server membaca revisi dan produk, memperbarui hanya lokasi+token lokasi, lalu layout secara atomik.
Stok/harga tidak ikut payload lokasi. Write stok produk menjaga lokasi yang telah diberi token Monitor.
Konflik layout tetap pending, tidak memblokir antrean produk/nota POS.
Tombol Periksa cloud membedakan belum aktif, gagal, pending, dan read berhasil;
memuat versi cloud dengan membuang perubahan lokal perlu konfirmasi eksplisit.

Validasi 20 November: analyzer bersih, 268 test Flutter + 12 test Node lulus.
APK debug cloud-first + Monitor (dengan editor fullscreen dan etalase) berhasil dibangun (137 detik).
Render fisik Android serta transaksi Firestore nyata layout belum diverifikasi.
Bagian berikut tetap target implementasi; bukan klaim semua tahap selesai.

## 1. Tujuan dan keputusan

Monitor membantu pemilik menemukan produk yang menipis/habis menurut lokasi
utama pada tampilan toko isometrik ringan. Bukan denah arsitektur presisi,
perhitungan fisik per rak, deteksi kamera, atau sistem restok otomatis.

Keputusan yang sudah disetujui:

- Khusus **pemilik**, masuk melalui tombol **Monitor** di Beranda pemilik.
  Halaman baru, bukan tab baru. Navbar yang ada dan alur kasir tidak berubah.
- **Isometrik 2.5D Flutter native**, sudut pandang tetap dari atas agak miring.
  Tanpa mesin 3D, WebView, dependensi baru, atau kamera yang diputar bebas.
- Mulai dari template yang bisa diedit; tidak wajib menggambar dari kanvas kosong.
- Tiga template: **Rak dinding**, **Dua baris rak**, **Rak dinding + tengah**.
- Dua mode terpisah: **Pantau** sebagai bawaan, **Edit tata letak** untuk perubahan.
- Satu lokasi utama per produk. Produk tanpa penempatan tetap bisa dijual.
- Rak, kulkas, dan meja kasir sebagai jenis objek awal. Meja kasir hanya penanda
  ruang pada versi pertama; produk ditempatkan pada rak/kulkas.
- Tanpa login/PIN baru. Peran Pengaturan adalah mode aplikasi, bukan keamanan cloud.

## 2. Mengapa template + editor sederhana

| Pilihan | Manfaat | Batas |
|---|---|---|
| Denah tetap | Cepat dibuka | Bisa tidak sesuai toko dan tidak mengikuti perubahan |
| Kanvas kosong | Fleksibel | Beban setup tinggi sebelum owner mendapat manfaat |
| Template + editor | Cepat dimulai dan bisa disesuaikan | Perlu editor terbatas dan konfirmasi penempatan |

Pilihan ketiga dipakai. Setup bukan syarat penggunaan kasir, laporan, atau katalog.
Tidak meminta ukuran meter, jumlah tingkat rak, atau pengukuran fisik ruangan.

## 3. Alur halaman

### Pertama kali

1. Tombol Monitor membuka pengantar **Atur tata letak toko**, bukan toko terisi
   otomatis. Pilih template melalui preview yang dapat dibaca dan dipilih.
2. Sesuaikan nama/posisi objek bila perlu, lalu tempatkan produk. Owner memilih
   rak/kulkas dan mencentang beberapa produk, dengan pencarian/filter kategori.
   Saran berdasarkan `locationLabel`/kategori tidak diterapkan tanpa konfirmasi.
3. Simpan layout. Penempatan produk boleh ditunda; produk tersisa ditampilkan
   pada daftar **Belum ditempatkan**. Template yang dipilih sebelum simpan tetap draft.

Mengubah template setelah setup termasuk operasi edit yang mengganti susunan;
perlu konfirmasi dan review penempatan. Jangan otomatis memetakan produk ke
objek baru hanya karena nama raknya sama.

### Pantau

- Header Monitor, aksi Edit tata letak, muat ulang, dan kontrol kembali.
- Ringkasan jumlah **jenis produk** habis, menipis, dan belum ditempatkan.
- Kanvas dengan objek netral, label nama, serta badge peringatan ikon + teks.
- Pan, pinch zoom, tombol zoom/reset agar tidak bergantung pada gesture saja.
- Tekan objek untuk membuka produk di dalamnya. Tekan alert untuk memilih objek
  dan membawanya ke area terlihat. Alert produk tanpa lokasi membuka daftar belum
  ditempatkan, tidak menunjuk rak rekaan.
- Sediakan tampilan daftar lokasi yang setara untuk aksesibilitas dan saat kanvas
  sulit dipakai. Angka/status di daftar sama dengan kanvas.

### Edit

- Bekerja pada salinan draft. Pantau tidak menggeser objek secara tidak sengaja.
- Tambah, nama, geser dengan snap grid, rotasi 90°, dan hapus objek.
- Validasi nama tidak kosong, ID unik, posisi dalam area, ukuran positif, dan
  objek tidak bertumpuk. Rotasi menghitung ulang footprint. Tidak perlu resize
  bebas; ukuran footprint berasal dari jenis objek pada versi awal.
- Kontrol pindah per langkah/grid tersedia selain drag, dengan target sentuh 48 dp.
- Simpan menerapkan perubahan; Batal mengembalikan layout tersimpan.
- Kembali dengan draft berubah menawarkan Simpan, Buang perubahan, atau Tetap edit.
  Kegagalan simpan mempertahankan draft dan menyediakan Coba lagi.
- Peran diperiksa saat masuk dan sebelum simpan. Jika berubah menjadi kasir,
  blokir penyimpanan/perubahan berikutnya dan keluar dari halaman khusus owner.

## 4. Makna stok dan penempatan

Sumber stok tetap `ProductRepository`, bukan angka pada objek layout:

| Kondisi produk | Status |
|---|---|
| `stock == 0` | Habis |
| `0 < stock <= lowStockThreshold` | Menipis |
| `stock > lowStockThreshold` | Tersedia |

Nilai stok tidak valid tidak dianggap stok sehat; tampilkan error data sesuai
validasi repository. Pada objek dengan beberapa produk, habis diprioritaskan
sebagai peringatan terberat, tetapi jumlah jenis menipis dan habis tetap terpisah.
Objek kosong berlabel belum berisi produk, bukan stok aman. Produk belum
terpetakan tetap ikut ringkasan global; tidak dihitung dua kali pada beberapa rak.

Contoh: **Rak Minuman — 8 jenis produk · 2 menipis · 1 habis**. Detail menampilkan
stok per produk beserta satuannya. Jangan menjumlah botol, kilogram, dan sachet
menjadi satu angka stok rak. UI tidak memuat label demo/sintetis pada data impor.

Aturan mutasi:

- Memindahkan objek atau penempatan produk tidak mengubah `stock`.
- Menghapus rak/kulkas melepas penempatan, bukan menghapus produk atau nota.
- Mengganti nama objek memperbarui keterangan lokasi produk terkait saat simpan.
- Produk dihapus dari katalog otomatis hilang dari daftar Monitor melalui revisi
  repository; tidak dihidupkan kembali oleh draft lama.
- ID objek yang tidak ditemukan diperlakukan sebagai belum ditempatkan dengan
  tindakan penataan ulang, bukan diam-diam ditempatkan menurut nama kategori.
- Transaksi baru memperbarui stok/ringkasan tanpa mengubah layout. Perubahan stok
  yang datang saat owner mengedit tidak dimasukkan ke salinan draft lokasi.

Satu produk bisa secara fisik ada di beberapa tempat, tetapi versi ini hanya
menyimpan lokasi utama. Angka stok adalah total tercatat produk, **bukan jumlah
fisik yang dijamin berada pada rak yang dipilih**. Batas ini dijelaskan singkat
pada bantuan Monitor, bukan klaim pemantauan fisik otomatis.

## 5. Arsitektur dan persistensi yang diusulkan

**Model dan repository layout lokal tahap 1 tersedia; layout cloud belum aktif.**
Migrasi SQLite menambah `monitor_layouts` tanpa mengubah tabel POS. Bentuk payload
cloud, perubahan penempatan, dan revisi server harus ditinjau sebelum tahap data cloud.

### Integrasi yang sudah tersedia

- `ProductRecord`: `fixtureId`, `locationLabel`, `stock`, `lowStockThreshold`.
- `AppSession` dan `dataRevision`: pembacaan peran dan invalidasi lintas fitur.
- SQLite/Drift, outbox, serta `CloudReadThrough`: fondasi native yang sudah ada.
- `floor_plan` arsip memiliki model/gesture/editor awal, tetapi ViewModel saat ini
  dimulai dari `FloorPlanSample`. Ini kandidat audit, bukan layar siap diaktifkan.
  Tidak menggunakan ulang jumlah produk, status sync, atau sheet contoh sebagai data nyata.

### Pembagian tanggung jawab

- Fitur `monitor/` yang direncanakan: model layout/objek dan satu `ChangeNotifier`
  untuk mode, pilihan, draft, validasi, serta agregasi tampilan.
- Repository layout di `core/data/`: load/save dan migrasi native. Stok tidak masuk
  dokumen layout. Draft edit berada dalam memori pada versi awal; tidak menjanjikan
  pemulihan draft setelah proses dimatikan. Layout tersimpan tetap harus bertahan.
- Renderer kandidat: `CustomPainter` untuk bidang isometrik dan depth ordering;
  `InteractiveViewer` untuk transform pan/zoom, overlay widget untuk label/kontrol.
  Hit-test membalik transform viewport dan proyeksi, memilih objek teratas yang
  terlihat. Semantik dan daftar alternatif tidak bergantung pada painter saja.
- Bentuk layout minimum: versi skema, ID layout, ukuran grid, daftar objek dengan
  ID/jenis/nama/posisi/rotasi, dan revisi layout. Koordinat logis, bukan piksel layar.
- `fixtureId` produk menjadi hubungan lokasi utama; `locationLabel` teks pendamping.
  Produk impor yang `fixtureId` kosong tidak ditempatkan otomatis.

### Kontrak simpan yang wajib diputuskan sebelum kode data

1. Satu penyimpanan layout + perubahan penempatan harus atomik di SQLite, lalu
   mempunyai operasi outbox yang dapat diulang tanpa mengubah stok/harga produk.
   Outbox saat ini hanya mengenal produk/nota; perlu perluasan teruji untuk layout.
2. Usulan cloud: `stores/{storeId}/layouts/main` untuk satu layout toko; **belum
   koleksi terpasang**. Penempatan tetap pada produk, bukan salinan stok di layout.
3. Payload penempatan hanya mengubah bidang lokasi; jangan mengirim ulang snapshot
   harga/stok lama dari saat draft dibuka. Integrasi dengan antrean produk yang
   sudah ada wajib menjaga perubahan kasir yang masih tertunda.
4. Periksa revisi layout saat save cloud. Konflik edit dua perangkat tidak boleh
   diam-diam menimpa layout lain; tampilkan pilihan muat ulang setelah draft diamankan.
5. Penghapusan objek dan pelepasan produk harus konsisten. Target satu save cloud
   atomik dengan precondition/revisi. Jika jumlah write melewati batas Firestore,
   blokir simpan dengan penjelasan dan pecah perubahan secara eksplisit; jangan
   melaporkan sukses untuk batch parsial. Batas operasional perlu diuji pada fase data.
6. Cloud read-through harus membaca layout beserta perlindungan pending tanpa
   membuang cache pada kegagalan. Tidak membuka rules publik atau menambah auth
   tanpa persetujuan. Keberhasilan lokal ditulis sebagai tersimpan lokal bila
   belum ada konfirmasi cloud; bukan status tersinkron palsu.

Bila kontrak atomik/revisi ini tidak dapat dipenuhi dengan fondasi saat ini,
review desain data dahulu. Jangan menyederhanakan dengan mengorbankan stok,
penempatan, data lama, atau kejujuran status.

## 6. Layout, aksesibilitas, dan performa

- Ponsel: kanvas utama, detail bottom sheet. Tablet landscape: kanvas dan panel
  samping jika lebar cukup; pemilihan berdasarkan constraints, bukan nama perangkat.
- Aman pada lebar 360 dp, text scale 1.3, target sentuh minimal 48 dp. Badge tidak
  menutup rak tetangga; label panjang membungkus pada daftar/detail.
- Semua objek punya semantic label: jenis, nama, jumlah jenis produk, jumlah
  menipis/habis. Fokus dan pilihan pada kanvas konsisten dengan tampilan daftar.
- Violet untuk aksi/pilihan, permukaan pasif netral. Warning/error memakai token
  dan teks/ikon. Tidak hanya warna; reduced motion menghilangkan transisi opsional.
- Tidak ada animasi/polling per rak. Agregasi memakai data repository/revisi yang
  tersedia; repaint hanya saat layout, pilihan, transform, atau stok berubah.
- Benchmark pada Android kelas bawah/HP yang tersedia dan tablet: interaksi tidak
  tersendat, tidak overflow, dan pengelolaan lifecycle tidak membocorkan listener.
  Batas jumlah objek ditetapkan dari hasil benchmark, bukan klaim tanpa pengujian.

## 7. Urutan implementasi dan keluaran

| Tahap | Hasil | Syarat sebelum lanjut |
|---|---|---|
| 0 — Audit & kontrak data | Audit arsip, keputusan skema/migrasi/revisi/outbox, ownership PR | Kontrak penempatan tidak menimpa stok; persetujuan scope implementasi |
| 1 — Model & persistensi | Layout kosong, tiga template, validasi grid, simpan/baca SQLite | Migrasi aman, save/cancel, uji restart dan rollback |
| 2 — Editor & penempatan | Setup dua langkah, bulk assign, tambah/pindah/rotasi/hapus | Draft/keluar aman, konflik peran, produk tidak terhapus |
| 3 — Pantau isometrik | Kanvas, hit-test, pan/zoom/reset, detail dan daftar setara | Pemilihan benar pada overlap/zoom; semantik dan layout adaptif |
| 4 — Stok & cloud | Alert dari repository, revisi UI, layout cloud/outbox/conflict handling | Transaksi baru tetap benar, offline/retry, tanpa echo sync |
| 5 — Integrasi owner | Tombol/rute terjaga, regresi seluruh fitur, APK perangkat | Analyzer/test lulus, Android/tablet diverifikasi, review PR |

Tahap 1–4 boleh dikembangkan sebagai potongan teruji, tetapi tidak ditampilkan
sebagai fitur lengkap sebelum data dan penempatan konsisten. Tidak menambah tab
atau mengganti navbar. Commit/push hanya atas permintaan tugas aktif.

Usulan koordinasi mengikuti `TEAM.md`: Farel untuk spasial/aksesibilitas, Tariq
untuk routing/fondasi bersama, Blessly untuk review penempatan dan regresi kasir.
Ini usulan pembagian tugas, bukan pemindahan kepemilikan permanen.

## 8. Kriteria penerimaan

- Owner baru bisa memilih template, menyimpan, membuka ulang, dan melanjutkan
  penempatan yang belum selesai; kasir tidak wajib setup.
- Drag tidak berjalan di Pantau. Rotasi/move menjaga posisi valid; Batal tidak
  mengubah layout tersimpan; save gagal mempertahankan draft.
- Bulk assign tidak menggandakan produk. Hapus lokasi tidak menghapus barang,
  nota, atau stok. Produk dihapus selama edit tidak muncul kembali saat save.
- Checkout pada produk terpetakan mengurangi stok sekali dan memperbarui alert;
  membuka Monitor tidak membuat transaksi/outbox stok baru.
- Offline memakai cache dan status jujur; data belum pernah dimuat tidak dianggap
  semua rak kosong/aman. Error mempunyai retry tanpa mengganti angka dengan nol.
- Layout/penempatan terpending tidak ditimpa hasil cloud; konflik dua editor
  ditangani tanpa lost update. Migrasi/ulang sync tidak menggandakan objek.
- Tes unit geometri/transform/grid/agregasi/validasi, repository/migrasi/outbox,
  widget setup/edit/owner guard, serta regresi POS dan impor wajib tersedia.
- Uji 360 dp dan tablet portrait/landscape, text scale 1.3, TalkBack, reduced motion,
  lifecycle, data banyak, dan kegagalan jaringan di perangkat Android.
- Jalankan `flutter analyze`, seluruh `flutter test`, dan test Node impor sebagai
  regresi data. Catat hasil nyata; pengujian lama bukan bukti Monitor sudah lolos.

## 9. Di luar versi pertama

3D penuh, rotasi kamera bebas, panorama, ukuran meter, beberapa lantai,
slot/tingkat rak per produk, stok fisik per lokasi, sensor/deteksi otomatis,
prediksi restok, notifikasi background/push, dan editor kolaboratif real-time.
Tidak menambah dependensi, layanan, model AI, atau perubahan autentikasi.

## 10. Kondisi dasar saat rencana ditulis

Kode cloud-first terakhir `a85a159` sudah dipush. Validasi sebelumnya: analyzer
bersih, 240 test Flutter dan 12 test Node lulus. Impor Firestore terverifikasi
90 dokumen: 24 produk dan 66 nota tunai, 394 unit, Rp3.035.800, 10–24 November
2026 inklusif. Tanpa label visual, dengan metadata asal internal.

APK cloud-first belum dibangun/dipasang; unduh cloud pada aplikasi nyata belum
terverifikasi. Akses baca publik HTTP 200 masih diketahui; rules tidak diubah.
Stok lintas perangkat masih last-write-wins, bukan atomik; snapshot koleksi/page
tidak atomik, pembacaan maksimal 10.000 dokumen per koleksi. Rencana Monitor
bukan perbaikan otomatis atas batas-batas ini dan bukan bukti siap produksi.
