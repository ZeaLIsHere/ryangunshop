import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'shell_destination.dart';

/// Isi sementara untuk tab yang fiturnya belum dibangun.
///
/// Sengaja tidak menampilkan data apa pun supaya tidak terlihat seperti integrasi
/// nyata, dan menyebutkan dengan jelas bahwa bagian ini belum tersedia.
class ShellPlaceholderView extends StatelessWidget {
  const ShellPlaceholderView({required this.destination, super.key});

  final ShellDestination destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(destination.selectedIcon, size: 48, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              destination.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              destination.unavailableMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Bagian ini sedang dikerjakan.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
