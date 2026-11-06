import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../model/fixture_item.dart';

/// Komponen visual objek ruang (fixture) di atas kanvas denah.
class FixtureTile extends StatelessWidget {
  const FixtureTile({
    required this.fixture,
    required this.isSelected,
    required this.isHighlighted,
    required this.isEditMode,
    required this.onTap,
    super.key,
  });

  final FixtureItem fixture;
  final bool isSelected;
  final bool isHighlighted;
  final bool isEditMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticLabel =
        '${fixture.type.label}: ${fixture.name}, ${fixture.productCount} produk'
        '${fixture.hasLowStock ? ', stok menipis' : ''}';

    Color borderColor = fixture.type.accentColor.withValues(alpha: 0.5);
    double borderWidth = 1.5;
    List<BoxShadow> shadows = [];

    if (isHighlighted) {
      borderColor = AppColors.accent;
      borderWidth = 3.0;
      shadows = [
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.5),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ];
    } else if (isSelected) {
      borderColor = AppColors.primary;
      borderWidth = 2.5;
      shadows = [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.3),
          blurRadius: 6,
          spreadRadius: 1,
        ),
      ];
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Transform.rotate(
        angle: fixture.rotation * (math.pi / 180),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.fixtureBorder,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: fixture.type.backgroundColor,
                borderRadius: AppRadius.fixtureBorder,
                border: Border.all(color: borderColor, width: borderWidth),
                boxShadow: shadows,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          fixture.type.icon,
                          size: 20,
                          color: fixture.type.accentColor,
                        ),
                        if (fixture.hasLowStock) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: AppColors.warning,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fixture.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                        fontSize: 11,
                      ),
                    ),
                    if (fixture.productCount > 0) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.primaryLight),
                        ),
                        child: Text(
                          '${fixture.productCount} item',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (isEditMode) ...[
                      const SizedBox(height: 2),
                      const Icon(
                        Icons.drag_indicator,
                        size: 14,
                        color: AppColors.muted,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
