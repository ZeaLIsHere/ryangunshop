import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/brand_spinner.dart';
import '../../../core/widgets/primary_action.dart';
import '../../../core/widgets/sample_badge.dart';
import '../../catalog/model/catalog_product.dart';
import '../model/scanner_scenario.dart';
import '../view_model/scanner_view_model.dart';

/// Ringkasan dan tindakan untuk setiap state pratinjau pemindai.
class ScannerStatusPanel extends StatelessWidget {
  const ScannerStatusPanel({
    required this.viewModel,
    required this.onManualSearch,
    required this.onConfirm,
    required this.onReturnToCheckout,
    this.onHighlightOnFloorPlan,
    super.key,
  });

  final ScannerViewModel viewModel;
  final VoidCallback onManualSearch;
  final VoidCallback onConfirm;
  final VoidCallback onReturnToCheckout;
  final VoidCallback? onHighlightOnFloorPlan;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.panelBorder,
        ),
        child: switch (viewModel.scenario) {
          ScannerScenario.ready => _message(
            context,
            icon: Icons.center_focus_strong_outlined,
            color: AppColors.primary,
            title: 'Siap memindai barcode',
            description: 'Arahkan barcode produk ke dalam bingkai kamera untuk memindai.',
            actions: [
              PrimaryAction(
                label: 'Coba Pindai Contoh',
                icon: Icons.qr_code_scanner,
                onPressed: viewModel.simulateScan,
              ),
              _secondaryButton(
                icon: Icons.search,
                label: 'Cari Produk Manual',
                onPressed: onManualSearch,
              ),
            ],
          ),
          ScannerScenario.loading => _message(
            context,
            icon: Icons.hourglass_top_outlined,
            color: AppColors.primary,
            title: 'Mencari produk contoh',
            description: 'Mencocokkan barcode dengan data produk warung.',
            actions: [
              if (!MediaQuery.disableAnimationsOf(context))
                const BrandSpinner(label: 'Memuat hasil contoh'),
              _secondaryButton(
                icon: Icons.close,
                label: 'Batalkan',
                onPressed: viewModel.reset,
              ),
            ],
          ),
          ScannerScenario.result => _result(context),
          ScannerScenario.added => _message(
            context,
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            title: 'Produk contoh masuk keranjang',
            description: 'Produk ditambahkan ke kasir. Lanjutkan pemindaian untuk produk lainnya.',
            actions: [
              PrimaryAction(
                label: 'Pindai Lagi',
                icon: Icons.qr_code_scanner,
                onPressed: viewModel.reset,
              ),
              _secondaryButton(
                icon: Icons.shopping_cart_outlined,
                label: 'Kembali ke Kasir',
                onPressed: onReturnToCheckout,
              ),
            ],
          ),
          ScannerScenario.empty => _message(
            context,
            icon: Icons.search_off_outlined,
            color: AppColors.muted,
            title: 'Produk tidak ditemukan',
            description: 'Barcode tidak cocok dengan produk di katalog. Coba cari manual.',
            actions: [
              PrimaryAction(
                label: 'Coba Pindai Lagi',
                icon: Icons.refresh,
                onPressed: viewModel.simulateScan,
              ),
              _secondaryButton(
                icon: Icons.search,
                label: 'Cari Produk Manual',
                onPressed: onManualSearch,
              ),
            ],
          ),
          ScannerScenario.permissionDenied => _message(
            context,
            icon: Icons.videocam_off_outlined,
            color: AppColors.warning,
            title: 'Izin kamera belum tersedia',
            description:
                'Ini skenario contoh. Produk tetap bisa dicari tanpa kamera.',
            actions: [
              PrimaryAction(
                label: 'Cari Produk Manual',
                icon: Icons.search,
                onPressed: onManualSearch,
              ),
              _secondaryButton(
                icon: Icons.arrow_back,
                label: 'Kembali ke Pratinjau',
                onPressed: viewModel.reset,
              ),
            ],
          ),
          ScannerScenario.failure => _message(
            context,
            icon: Icons.error_outline,
            color: AppColors.error,
            title: 'Pratinjau kamera gagal',
            description: 'Ini skenario contoh. Coba lagi atau pilih produk secara manual.',
            actions: [
              PrimaryAction(
                label: 'Coba Lagi',
                icon: Icons.refresh,
                onPressed: viewModel.reset,
              ),
              _secondaryButton(
                icon: Icons.search,
                label: 'Cari Produk Manual',
                onPressed: onManualSearch,
              ),
            ],
          ),
          ScannerScenario.offline => _message(
            context,
            icon: Icons.cloud_off_outlined,
            color: AppColors.warning,
            title: 'Mode offline contoh',
            description:
                'Data katalog contoh tetap bisa dicari manual tanpa jaringan.',
            actions: [
              PrimaryAction(
                label: 'Cari Produk Manual',
                icon: Icons.search,
                onPressed: onManualSearch,
              ),
              _secondaryButton(
                icon: Icons.arrow_back,
                label: 'Kembali ke Pratinjau',
                onPressed: viewModel.reset,
              ),
            ],
          ),
        },
      ),
    );
  }

  Widget _message(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required List<Widget> actions,
  }) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            const SizedBox(width: AppSpacing.xs),
            const SampleBadge(),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(description, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        for (final action in actions) ...[
          action,
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

  Widget _result(BuildContext context) {
    final CatalogProduct? product = viewModel.detectedProduct;
    if (product == null) {
      return _message(
        context,
        icon: Icons.search_off_outlined,
        color: AppColors.muted,
        title: 'Belum ada hasil',
        description: 'Coba kembali ke pratinjau pemindai.',
        actions: [PrimaryAction(label: 'Kembali', onPressed: viewModel.reset)],
      );
    }

    final theme = Theme.of(context);
    final isSimulated = viewModel.isSimulated;
    final outOfStock = product.stock == 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                isSimulated ? 'Hasil simulasi' : 'Dipilih manual',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SampleBadge(),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(product.name, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${formatRupiah(product.price)} / ${product.unit}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Lokasi: ${product.locationLabel}',
          style: theme.textTheme.bodyMedium,
        ),
        if (product.barcode != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text('Barcode: ${product.barcode}', style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(
              isSimulated
                  ? Icons.query_stats_outlined
                  : Icons.touch_app_outlined,
              color: AppColors.muted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                isSimulated
                    ? 'Produk simulasi dari katalog warung.'
                    : 'Produk dipilih dari daftar katalog.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        if (outOfStock) ...[
          const SizedBox(height: AppSpacing.sm),
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: AppSpacing.xs),
              Expanded(child: Text('Stok produk habis; pilih produk lain.')),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        PrimaryAction(
          label: 'Konfirmasi ke Keranjang',
          icon: Icons.add_shopping_cart,
          onPressed: outOfStock ? null : onConfirm,
        ),
        if (onHighlightOnFloorPlan != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _secondaryButton(
            icon: Icons.map_outlined,
            label: 'Lihat di Denah',
            onPressed: onHighlightOnFloorPlan!,
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        _secondaryButton(
          icon: Icons.refresh,
          label: 'Pindai Ulang',
          onPressed: viewModel.reset,
        ),
      ],
    );
  }

  Widget _secondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpacing.minTouchTarget),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.controlBorder,
        ),
      ),
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
