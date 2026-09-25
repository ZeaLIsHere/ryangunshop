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
  ),
  cashier(
    label: 'Keranjang',
    description: 'Periksa barang lalu bayar',
    icon: Icons.point_of_sale_outlined,
  ),
  reports(
    label: 'Riwayat transaksi',
    description: 'Lihat transaksi yang sudah selesai',
    icon: Icons.receipt_long_outlined,
  ),
  settings(
    label: 'Pengaturan',
    description: 'Peran pengguna dan info warung',
    icon: Icons.settings_outlined,
  );

  const DashboardShortcut({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;
  final String description;
  final IconData icon;
}
