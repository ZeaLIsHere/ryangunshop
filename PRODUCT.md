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

Pengalaman pengguna RyanGunshop dibangun di atas alur operasional kasir warung yang cepat dan efisien:

1. **Pembuka dan Orientasi:**
   Splash screen menyajikan animasi logo 3D RyanGunshop berdurasi 1,45 detik menuju Beranda (atau onboarding
   tiga langkah pengenalan visual dengan bahasa persuasif-santai: Kasir Sat-set, Bayar Bebas Tunai/QRIS, dan
   Pantau Cuan & Stok Real-Time).
2. **Beranda Operasional POS:**
   Dashboard utama berpusat pada perputaran kasir harian: kartu Hero Omzet dinamis bergradien violet yang
   menampilkan omzet hari ini, jumlah nota, dan rata-rata transaksi; kartu cetak laporan harian Bluetooth;
   4 modul bento Aksi Cepat (`Pindai Barcode`, `Buka Kasir`, `Stok`, `Riwayat Nota`); serta daftar riwayat
   aktivitas transaksi terkini dengan jam transaksi, nominal rupiah, dan wadah placeholder foto produk.
3. **Transaksi dan Kasir:**
   Alur kasir dirancang tanpa friksi:
   - kasir melihat total belanja, kuantitas item, serta pod aksi cepat (Tambah Menu, Keranjang, Voucher/Diskon);
   - daftar belanja menampilkan nama produk, harga satuan, penanda SKU, dan kontrol kuantitas (+ / -);
   - panel ringkasan biaya menghitung subtotal, diskon toko, pajak PB1 (0% UMKM), dan total bayar;
   - tombol utama memicu sheet pembayaran dan pencatatan transaksi langsung ke memori sesi lokal.
4. **Metode Pembayaran (Tunai & QRIS):**
   - Tunai menyediakan chip nominal cepat `Uang Pas` dan pecahan besar, serta menghitung uang kembalian
     secara otomatis dengan indikator warna mint green;
   - QRIS dinamis siap integrasi payment gateway dengan status simulasi terstruktur;
   - transaksi tunai lunas otomatis tersimpan ke riwayat nota, mengupdate omzet Beranda, dan mengosongkan keranjang;
   - layar ringkasan struk sukses menyediakan opsi cetak struk via printer thermal Bluetooth.
5. **Katalog Produk dan Manajemen Stok:**
   Pencarian teks instan, filter kategori, pengurutan cerdas, filter cepat stok menipis, serta formulir
   tambah/edit produk mobile yang mudah tanpa ketergantungan denah.
6. **Pemindai Barcode Produk:**
   Antarmuka pemindaian barcode dengan bingkai bidik kamera simulasi/nyata, saklar lampu senter, serta jalan
   keluar pencarian manual instan bila barcode rusak.
7. **Laporan, Analitik & Asisten AI:**
   Riwayat transaksi nota harian, statistik analitik penjualan dan margin laba kotor, serta asisten AI IyanBoT
   untuk menjawab pertanyaan stok dan operasional warung.

## Personality

Praktis, tenang, jelas, dan dapat dipercaya—seperti alat kerja warung modern yang
rapi. Visual bergaya modern violet commerce (`#7C3AED` dan `#6D28D9`) dengan aksen
pastel yang hangat dan aset ikon 3D claymorphic seragam.

## Design Principles

1. Kasir cepat dan minim langkah: Beranda dan kasir memprioritaskan kecepatan input dan konfirmasi transaksi.
2. Data nyata atau status jujur: jangan menampilkan pembayaran berhasil atau angka usaha palsu.
3. Transaksi tersimpan instan: setiap pembayaran lunas langsung tercatat dan memperbarui statistik omzet lokal.
4. Offline-first: aplikasi tetap dapat digunakan penuh saat sinyal internet terputus.
5. Aksesibel di perangkat kecil: target sentuh minimal 48 dp, teks inti minimal 14 sp, dan aman pada text scale 1.3 dan lebar 360 dp.

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
