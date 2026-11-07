import 'package:flutter/material.dart';

/// Pintasan ringkas pada dashboard.
///
/// Nilai enum ini tidak menyebut tab secara langsung supaya fitur dashboard tetap
/// tidak bergantung pada susunan navigasi aplikasi.
enum DashboardShortcut {
  catalog(
    label: 'Katalog produk',
    description: 'Cari barang dan periksa stok',
    icon: Icons.inventory_2_outlined,
    assetPath: 'assets/icon/01_katalog_produk.png',
  ),
  cashier(
    label: 'Keranjang',
    description: 'Periksa barang lalu bayar',
    icon: Icons.point_of_sale_outlined,
    assetPath: 'assets/icon/02_keranjang.png',
  ),
  reports(
    label: 'Riwayat transaksi',
    description: 'Lihat transaksi yang sudah selesai',
    icon: Icons.receipt_long_outlined,
    assetPath: 'assets/icon/03_riwayat_transaksi.png',
  ),
  settings(
    label: 'Pengaturan',
    description: 'Peran pengguna dan info warung',
    icon: Icons.settings_outlined,
    assetPath: 'assets/icon/04_pengaturan.png',
  ),
  statistics(
    label: 'Statistik',
    description: 'Ringkasan penjualan dan stok',
    icon: Icons.insights_outlined,
    assetPath: 'assets/icon/05_statistik.png',
  ),
  chatbot(
    label: 'Chatbot',
    description: 'Tanya bantuan lewat percakapan',
    icon: Icons.chat_bubble_outline,
    assetPath: 'assets/icon/06_chatbot.png',
  );

  const DashboardShortcut({
    required this.label,
    required this.description,
    required this.icon,
    required this.assetPath,
  });

  final String label;
  final String description;
  final IconData icon;
  final String assetPath;
}
