import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/session/app_session.dart';
import '../../../core/session/completed_transaction.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../model/dashboard_shortcut.dart';
import '../sample/dashboard_sample.dart';

/// Beranda utama: Hero Omzet harian, 4 modul bento Aksi Cepat,
/// riwayat transaksi terkini, dan pintasan menu.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.onShortcutSelected,
    this.onStartScan,
    super.key,
  });

  /// Dipanggil saat pengguna memilih salah satu pintasan.
  final ValueChanged<DashboardShortcut> onShortcutSelected;

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
          _HeroOmzetCard(
            onPressed:
                onStartScan ??
                () => onShortcutSelected(DashboardShortcut.cashier),
          ),
          const SizedBox(height: AppSpacing.sm),
          _QuickPrintCard(
            onTap: () => onShortcutSelected(DashboardShortcut.reports),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Aksi Cepat',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _QuickActionBento(
            onStartScan:
                onStartScan ??
                () => onShortcutSelected(DashboardShortcut.cashier),
            onOpenCashier: () => onShortcutSelected(DashboardShortcut.cashier),
            onOpenCatalog: () => onShortcutSelected(DashboardShortcut.catalog),
            onOpenReports: () => onShortcutSelected(DashboardShortcut.reports),
          ),
          const SizedBox(height: AppSpacing.md),
          _RecentTransactionsSection(
            onViewAll: () => onShortcutSelected(DashboardShortcut.reports),
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
        ],
      ),
    );
  }
}

/// Kartu Hero Omzet & Kasir utama bertema Violet Gradient (sesuai desain/home_denah_warung).
class _HeroOmzetCard extends StatelessWidget {
  const _HeroOmzetCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AppSessionScope.maybeOf(context);
    final todayRevenue = session?.todayRevenue ?? 1450000;
    final todayTransactionCount = session?.todayTransactionCount ?? 42;
    final todayAverageRevenue = session?.todayAverageRevenue ?? 34500;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark, Color(0xFF4C1D95)],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Omzet Hari Ini',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.2),
                  borderRadius: AppRadius.pillBorder,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Shift Siang',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.surface,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                            fontSize: 10,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rata-rata',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.surface.withValues(alpha: 0.75),
                            fontSize: 10,
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
                    minimumSize: const Size(48, 42),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  onPressed: onPressed,
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: Text(
                    DashboardSample.mainActionLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
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

/// Modul cetak struk cepat printer Bluetooth (sesuai desain/home_denah_warung).
class _QuickPrintCard extends StatelessWidget {
  const _QuickPrintCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(AppRadius.squircle),
            ),
            child: const Icon(
              Icons.print_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cetak Laporan Harian',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Printer Bluetooth Siap',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
        ],
      ),
    );
  }
}

/// Baris 4-up bento Aksi Cepat dengan squircle pod pastel (sesuai desain/home_denah_warung).
class _QuickActionBento extends StatelessWidget {
  const _QuickActionBento({
    required this.onStartScan,
    required this.onOpenCashier,
    required this.onOpenCatalog,
    required this.onOpenReports,
  });

  final VoidCallback onStartScan;
  final VoidCallback onOpenCashier;
  final VoidCallback onOpenCatalog;
  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionPod(
            icon: Icons.qr_code_scanner,
            label: 'Pindai Barcode',
            bgColor: const Color(0xFFF5F3FF),
            iconColor: const Color(0xFF7C3AED),
            onTap: onStartScan,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _QuickActionPod(
            icon: Icons.point_of_sale,
            label: 'Buka Kasir',
            bgColor: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF059669),
            onTap: onOpenCashier,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _QuickActionPod(
            icon: Icons.notification_important_outlined,
            label: 'Stok Menipis',
            badgeText: '3',
            bgColor: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFEA580C),
            onTap: onOpenCatalog,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _QuickActionPod(
            icon: Icons.receipt_long_outlined,
            label: 'Riwayat Nota',
            bgColor: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFF7E22CE),
            onTap: onOpenReports,
          ),
        ),
      ],
    );
  }
}

class _QuickActionPod extends StatelessWidget {
  const _QuickActionPod({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
    this.badgeText,
  });

  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppRadius.squircle),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
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
                  color: Color(0xFFEA580C),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
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

/// Bagian Aktivitas Transaksi Terbaru sesuai desain/home_denah_warung.
class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AppSessionScope.maybeOf(context);
    final transactions =
        session?.recentTransactions ??
        const [
          CompletedTransaction(
            id: 'TRX-9481',
            timeLabel: '13:42 WIB',
            title: 'Minyak Goreng Bimoli 2L',
            amount: 36500,
            itemCount: 1,
            paymentMethod: 'Tunai',
          ),
          CompletedTransaction(
            id: 'TRX-9480',
            timeLabel: '13:30 WIB',
            title: 'Indomie Goreng Spesial (5 Pcs)',
            amount: 15500,
            itemCount: 5,
            paymentMethod: 'QRIS',
          ),
          CompletedTransaction(
            id: 'TRX-9479',
            timeLabel: '13:18 WIB',
            title: 'Teh Pucuk Harum Dingin 350ml (2)',
            amount: 8000,
            itemCount: 2,
            paymentMethod: 'Tunai',
          ),
        ];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Aktivitas Transaksi Terbaru',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(48, 30),
                ),
                onPressed: onViewAll,
                child: const Text(
                  'Semua Nota',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: Text(
                  'Belum ada transaksi hari ini',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length.clamp(0, 5),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final trx = transactions[index];
                return _TransactionItemRow(transaction: trx);
              },
            ),
        ],
      ),
    );
  }
}

class _TransactionItemRow extends StatelessWidget {
  const _TransactionItemRow({required this.transaction});

  final CompletedTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCash = transaction.paymentMethod.toLowerCase().contains('tunai');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isCash ? const Color(0xFFECFDF5) : const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCash ? Icons.payments_outlined : Icons.qr_code_2,
              color: isCash ? const Color(0xFF059669) : const Color(0xFF7C3AED),
              size: 20,
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Nota #${transaction.id} • ${transaction.timeLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupiah(transaction.amount),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isCash
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  transaction.paymentMethod,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isCash
                        ? const Color(0xFF059669)
                        : const Color(0xFF7C3AED),
                  ),
                ),
              ),
            ],
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
            width: 44,
            height: 44,
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
