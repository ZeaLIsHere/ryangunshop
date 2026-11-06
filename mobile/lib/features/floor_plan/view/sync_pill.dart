import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

enum SyncStatus {
  synced('Tersinkron', Icons.cloud_done_outlined, AppColors.success),
  pending('Sinkronisasi...', Icons.sync, AppColors.primary),
  offline('Mode Offline', Icons.cloud_off_outlined, AppColors.warning);

  const SyncStatus(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

/// Pill penanda status sinkronisasi data warung.
class SyncPill extends StatelessWidget {
  const SyncPill({
    this.status = SyncStatus.synced,
    super.key,
  });

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _showSyncDialog(context),
      borderRadius: AppRadius.fixtureBorder,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs + 2,
        ),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.1),
          borderRadius: AppRadius.fixtureBorder,
          border: Border.all(color: status.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 14, color: status.color),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              status.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: status.color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(status.icon, color: status.color),
            const SizedBox(width: AppSpacing.xs),
            const Text('Status Sinkronisasi'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Data lokal tersimpan aman di perangkat.'),
            SizedBox(height: 6),
            Text('• Perubahan katalog dan denah langsung aktif.'),
            SizedBox(height: 6),
            Text('• Sinkronisasi otomatis berjalan di latar belakang.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
