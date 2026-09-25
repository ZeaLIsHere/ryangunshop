import 'package:flutter/material.dart';
import 'package:ryangunshop/core/theme/app_colors.dart';
import 'package:ryangunshop/core/theme/app_radius.dart';
import 'package:ryangunshop/core/theme/app_spacing.dart';
import '../model/fixture_model.dart';

/// Komponen visual untuk merender sebuah objek ruang (fixture) di atas denah.
///
/// Komponen ini menyesuaikan tampilannya berdasarkan [FixtureType], dan 
/// menampilkan nama serta jumlah produk jika relevan. Dilengkapi dengan semantic
/// label untuk aksesibilitas.
class FixtureTile extends StatelessWidget {
  final FixtureModel fixture;
  final VoidCallback? onTap;

  const FixtureTile({
    super.key,
    required this.fixture,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${_getFixtureTypeName(fixture.type)} ${fixture.name}, '
          '${fixture.productCount} produk.',
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _getBackgroundColor(fixture.type),
            border: Border.all(
              color: AppColors.primary,
              width: fixture.type == FixtureType.wall ? 0.0 : 1.0,
            ),
            borderRadius: AppRadius.fixtureBorder,
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (fixture.type == FixtureType.wall || fixture.type == FixtureType.aisle) {
      // Dinding atau lorong kosong biasanya tidak menampilkan teks produk secara menonjol
      return Center(
        child: Text(
          fixture.name,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _getIconForType(fixture.type),
          color: AppColors.primaryDark,
          size: 16,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          fixture.name,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (fixture.productCount > 0)
          Text(
            '${fixture.productCount} item',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9,
            ),
          ),
      ],
    );
  }

  String _getFixtureTypeName(FixtureType type) {
    switch (type) {
      case FixtureType.wall:
        return 'Dinding';
      case FixtureType.aisle:
        return 'Lorong';
      case FixtureType.shelf:
        return 'Rak';
      case FixtureType.cabinet:
        return 'Lemari';
      case FixtureType.cooler:
        return 'Kulkas';
      case FixtureType.checkout:
        return 'Meja Kasir';
    }
  }

  Color _getBackgroundColor(FixtureType type) {
    switch (type) {
      case FixtureType.wall:
        return AppColors.ink.withAlpha((0.1 * 255).round());
      case FixtureType.aisle:
        return Colors.transparent;
      case FixtureType.cooler:
        return AppColors.primaryLight.withAlpha((0.5 * 255).round());
      case FixtureType.checkout:
        return AppColors.accent.withAlpha((0.2 * 255).round());
      default:
        return AppColors.surface;
    }
  }

  IconData _getIconForType(FixtureType type) {
    switch (type) {
      case FixtureType.shelf:
        return Icons.shelves; // Memerlukan material_design_icons atau icon material 3 terdekat
      case FixtureType.cabinet:
        return Icons.kitchen;
      case FixtureType.cooler:
        return Icons.ac_unit;
      case FixtureType.checkout:
        return Icons.point_of_sale;
      default:
        return Icons.square;
    }
  }
}
