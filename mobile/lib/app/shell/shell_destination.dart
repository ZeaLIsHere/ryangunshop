import 'package:flutter/material.dart';

/// Tab utama pada navigasi bawah.
///
/// Urutan nilai menentukan urutan tab dari kiri ke kanan.
enum ShellDestination {
  floorPlan(
    label: 'Beranda',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront,
    assetPath: 'assets/icon/beranda.png',
    unavailableMessage: 'Halaman beranda belum tersedia.',
  ),
  catalog(
    label: 'Katalog',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    assetPath: 'assets/icon/01_katalog_produk.png',
    unavailableMessage: 'Daftar produk dan status stok belum tersedia.',
  ),
  cashier(
    label: 'Kasir',
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale,
    assetPath: 'assets/icon/02_keranjang.png',
    unavailableMessage: 'Keranjang dan pembayaran belum tersedia.',
  ),
  settings(
    label: 'Pengaturan',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    assetPath: 'assets/icon/04_pengaturan.png',
    unavailableMessage: 'Pengaturan dan peran pengguna belum tersedia.',
  );

  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.assetPath,
    required this.unavailableMessage,
  });

  /// Label tab, sekaligus judul app bar dan label semantik.
  final String label;

  /// Ikon saat tab tidak dipilih.
  final IconData icon;

  /// Ikon saat tab dipilih.
  final IconData selectedIcon;

  /// Path gambar ikon 3D di folder assets/icon.
  final String assetPath;

  /// Keterangan jujur selama isi tab belum dibangun.
  final String unavailableMessage;

  /// Alias tujuan halaman utama (Beranda).
  static const ShellDestination home = ShellDestination.floorPlan;
}
