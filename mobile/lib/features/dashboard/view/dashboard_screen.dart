import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_action.dart';
import '../model/dashboard_shortcut.dart';
import '../sample/dashboard_sample.dart';

/// Dashboard utama: satu aksi kasir yang dominan dan pintasan ringkas.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.onShortcutSelected, super.key});

  /// Dipanggil saat pengguna memilih aksi utama atau salah satu pintasan.
  final ValueChanged<DashboardShortcut> onShortcutSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MainActionCard(
            onPressed: () => onShortcutSelected(DashboardShortcut.cashier),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            DashboardSample.shortcutsSectionTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final shortcut in DashboardSample.shortcuts) ...[
            _ShortcutTile(
              shortcut: shortcut,
              onTap: () => onShortcutSelected(shortcut),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.xs),
          const _FloorPlanCard(),
        ],
      ),
    );
  }
}

/// Kartu aksi utama yang paling menonjol pada layar.
class _MainActionCard extends StatelessWidget {
  const _MainActionCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.point_of_sale,
                size: 28,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  DashboardSample.mainActionTitle,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            DashboardSample.mainActionDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryAction(
            label: DashboardSample.mainActionLabel,
            icon: Icons.qr_code_scanner,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

/// Pintasan ringkas menuju fitur lain.
class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({required this.shortcut, required this.onTap});

  final DashboardShortcut shortcut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.fixtureBorder,
            ),
            child: Icon(shortcut.icon, color: AppColors.primaryDark),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shortcut.label, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(shortcut.description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Penanda jujur bahwa kanvas denah belum tersedia.
class _FloorPlanCard extends StatelessWidget {
  const _FloorPlanCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      semanticLabel: DashboardSample.floorPlanTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DashboardSample.floorPlanTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            DashboardSample.floorPlanUnavailable,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
