import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Penanda bahwa nilai di sekitarnya masih data contoh.
///
/// Dipakai di seluruh fitur supaya status contoh selalu terlihat, bukan tersirat.
class SampleBadge extends StatelessWidget {
  const SampleBadge({this.label = 'Data contoh', super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.fixtureBorder,
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}
