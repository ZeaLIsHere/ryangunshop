import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Jenis objek ruang/fixture di dalam warung.
enum FixtureType {
  shelf('Rak Barang', Icons.table_rows_outlined, AppColors.primaryLight, AppColors.primary),
  chiller('Kulkas Minuman', Icons.kitchen_outlined, Color(0xFFE0F2FE), Color(0xFF0284C7)),
  cabinet('Lemari Rokok & Obat', Icons.inventory_2_outlined, Color(0xFFFEF3C7), Color(0xFFD97706)),
  cashierDesk('Meja Kasir', Icons.point_of_sale_outlined, Color(0xFFDCFCE7), Color(0xFF16A34A)),
  aisle('Lorong', Icons.straighten_outlined, Color(0xFFF1F5F9), Color(0xFF64748B)),
  wall('Dinding Batas', Icons.crop_square_outlined, Color(0xFFE2E8F0), Color(0xFF475569));

  const FixtureType(this.label, this.icon, this.backgroundColor, this.accentColor);

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color accentColor;
}

/// Model objek ruang (fixture) dengan koordinat relatif (0.0 - 1.0).
class FixtureItem {
  const FixtureItem({
    required this.id,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
    this.zoneId = 'zona-utama',
    this.productCount = 0,
    this.hasLowStock = false,
  }) : assert(rotation % 90 == 0, 'Rotasi harus kelipatan 90 derajat');

  final String id;
  final String name;
  final FixtureType type;
  /// Koordinat horizontal relatif dari kiri (0.0 sampai 1.0).
  final double x;
  /// Koordinat vertikal relatif dari atas (0.0 sampai 1.0).
  final double y;
  /// Lebar relatif (0.0 sampai 1.0).
  final double width;
  /// Tinggi relatif (0.0 sampai 1.0).
  final double height;
  /// Rotasi objek dalam derajat: 0, 90, 180, 270.
  final int rotation;
  /// Zona panorama 360 yang menaungi objek ini.
  final String zoneId;
  /// Jumlah produk yang terhubung ke objek ini.
  final int productCount;
  /// Indikator jika ada produk di rak ini yang stoknya menipis.
  final bool hasLowStock;

  FixtureItem copyWith({
    String? id,
    String? name,
    FixtureType? type,
    double? x,
    double? y,
    double? width,
    double? height,
    int? rotation,
    String? zoneId,
    int? productCount,
    bool? hasLowStock,
  }) {
    return FixtureItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      zoneId: zoneId ?? this.zoneId,
      productCount: productCount ?? this.productCount,
      hasLowStock: hasLowStock ?? this.hasLowStock,
    );
  }
}
