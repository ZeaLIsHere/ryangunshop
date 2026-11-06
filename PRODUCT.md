# RyanGunshop — Product Context

## Product

RyanGunshop adalah aplikasi kasir dan pengelolaan warung berbasis Flutter untuk
Android 8.0 ke atas. Produk bersifat offline-first: aktivitas kasir dan perubahan
stok tetap dapat berjalan melalui SQLite/Drift, kemudian disinkronkan ke
Firestore saat jaringan tersedia.

## Users

- Pemilik warung yang mengatur produk, tata letak, stok, laporan, merchant QRIS,
  serta akses kasir.
- Kasir yang harus menemukan, memindai, mengonfirmasi, dan menjual barang dengan
  sedikit langkah.

Pengguna bisa memakai perangkat kelas bawah dan tidak selalu memiliki koneksi
internet yang stabil. Antarmuka utama harus dapat dipahami tanpa pelatihan
teknis.

## Core Experience

Pengalaman pengguna RyanGunshop dibangun di atas alur operasional warung yang efisien:

1. **Pembuka dan Orientasi:**
   Splash screen menyajikan animasi logo berdurasi 1,45 detik menuju dashboard (atau onboarding
   tiga langkah pengenalan visual bagi pengguna baru yang dapat dilewati dan mendukung reduced motion).
2. **Denah dan Tata Letak Ruang:**
   Dashboard merepresentasikan tata letak fisik warung melalui template kanvas 2D interaktif (dinding,
   lorong, rak, lemari, kulkas, dan meja kasir). Denah berfungsi sebagai alat navigasi operasional:
   memilih suatu objek akan menampilkan barang dan ketersediaan stok di lokasi tersebut. Hasil scan
   produk dapat menyorot lokasi raknya secara instan.
3. **Mode Edit Denah Khusus Pemilik:**
   Pemilik warung dapat menambah, memindahkan (drag), memutar, mengubah ukuran, menduplikasi, memberi
   nama, dan menghapus objek ruang pada denah, dengan batas kanvas yang aman dan proteksi terhadap
   sentuhan kasir yang tidak sengaja.
4. **Viewer Panorama 360 Derajat:**
   Sebagai pendukung visualisasi spasial, denah terhubung ke foto panorama 360° per zona warung,
   memberikan gambaran nyata kondisi rak tanpa membebani performa perangkat kelas bawah.
5. **Katalog Produk dan Pencarian:**
   Pencarian teks instan, filter kategori, pengurutan, peringatan stok menipis, serta formulir produk
   mobile satu kolom dengan validasi kode batang dan penempatan rak warung.
6. **Pemindai Produk & Pencarian Manual:**
   Kamera layar penuh dengan bingkai bidik terarah dan konfirmasi eksplisit sebelum barang masuk
   keranjang, dilengkapi jalan keluar pencarian manual jika kamera atau barcode bermasalah.
7. **Transaksi dan Kasir:**
   Alur pembayaran dimulai setelah barang dikonfirmasi dan masuk ke keranjang:
   - aplikasi menghitung total belanja dari harga lokal yang tersimpan;
   - kasir memilih metode tunai atau QRIS;
   - tunai menyediakan opsi uang pas/cepat serta menghitung uang kembalian secara otomatis;
   - QRIS dinamis dibuat oleh payment gateway untuk nominal transaksi dan merchant yang terdaftar;
   - transaksi QRIS baru dianggap berhasil setelah webhook provider tervalidasi;
   - penyimpanan transaksi dan pengurangan stok dilakukan secara atomik.
8. **Pengaturan Peran dan Laporan:**
   Pemisahan hak akses antara Pemilik dan Kasir, serta ringkasan riwayat transaksi harian/mingguan
   untuk memantau perputaran omzet warung.

## Personality

Praktis, tenang, jelas, dan dapat dipercaya—seperti alat kerja warung yang
rapi. Visual tidak boleh terasa seperti aplikasi finansial korporat atau gim 3D.
Slate blue menjadi identitas utama untuk tindakan dan navigasi, didampingi
netral dingin agar denah mudah dibaca dalam kondisi warung yang terang.

## Design Principles

1. Denah dahulu, transaksi tetap dekat: dashboard fokus pada ruang, tetapi aksi
   pindai dan keranjang selalu mudah dijangkau.
2. Data nyata atau status jujur: jangan menampilkan pembayaran berhasil,
   ketersediaan stok, atau angka usaha yang belum dikonfirmasi sumber data.
3. Edit dan operasi adalah mode berbeda: objek tidak boleh bergeser saat kasir
   hanya ingin memilih rak.
4. Offline terlihat jelas: status sinkronisasi dan tindakan yang memerlukan
   internet harus mempunyai penjelasan dan retry.
5. Aksesibel di perangkat kecil: target sentuh minimal 48 dp, teks inti minimal
   14 sp, kontras memadai, dan makna tidak bergantung pada warna saja.

## Technical Boundaries

- Flutter/Dart untuk aplikasi Android; tidak memakai Jetpack Compose.
- Preview dan inspeksi UI dilakukan lewat Flutter extension di VS Code pada
  emulator atau perangkat Android.
- Denah MVP menggunakan koordinat relatif 2D agar responsif dan hemat resource.
- Panorama 360 memerlukan foto equirectangular per zona; digital twin 3D penuh
  bukan bagian MVP.
- QRIS dinamis memerlukan akun merchant dan API payment gateway resmi. Rahasia,
  pembuatan charge, signature, serta webhook tidak boleh berada di aplikasi.
- Tenant selalu ditentukan dari sesi/claim `storeId`, bukan input bebas pengguna.
