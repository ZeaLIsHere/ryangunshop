# RyanGunshop — Konteks Produk

Status berjalan: **15 November 2026**, branch `feat/ui-shell-owner-barcode`.

## Produk dan pengguna

RyanGunshop adalah aplikasi kasir dan pengelolaan warung berbasis Flutter/Dart
untuk Android 8.0 ke atas (API 26). POS bersifat offline-first: produk, stok,
draft keranjang, dan nota tunai tersimpan di SQLite/Drift. Database baru dimulai
kosong; data pratinjau bukan data usaha.

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
3. **Beranda pemilik.** Penjualan Bersih, jumlah nota, rata-rata, grafik harian,
   perhatian stok saat ini, produk terlaris, nota periode, dan aksi kelola.
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
8. **Laporan.** PDF dan XLSX harian dari transaksi repository, dibagikan lewat
   Android, bukan otomatis masuk Downloads. Tidak mengklaim laba historis
   karena harga modal belum disnapshot pada transaksi. Cetak fisik belum
   terverifikasi, termasuk label dan printer struk.
9. **IyanBoT.** Integrasi Groq memakai tool baca serta draft transaksi/produk.
   LLM tidak langsung menulis: pengguna harus mengonfirmasi draft sebelum
   repository menyimpan. Draft produk hanya untuk pemilik. Uji API langsung
   belum terverifikasi; kelanjutan pengujian dijeda atas permintaan pengguna.

## Cloud dan batas keamanan

Firebase native sudah dikonfigurasi dan diaktifkan lewat `FIREBASE_ENABLED` pada
build yang memakai konfigurasi privat. Outbox SQLite menampung perubahan produk
dan transaksi yang dicatat saat jalur sinkronisasi aktif. Pengurasan dijalankan
saat startup, perubahan sesi, serta berkala 15 detik selama aplikasi berjalan;
bukan layanan latar belakang Android.

Inisialisasi SDK bukan bukti dokumen sudah terunggah. Produk yang sudah ada
sebelum outbox aktif tidak otomatis di-backfill. Sinkronisasi cloud langsung,
pemulihan perangkat baru, autentikasi, dan isolasi tenant belum terverifikasi.
Pratinjau web tidak memakai SQLite atau sinkronisasi native.

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

Validasi terakhir yang dilaporkan: analyzer bersih, 212 test lulus; APK debug
berhasil dibangun sekitar 51 detik, dipasang ulang dengan `adb install -r`, dan
diluncurkan pada Samsung SM_A366B tanggal 15 November 2026 tanpa menghapus data.
Pemasangan/peluncuran bukan audit visual atau uji alur penuh. Pemindaian fisik,
cetak label/struk, live cloud, dan live Groq belum terverifikasi.

Prioritas berikutnya: verifikasi UI/alur Android nyata, cetak dan pindai label,
bukti unggah outbox serta strategi backfill, autentikasi/hak akses produksi,
kemudian pemulihan cloud dan QRIS resmi. Restok prediktif, snapshot modal untuk
laba historis, foto koreksi privat, TFLite, serta WhatsApp/Ollama `backend-agent`
masih pengembangan berikutnya, bukan fitur produksi yang dijanjikan.
