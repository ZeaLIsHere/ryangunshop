import 'package:flutter/foundation.dart';

/// Jenis objek ruang (fixture) yang ada di warung.
enum FixtureType {
  /// Dinding pembatas atau struktural.
  wall,
  /// Area pejalan kaki / lorong kosong.
  aisle,
  /// Rak produk umum.
  shelf,
  /// Lemari penyimpanan (tertutup).
  cabinet,
  /// Kulkas atau pendingin minuman.
  cooler,
  /// Meja kasir.
  checkout,
}

/// Model data yang mewakili satu objek ruang (fixture) di dalam denah.
/// Menggunakan koordinat relatif (0.0 - 1.0) agar dapat dirender pada resolusi apa pun.
@immutable
class FixtureModel {
  final String id;
  final String name;
  final FixtureType type;
  
  /// Jumlah produk yang terasosiasi dengan fixture ini.
  final int productCount;
  
  /// Posisi relatif X dari kiri (0.0 sampai 1.0).
  final double x;
  
  /// Posisi relatif Y dari atas (0.0 sampai 1.0).
  final double y;
  
  /// Lebar relatif (0.0 sampai 1.0).
  final double width;
  
  /// Tinggi relatif (0.0 sampai 1.0).
  final double height;
  
  /// Rotasi objek dalam derajat (0 - 360).
  final double rotation;

  const FixtureModel({
    required this.id,
    required this.name,
    required this.type,
    this.productCount = 0,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0.0,
  });

  /// Menyalin objek dengan beberapa perubahan properti.
  FixtureModel copyWith({
    String? id,
    String? name,
    FixtureType? type,
    int? productCount,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
  }) {
    return FixtureModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      productCount: productCount ?? this.productCount,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
    );
  }
}
