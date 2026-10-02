# Alur UI katalog dan kasir

Pemilik: Blessly Victory Deo Silaban. Lingkup implementasi saat ini: **Fase 0**,
katalog statis serta model UI keranjang dan pembayaran. Seluruh harga, stok,
lokasi, dan status pembayaran adalah contoh lokal.

## Yang sudah tersedia

- `ProductCatalog`: lima produk contoh, harga rupiah, lokasi, serta stok cukup,
  menipis, dan habis. Setiap kartu memakai `SampleBadge`.
- Pemilih skenario: daftar contoh, memuat, kosong, gagal, dan offline.
- State memuat dapat dihentikan dengan **Tampilkan contoh**. Dengan reduced motion,
  indikator memuat berupa ikon dan teks statis.
- State kosong menyediakan **Tampilkan contoh**; **Coba lagi** pada state gagal
  memulihkan daftar lokal. Tidak ada pemanggilan jaringan.
- State offline mempertahankan daftar contoh dengan keterangan simulasi; tidak
  memeriksa koneksi atau mengklaim sinkronisasi.
- `CartItem`: snapshot nama, harga satuan, kuantitas, satuan, dan subtotal.
- `PaymentPreview`: nominal rupiah bulat, metode tunai/QRIS, uang diterima,
  kembalian bila mencukupi, serta enum status QRIS.

Katalog belum dipasang di tab Produk pada app shell. `mobile/lib/app/**` milik Tariq;
penyambungannya perlu PR dan review bersama. `ProductCatalog` berupa isi layar,
sehingga dapat dipasang langsung sebagai body tanpa app bar tambahan.

## Pratinjau Android melalui VS Code

1. Gunakan Flutter dengan Dart yang memenuhi `mobile/pubspec.yaml` (`^3.13.3`).
2. Buka folder proyek, lalu jalankan `Flutter: Launch Emulator` atau hubungkan
   perangkat Android dan pilih melalui `Flutter: Select Device`.
3. Buka `mobile/lib/features/catalog/sample/catalog_preview.dart`.
4. Klik **Debug** pada CodeLens di atas `main()` melalui ekstensi Dart/Flutter.
   Entrypoint ini membuka katalog secara mandiri. Konfigurasi F5 bawaan proyek
   tetap membuka `lib/main.dart`, yang tab Produknya masih placeholder.
5. Coba kelima pilihan **Skenario contoh**. Gulir daftar sampai produk terakhir.

Pratinjau web bukan bukti validasi UI Android. Entrypoint pratinjau tidak mengubah
routing, sesi, atau konfigurasi bersama.

## Alur yang dikerjakan bertahap

| Fase | Alur | Status |
|---|---|---|
| 0 | Buka katalog → lihat harga, stok, dan lokasi contoh | Tersedia lewat entrypoint pratinjau |
| 1 | Katalog → cari/filter stok menipis → tambah produk | Belum; termasuk CTA tambah pada state kosong dan kerangka `ProductForm` |
| 2 | Formulir → foto, identitas, harga/stok, lokasi → validasi → simpan UI; detail produk | Belum |
| 3 | Mulai pindai → hasil simulasi → konfirmasi eksplisit | Belum; izin ditolak/error harus punya pencarian manual |
| 4 | Konfirmasi produk → `CartCheckout` → tunai atau QRIS → status contoh | Model tersedia; layar dan interaksinya belum |
| 5 | Uji alur pada Android kecil → APK internal | Belum |

Pada fase berikutnya, hasil pindai tidak otomatis masuk keranjang. Kamera dilepas
selama checkout dan disiapkan ulang saat kasir memilih pindai lagi. Pemilihan peran
harus memakai `AppSessionScope`, bukan disalin ke state katalog.

## Makna state pembayaran

| State QRIS | Makna tampilan yang direncanakan |
|---|---|
| `creating` | Menyiapkan QR contoh |
| `awaitingPayment` | Menunggu pembayaran dalam simulasi |
| `paid` | Contoh tampilan pembayaran diterima; bukan transaksi nyata |
| `expired` | QR contoh kedaluwarsa, menyediakan tindakan ulang |
| `failed` | Simulasi gagal, menyediakan coba lagi atau pilih tunai |

Data QRIS contoh mencakup seluruh state untuk pratinjau. Tidak ada QR yang dapat
dibayar, webhook, penyelesaian transaksi, atau pengurangan stok. `change == null`
pada model tunai berarti uang belum diisi atau belum cukup; nol berarti uang pas.

## Pemeriksaan sebelum PR

Jalankan dari `mobile/`:

```bash
flutter analyze
flutter test
```

Pengujian katalog berada di `test/features/catalog/`: state dan pemulihan UI,
lebar 360 dp dengan skala teks 1,3, target sentuh Android dan label kontrol,
reduced motion, batas stok menipis, subtotal, serta kembalian tunai.

Di Android, periksa ulang keterbacaan kartu, gulir, pemilih skenario, TalkBack,
dan tombol pemulihan pada font besar. Catat hasil aktual di PR. Status implementasi
dan batas verifikasi ada pada baris Blessly Fase 0 di `PROGRESS.md`.
