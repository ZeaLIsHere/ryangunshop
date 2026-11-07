import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PanoramaHotspot {
  const PanoramaHotspot({
    required this.id,
    required this.title,
    required this.fixtureId,
    required this.yaw,
    required this.pitch,
    this.icon = Icons.location_on,
  });

  final String id;
  final String title;
  final String fixtureId;

  /// Sudut horizontal (0 sampai 360 derajat)
  final double yaw;

  /// Sudut vertikal (-90 sampai 90 derajat)
  final double pitch;
  final IconData icon;
}

class PanoramaZone {
  const PanoramaZone({
    required this.id,
    required this.name,
    required this.description,
    required this.hotspots,
    this.primaryColor = AppColors.primary,
  });

  final String id;
  final String name;
  final String description;
  final List<PanoramaHotspot> hotspots;
  final Color primaryColor;
}

abstract final class PanoramaSample {
  static const List<PanoramaZone> zones = [
    PanoramaZone(
      id: 'zona-depan',
      name: 'Zona Depan & Kasir',
      description: 'Pintu masuk utama, meja kasir, dan lemari etalase',
      hotspots: [
        PanoramaHotspot(
          id: 'spot-kasir',
          title: 'Meja Kasir Utama',
          fixtureId: 'meja-kasir',
          yaw: 45,
          pitch: -5,
          icon: Icons.point_of_sale,
        ),
        PanoramaHotspot(
          id: 'spot-lemari',
          title: 'Lemari Khusus',
          fixtureId: 'lemari-rokok',
          yaw: 120,
          pitch: 5,
          icon: Icons.inventory_2,
        ),
      ],
    ),
    PanoramaZone(
      id: 'zona-tengah',
      name: 'Zona Tengah & Sembako',
      description: 'Lorong rak sembako, beras, minyak, dan mi instan',
      hotspots: [
        PanoramaHotspot(
          id: 'spot-sembako',
          title: 'Rak Sembako A',
          fixtureId: 'contoh-rak-sembako',
          yaw: 80,
          pitch: 0,
          icon: Icons.table_rows,
        ),
        PanoramaHotspot(
          id: 'spot-mi',
          title: 'Rak Makanan B',
          fixtureId: 'contoh-rak-mi',
          yaw: 220,
          pitch: 0,
          icon: Icons.fastfood,
        ),
      ],
    ),
    PanoramaZone(
      id: 'zona-belakang',
      name: 'Zona Belakang & Kulkas',
      description: 'Area pendingin minuman dan gudang kecil',
      hotspots: [
        PanoramaHotspot(
          id: 'spot-kulkas',
          title: 'Kulkas Minuman',
          fixtureId: 'contoh-kulkas',
          yaw: 150,
          pitch: 0,
          icon: Icons.kitchen,
        ),
      ],
    ),
  ];
}
