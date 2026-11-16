import 'package:flutter/material.dart';

import '../../../core/data/transaction_repository.dart';
import '../../../core/session/app_session.dart';
import '../../../core/session/completed_transaction.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../model/dashboard_shortcut.dart';
import 'dashboard_components.dart';

/// Beranda utama: Hero Omzet harian, 4 modul bento Aksi Cepat,
/// riwayat transaksi terkini, dan pintasan menu.
class CashierDashboard extends StatefulWidget {
  const CashierDashboard({
    required this.onShortcutSelected,
    this.onStartScan,
    super.key,
  });

  /// Dipanggil saat pengguna memilih salah satu pintasan.
  final ValueChanged<DashboardShortcut> onShortcutSelected;

  /// Aksi utama "Mulai pindai". Bila tidak diisi, membuka tab kasir.
  final VoidCallback? onStartScan;

  @override
  State<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends State<CashierDashboard> {
  Future<
    ({
      List<TransactionRecord> daily,
      List<CompletedTransaction> recent,
      int lowStock,
    })
  >?
  _data;
  int? _count;
  ValueChanged<DashboardShortcut> get onShortcutSelected =>
      widget.onShortcutSelected;
  VoidCallback? get onStartScan => widget.onStartScan;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final count = AppSessionScope.of(context).todayTransactionCount;
    if (_data == null || _count != count) {
      _count = count;
      _data = _load();
    }
  }

  Future<
    ({
      List<TransactionRecord> daily,
      List<CompletedTransaction> recent,
      int lowStock,
    })
  >
  _load() async {
    final session = AppSessionScope.of(context);
    final daily = await session.transactionRepository.listForDay(
      DateTime.now(),
    );
    final recent = await session.transactionRepository.listRecent(limit: 5);
    final products = await session.productRepository.listProducts();
    if (!mounted) throw StateError('Beranda sudah ditutup');
    return (
      daily: daily,
      recent: [
        for (final row in recent)
          CompletedTransaction(
            id: row.id,
            title: row.summaryTitle,
            amount: row.totalAmount,
            timeLabel: TimeOfDay.fromDateTime(row.createdAt.toLocal())
                .format(context),
            itemCount: row.itemCount,
            paymentMethod: row.paymentMethod,
          ),
      ],
      lowStock: products
          .where((p) => p.stock > 0 && p.stock <= p.lowStockThreshold)
          .length,
    );
  }

  void _reload() => setState(() {
    _data = _load();
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(semanticsLabel: 'Memuat beranda'),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline),
                const Text('Data beranda gagal dimuat. Angka belum tersedia.'),
                TextButton(onPressed: _reload, child: const Text('Coba lagi')),
              ],
            ),
          );
        }
        final data = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardHeroCard(
                daily: data.daily,
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
                lowStock: data.lowStock,
                onStartScan:
                    onStartScan ??
                    () => onShortcutSelected(DashboardShortcut.cashier),
                onOpenCashier: () =>
                    onShortcutSelected(DashboardShortcut.cashier),
                onOpenCatalog: () =>
                    onShortcutSelected(DashboardShortcut.catalog),
                onOpenReports: () =>
                    onShortcutSelected(DashboardShortcut.reports),
              ),
              const SizedBox(height: AppSpacing.md),
              _RecentTransactionsSection(
                transactions: data.recent,
                onViewAll: () => onShortcutSelected(DashboardShortcut.reports),
              ),
              DashboardShortcutsSection(onShortcutSelected: onShortcutSelected),
              const SizedBox(height: AppSpacing.sm),
              const Text('Data perangkat ini · dapat dibuka offline'),
              TextButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Muat ulang'),
              ),
              if (data.recent.isEmpty)
                TextButton(
                  onPressed: () =>
                      onShortcutSelected(DashboardShortcut.cashier),
                  child: const Text('Catat penjualan'),
                ),
            ],
          ),
        );
      },
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
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(AppRadius.squircle),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxs),
              child: Image.asset(
                'assets/icon/10_printer_bluetooth.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.print_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
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
                  'Buka laporan perangkat ini',
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
    required this.lowStock,
  });

  final VoidCallback onStartScan;
  final VoidCallback onOpenCashier;
  final VoidCallback onOpenCatalog;
  final VoidCallback onOpenReports;
  final int lowStock;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DashboardActionPod(
            assetPath: 'assets/icon/08_pindai_barcode.png',
            icon: Icons.qr_code_scanner,
            label: 'Pindai Barcode',
            bgColor: AppColors.primarySubtle,
            iconColor: AppColors.primary,
            onTap: onStartScan,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: DashboardActionPod(
            assetPath: 'assets/icon/02_keranjang.png',
            icon: Icons.point_of_sale,
            label: 'Buka Kasir',
            bgColor: AppColors.primarySubtle,
            iconColor: AppColors.ink,
            onTap: onOpenCashier,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: DashboardActionPod(
            assetPath: 'assets/icon/09_stok_produk.png',
            icon: Icons.inventory_2_outlined,
            label: 'Stok',
            badgeText: lowStock > 0 ? '$lowStock' : null,
            bgColor: AppColors.primarySubtle,
            iconColor: AppColors.warning,
            onTap: onOpenCatalog,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: DashboardActionPod(
            assetPath: 'assets/icon/03_riwayat_transaksi.png',
            icon: Icons.receipt_long_outlined,
            label: 'Riwayat Nota',
            bgColor: AppColors.primaryLight,
            iconColor: AppColors.primaryDark,
            onTap: onOpenReports,
          ),
        ),
      ],
    );
  }
}

/// Bagian Aktivitas Transaksi Terbaru sesuai desain/home_denah_warung.
class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({
    required this.onViewAll,
    required this.transactions,
  });

  final List<CompletedTransaction> transactions;

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  minimumSize: const Size(
                    AppSpacing.minTouchTarget,
                    AppSpacing.minTouchTarget,
                  ),
                ),
                onPressed: onViewAll,
                child: Text(
                  'Semua',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
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
                return DashboardTransactionRow(transaction: trx);
              },
            ),
        ],
      ),
    );
  }
}
