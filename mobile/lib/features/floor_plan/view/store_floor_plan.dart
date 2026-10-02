import 'package:flutter/material.dart';
import 'package:ryangunshop/core/theme/app_colors.dart';

import '../model/fixture_model.dart';
import 'fixture_tile.dart';

/// Kanvas denah 2D interaktif (mode lihat).
///
/// Mendukung fitur zoom dan pan. Menggunakan InteractiveViewer agar 
/// kanvas dapat digeser dan diperbesar oleh pengguna.
class StoreFloorPlan extends StatelessWidget {
  final List<FixtureModel> fixtures;
  final ValueChanged<FixtureModel>? onFixtureTap;

  const StoreFloorPlan({
    super.key,
    this.fixtures = const [],
    this.onFixtureTap,
  });

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasWidth = constraints.maxWidth;
            final canvasHeight = constraints.maxHeight;

            return Stack(
              children: fixtures.map((fixture) {
                return Positioned(
                  left: fixture.x * canvasWidth,
                  top: fixture.y * canvasHeight,
                  width: fixture.width * canvasWidth,
                  height: fixture.height * canvasHeight,
                  child: FixtureTile(
                    fixture: fixture,
                    onTap: onFixtureTap != null 
                        ? () => onFixtureTap!(fixture) 
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
