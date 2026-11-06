import 'package:flutter/material.dart';

/// Urutan tampilan daftar produk pada katalog.
///
/// Sengaja dibatasi pada urutan yang menjawab cara kerja warung. Urutan
/// "terlaris" tidak disertakan karena belum ada data penjualan nyata.
enum CatalogSort {
  nameAsc('Nama A-Z', Icons.sort_by_alpha),
  category('Kategori', Icons.category_outlined),
  stockAsc('Stok menipis dulu', Icons.inventory_2_outlined),
  priceAsc('Harga termurah', Icons.trending_down),
  priceDesc('Harga termahal', Icons.trending_up),
  location('Rak / lokasi', Icons.place_outlined);

  const CatalogSort(this.label, this.icon);

  /// Label bahasa Indonesia untuk menu urutkan.
  final String label;

  /// Ikon pendamping label; makna tidak bergantung pada ikon saja.
  final IconData icon;
}
