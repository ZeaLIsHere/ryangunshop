import 'package:flutter/material.dart';

/// Tab utama pada navigasi bawah.
///
/// Urutan nilai menentukan urutan tab dari kiri ke kanan.
enum ShellDestination {
  floorPlan(
    label: 'Denah',
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view,
    unavailableMessage: 'Denah interaktif warung belum tersedia.',
  ),
  catalog(
    label: 'Katalog',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    unavailableMessage: 'Daftar produk dan status stok belum tersedia.',
  ),
  cashier(
    label: 'Kasir',
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale,
    unavailableMessage: 'Keranjang dan pembayaran belum tersedia.',
  ),
  settings(
    label: 'Pengaturan',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    unavailableMessage: 'Pengaturan dan peran pengguna belum tersedia.',
  );

  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.unavailableMessage,
  });

  /// Label tab, sekaligus judul app bar dan label semantik.
  final String label;

  /// Ikon saat tab tidak dipilih.
  final IconData icon;

  /// Ikon saat tab dipilih.
  final IconData selectedIcon;

  /// Keterangan jujur selama isi tab belum dibangun.
  final String unavailableMessage;
}
