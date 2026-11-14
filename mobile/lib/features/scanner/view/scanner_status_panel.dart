import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_action.dart';
import '../model/scanner_scenario.dart';
import '../view_model/scanner_view_model.dart';
import 'scanner_camera.dart';

class ScannerStatusPanel extends StatelessWidget {
  const ScannerStatusPanel({
    required this.viewModel,
    required this.camera,
    required this.onRetryCamera,
    required this.onManualSearch,
    required this.onConfirm,
    required this.onReturnToCheckout,
    required this.onDetail,
    this.onAddProduct,
    super.key,
  });

  final ScannerViewModel viewModel;
  final ScannerCamera camera;
  final VoidCallback onRetryCamera;
  final VoidCallback onManualSearch;
  final VoidCallback onConfirm;
  final VoidCallback onReturnToCheckout;
  final VoidCallback onDetail;
  final VoidCallback? onAddProduct;

  Widget _button(String label, VoidCallback? action, IconData icon) =>
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.minTouchTarget),
        ),
        onPressed: action,
        icon: Icon(icon),
        label: Text(label),
      );

  @override
  Widget build(BuildContext context) {
    final model = viewModel;
    final product = model.detectedProduct;
    final ready = model.scanning;
    final title = ready
        ? !camera.supported
              ? 'Kamera Android tidak tersedia'
              : camera.requesting
              ? 'Meminta izin / menyiapkan kamera'
              : camera.denied
              ? 'Izin kamera ditolak'
              : camera.error != null
              ? 'Kamera gagal'
              : camera.running
              ? 'Siap memindai barcode'
              : 'Kamera dijeda'
        : switch (model.scenario) {
            ScannerScenario.loading => 'Mencari produk',
            ScannerScenario.result => 'Konfirmasi produk',
            ScannerScenario.added => 'Produk masuk keranjang',
            ScannerScenario.empty => 'Produk tidak ditemukan',
            _ => 'Katalog gagal dibaca',
          };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.panelBorder,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  model.error != null || camera.error != null
                      ? Icons.warning_amber_rounded
                      : Icons.qr_code_scanner,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (ready)
              Text(
                !camera.supported
                    ? 'Pemindaian kamera hanya tersedia di Android. Pilih produk lewat pencarian manual.'
                    : camera.error ?? 'Arahkan barcode produk ke kamera. Deteksi dan pencarian lokal bekerja tanpa internet. Bingkai kamera tidak diunggah.',
              ),
            if (model.code != null) Text('Barcode: ${model.code}'),
            if (model.error != null)
              Text(
                model.error!,
                style: const TextStyle(color: AppColors.error),
              ),
            if (model.scenario == ScannerScenario.empty)
              Text(
                onAddProduct != null
                    ? 'Barcode belum terdaftar. Cari manual atau tambahkan produk baru.'
                    : 'Barcode belum terdaftar. Cari produk manual atau minta pemilik menambahkannya.',
              ),
            if (model.scenario == ScannerScenario.loading)
              const LinearProgressIndicator(),
            if (model.scenario == ScannerScenario.result &&
                product != null) ...[
              Text(product.name, style: Theme.of(context).textTheme.titleLarge),
              Text(
                '${formatRupiah(product.price)} / ${product.unit} · Stok ${product.stock}',
              ),
              if (product.stock == 0)
                const Text('Stok habis; produk tidak dapat ditambahkan.'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Kurangi jumlah',
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                    onPressed: !model.confirming && model.quantity > 1
                        ? () => model.changeQuantity(model.quantity - 1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Flexible(child: Text('Jumlah ${model.quantity}')),
                  IconButton(
                    tooltip: 'Tambah jumlah',
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                    onPressed:
                        !model.confirming && model.quantity < product.stock
                        ? () => model.changeQuantity(model.quantity + 1)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              PrimaryAction(
                label: model.confirming
                    ? 'Memeriksa stok…'
                    : 'Konfirmasi ke Keranjang',
                onPressed: product.stock > 0 && !model.confirming
                    ? onConfirm
                    : null,
              ),
              _button(
                'Detail Produk',
                model.confirming ? null : onDetail,
                Icons.info_outline,
              ),
            ],
            if (ready &&
                camera.supported &&
                !camera.requesting &&
                camera.error != null)
              _button('Coba Izin / Kamera Lagi', onRetryCamera, Icons.refresh),
            if (model.scenario == ScannerScenario.failure && model.code != null)
              _button('Coba Pencarian Lagi', model.retryLookup, Icons.refresh),
            if (model.scenario == ScannerScenario.empty && onAddProduct != null)
              _button('Tambah Produk', onAddProduct, Icons.add),
            if (!ready && model.scenario != ScannerScenario.loading)
              _button(
                'Pindai Lagi',
                model.confirming ? null : model.reset,
                Icons.qr_code_scanner,
              ),
            _button(
              'Cari Produk Manual',
              model.confirming ? null : onManualSearch,
              Icons.search,
            ),
            if (model.scenario == ScannerScenario.added ||
                model.scenario == ScannerScenario.result)
              _button(
                'Kembali ke Kasir',
                model.confirming ? null : onReturnToCheckout,
                Icons.shopping_cart_outlined,
              ),
          ],
        ),
      ),
    );
  }
}
