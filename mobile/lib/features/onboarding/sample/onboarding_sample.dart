import 'package:flutter/material.dart';

import '../model/onboarding_page.dart';

/// Isi perkenalan tiga halaman.
///
/// Ilustrasi memakai ikon sebagai bentuk geometris sederhana, sehingga tidak
/// memerlukan berkas gambar.
abstract final class OnboardingSample {
  static const List<OnboardingPage> pages = <OnboardingPage>[
    OnboardingPage(
      title: 'Pindai produk',
      description:
          'Arahkan kamera ke barcode, lalu konfirmasi barang yang terdeteksi.',
      icon: Icons.qr_code_scanner,
    ),
    OnboardingPage(
      title: 'Atur tata letak',
      description: 'Susun rak, lemari, dan kulkas pada denah agar barang mudah ditemukan.',
      icon: Icons.grid_view,
    ),
    OnboardingPage(
      title: 'Bayar dengan tenang',
      description: 'Periksa keranjang, lalu pilih pembayaran tunai atau QRIS.',
      icon: Icons.point_of_sale,
    ),
  ];
}
