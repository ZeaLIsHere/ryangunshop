import 'package:flutter/material.dart';

import '../../../core/data/transaction_repository.dart';
import '../../../core/format/rupiah.dart';
import '../../../core/session/completed_transaction.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../sample/dashboard_sample.dart';
import '../model/dashboard_shortcut.dart';

/// Kartu Hero Omzet & Kasir utama bertema Violet Gradient (sesuai desain/home_denah_warung).
class DashboardHeroCard extends StatelessWidget {
  const DashboardHeroCard({
    required this.onPressed,
    required this.daily,
    this.title = 'Omzet Hari Ini',
    this.actionLabel = DashboardSample.mainActionLabel,
    this.actionIcon = Icons.qr_code_scanner,

    super.key,
  });

  final String title;
  final String actionLabel;
  final IconData actionIcon;

  final List<TransactionRecord> daily;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayRevenue = daily.fold(0, (sum, row) => sum + row.totalAmount);
    final todayTransactionCount = daily.length;
    final todayAverageRevenue = daily.isEmpty
        ? 0
        : (todayRevenue / daily.length).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: AppRadius.panelBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.surface.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              formatRupiah(todayRevenue),
              style: theme.textTheme.displayMedium?.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.bold,
                letterSpacing: -1.0,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.surface.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Transaksi',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.surface.withValues(alpha: 0.75),
                          ),
                        ),
                        Text(
                          '$todayTransactionCount Nota',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 22,
                      color: AppColors.surface.withValues(alpha: 0.25),
                    ),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Rata-rata',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.surface.withValues(alpha: 0.75),
                            ),
                          ),
                          Text(
                            formatRupiah(todayAverageRevenue),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    minimumSize: const Size(
                      AppSpacing.minTouchTarget,
                      AppSpacing.minTouchTarget,
                    ),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  onPressed: onPressed,
                  icon: Icon(actionIcon, size: 18),
                  label: Text(
                    actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardActionPod extends StatelessWidget {
  const DashboardActionPod({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
    this.assetPath,
    this.badgeText,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback? onTap;
  final String? assetPath;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: AppSpacing.sm,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppRadius.squircle),
                ),
                child: assetPath != null
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxs),
                        child: Image.asset(
                          assetPath!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              Icon(icon, color: iconColor, size: 22),
                        ),
                      )
                    : Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          if (badgeText != null)
            Positioned(
              top: -2,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DashboardTransactionRow extends StatelessWidget {
  const DashboardTransactionRow({
    required this.transaction,
    this.receiptId,
    super.key,
  });

  final CompletedTransaction transaction;
  final String? receiptId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child:
                  transaction.imageUrl != null &&
                      transaction.imageUrl!.isNotEmpty
                  ? Image.network(
                      transaction.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.image_outlined,
                        color: AppColors.muted,
                        size: 22,
                      ),
                    )
                  : const Icon(
                      Icons.image_outlined,
                      color: AppColors.muted,
                      size: 22,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (receiptId != null)
                  Text(receiptId!, style: theme.textTheme.bodySmall),
                Text(
                  transaction.timeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatRupiah(transaction.amount),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: AppTypography.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardShortcutsSection extends StatelessWidget {
  const DashboardShortcutsSection({
    required this.onShortcutSelected,
    super.key,
  });

  final ValueChanged<DashboardShortcut> onShortcutSelected;

  @override
  Widget build(BuildContext context) {
    final shortcuts = DashboardSample.shortcuts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(
          DashboardSample.shortcutsSectionTitle,
          style: Theme.of(context).textTheme.headlineSmall,
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
      ],
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
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            padding: const EdgeInsets.all(AppSpacing.xxs),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.controlCompactBorder,
            ),
            child: Image.asset(
              shortcut.assetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  Icon(shortcut.icon, size: 20, color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(shortcut.label, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(shortcut.description, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
