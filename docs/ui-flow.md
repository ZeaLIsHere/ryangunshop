# Alur UI katalog dan kasir

Pemilik: Blessly Victory Deo Silaban. Lingkup implementasi saat ini mencakup seluruh alur UI
katalog, formulir produk, pemindai barcode/produk, keranjang, hingga pratinjau pembayaran.
Seluruh harga, stok, lokasi, dan status pembayaran menggunakan data contoh lokal sesuai
batasan tahap antarmuka.

## Alur kerja utama

```text
Katalog/Pemindai ──> Konfirmasi Produk ──> Keranjang (CartCheckout) ──> Sheet Pembayaran ──> Status Berhasil
```

1. **Eksplorasi Katalog:** Kasir atau pemilik dapat mencari produk lewat input teks,
   menyaring kategori, melihat peringatan stok menipis, atau mengurutkan berdasarkan nama,
   harga, dan stok.
2. **Tambah dan Edit Produk (`ProductFormScreen`):** Formulir satu kolom bertahap mencakup
   pratinjau foto, nama & SKU/barcode, harga jual/modal, stok awal, serta kategori.
   Dilengkapi validasi inline untuk barcode ganda dan angka negatif.
3. **Pemindaian (`ProductScannerScreen`):** Simulasi pemindai kamera dengan area bidik,
   kontrol senter/flash, tombol simulasi deteksi, serta opsi pencarian manual ketika
   kamera tidak diizinkan atau produk tidak terdeteksi. Hasil pemindaian wajib dikonfirmasi
   sebelum dimasukkan ke keranjang.
4. **Keranjang Belanja (`CartCheckoutScreen`):** Penyesuaian kuantitas produk dengan stepper,
   ringkasan subtotal & total sticky di bawah, serta pembersihan keranjang.
5. **Pembayaran (`PaymentSheet`):** Memisahkan alur Tunai (pilihan uang pas, uang cepat,
   dan hitung kembalian instan) serta QRIS (simulasi siklus `creating`, `awaitingPayment`,
   `paid`, `expired`, dan `failed`).
6. **Bukti Transaksi (`PaymentSuccessScreen`):** Menampilkan rincian transaksi contoh dengan
   penandaan jelas bahwa data dan pencatatan kasir bersifat simulasi.

## Yang sudah tersedia

- `ProductCatalog`: daftar produk, filter kategori, pencarian kata kunci, indikator stok
  (aman, menipis, habis), serta `SampleBadge`.
- Pemilih skenario di katalog: daftar contoh, memuat, kosong, gagal, dan offline.
- `ProductFormScreen`: penambahan produk baru dan pengeditan produk yang sudah ada, dengan
  validasi nomor, barcode, dan kategori produk.
- `ProductScannerScreen`: pemindai simulasi dengan state siap, mendeteksi, hasil terdeteksi,
  izin kamera ditolak, dan konfirmasi produk langsung ke keranjang.
- `ManualProductSearchScreen`: pencarian manual sebagai jalan keluar saat pemindai kamera
  tidak dapat digunakan.
- `CartCheckoutScreen`: daftar belanja dinamis, penyesuaian kuantitas, dan penghitungan total.
- `PaymentSheet` & `PaymentSuccessScreen`: simulasi tunai dan QRIS dinamis lengkap dengan
  tampilan kembalian, batas waktu QR, pencatatan otomatis transaksi ke sesi lokal,
  dan opsi cetak struk via printer Bluetooth.

## Status alur bertahap

| Fase | Alur | Status |
|---|---|---|
| 0 | Buka katalog → lihat harga dan stok contoh | Selesai (terintegrasi ke app shell) |
| 1 | Katalog → cari/filter stok menipis → urutkan → tambah produk | Selesai (fitur pencarian, filter, dan sorting) |
| 2 | Formulir → foto contoh, identitas, harga/stok, kategori → validasi inline | Selesai (`ProductFormScreen` & `ProductDetailSheet`) |
| 3 | Mulai pindai → hasil simulasi → konfirmasi eksplisit → pencarian manual | Selesai (`ProductScannerScreen` & `ManualProductSearchScreen`) |
| 4 | Konfirmasi produk → `CartCheckout` → pembayaran tunai/QRIS → simpan sesi & struk | Selesai (`CartCheckout`, `PaymentSheet`, `PaymentSuccessScreen`) |
| 5 | Uji alur pada Android layar kecil (360 dp) & rilis internal | Selesai / Review (teruji pada pengujian widget & manual) |

## Makna state pembayaran

| State QRIS | Makna tampilan yang direncanakan |
|---|---|
| `creating` | Menyiapkan QR contoh |
| `awaitingPayment` | Menunggu pembayaran dalam simulasi |
| `paid` | Contoh tampilan pembayaran diterima; bukan transaksi nyata |
| `expired` | QR contoh kedaluwarsa, menyediakan tindakan buat ulang |
| `failed` | Simulasi gagal, menyediakan coba lagi atau beralih ke tunai |

## Pemeriksaan kualitas

Jalankan dari folder `mobile/`:

```bash
flutter analyze
flutter test
```

Cakupan pengujian mencakup verifikasi layar kecil (lebar 360 dp), pembesaran teks (text scale 1.3),
target sentuh minimal 48 dp, pemulihan dari state gagal/kosong, dan kepatuhan prinsip data jujur.
