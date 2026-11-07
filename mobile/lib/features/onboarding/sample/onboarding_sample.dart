import 'package:flutter/material.dart';

import '../model/onboarding_page.dart';

/// Isi perkenalan tiga halaman.
///
/// Ilustrasi memakai ikon sebagai bentuk geometris sederhana, sehingga tidak
/// memerlukan berkas gambar.
abstract final class OnboardingSample {
  static const List<OnboardingPage> pages = <OnboardingPage>[
    OnboardingPage(
      title: 'Kasir Sat-Set, Anti Ribet',
      description: 'Tinggal scan barcode atau pilih barang di katalog. Hitung total, diskon, dan kembalian seketika tanpa pusing kalkulator!',
      icon: Icons.point_of_sale_rounded,
      assetPath: 'assets/icon/02_keranjang.png',
    ),
    OnboardingPage(
      title: 'Bayar Bebas, Tunai Maupun QRIS',
      description: 'Mau uang pas, pecahan besar, atau scan QRIS dinamis langsung jadi. Pembeli puas, operasional warung makin lancar!',
      icon: Icons.qr_code_scanner_rounded,
      assetPath: 'assets/icon/08_pindai_barcode.png',
    ),
    OnboardingPage(
      title: 'Pantau Cuan & Stok Real-Time',
      description: 'Omzet harian dan riwayat nota tercatat otomatis dan rapi. Dilengkapi notifikasi stok menipis biar dagangan gak pernah kehabisan!',
      icon: Icons.insights_rounded,
      assetPath: 'assets/icon/05_statistik.png',
    ),
  ];
}
