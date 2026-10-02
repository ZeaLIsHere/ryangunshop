import 'package:flutter/material.dart';
import 'package:ryangunshop/core/theme/app_colors.dart';

/// Kanvas denah 2D interaktif (mode lihat).
///
/// Mendukung fitur zoom dan pan. Menggunakan InteractiveViewer agar 
/// kanvas dapat digeser dan diperbesar oleh pengguna.
class StoreFloorPlan extends StatelessWidget {
  const StoreFloorPlan({super.key});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(100),
      minScale: 0.5,
      maxScale: 3.0,
      child: Container(
        color: AppColors.canvas,
        width: 1000,
        height: 1000,
        // TODO: render fixture tiles here
      ),
    );
  }
}
