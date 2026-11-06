import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../model/dashboard_shortcut.dart';
import '../sample/dashboard_sample.dart';

/// Dashboard utama: satu aksi kasir yang dominan dan pintasan ringkas.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.onShortcutSelected,
    this.onOpenFloorPlan,
    this.onStartScan,
    super.key,
  });

  /// Dipanggil saat pengguna memilih salah satu pintasan.
  final ValueChanged<DashboardShortcut> onShortcutSelected;
  final VoidCallback? onOpenFloorPlan;

  /// Aksi utama "Mulai pindai". Bila tidak diisi, membuka tab kasir.
  final VoidCallback? onStartScan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortcuts = DashboardSample.shortcuts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MainActionCard(
            onPressed:
                onStartScan ??
                () => onShortcutSelected(DashboardShortcut.cashier),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            DashboardSample.shortcutsSectionTitle,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var index = 0; index < shortcuts.length; index += 2) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ShortcutTile(
                    shortcut: shortcuts[index],
                    onTap: () => onShortcutSelected(shortcuts[index]),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: index + 1 < shortcuts.length
                      ? _ShortcutTile(
                          shortcut: shortcuts[index + 1],
                          onTap: () => onShortcutSelected(shortcuts[index + 1]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.xs),
          _FloorPlanCard(onTap: onOpenFloorPlan),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: AppRadius.panelBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.16),
                  borderRadius: AppRadius.controlBorder,
                ),
                child: const Icon(
                  Icons.point_of_sale_rounded,
                  color: AppColors.surface,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  DashboardSample.mainActionTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.surface,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            DashboardSample.mainActionDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.surface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: AppSpacing.minTouchTarget,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primaryDark,
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              label: Text(DashboardSample.mainActionLabel),
            ),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.controlCompactBorder,
            ),
            child: Icon(shortcut.icon, size: 20, color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(shortcut.label, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            shortcut.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Kartu pintasan menuju kanvas denah warung.
class _FloorPlanCard extends StatelessWidget {
  const _FloorPlanCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      semanticLabel: DashboardSample.floorPlanTitle,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.controlCompactBorder,
            ),
            child: const Icon(Icons.map_outlined, color: AppColors.primaryDark),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
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
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}
