import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/format/rupiah.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_action.dart';
import '../../catalog/model/catalog_product.dart';
import '../../catalog/sample/catalog_sample.dart';

/// Layar pemindai barcode / kamera kasir RyanGunshop.
class ProductScannerScreen extends StatefulWidget {
  const ProductScannerScreen({this.onHighlightOnFloorPlan, super.key});

  /// Dipanggil jika kasir ingin melihat lokasi rak produk yang terdeteksi di denah.
  final ValueChanged<String>? onHighlightOnFloorPlan;

  @override
  State<ProductScannerScreen> createState() => _ProductScannerScreenState();
}

class _ProductScannerScreenState extends State<ProductScannerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanAnimController;
  Timer? _detectionTimer;
  bool _isTorchOn = false;
  CatalogProduct? _detectedProduct;
  bool _hasPermission = true;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Otomatis deteksi salah satu produk contoh setelah layar dibuka sebentar
    _detectionTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _detectedProduct = CatalogSample.products[3]; // Mi instan
        });
      }
    });
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _scanAnimController.dispose();
    super.dispose();
  }

  void _manualBarcodeDialog() {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Input Barcode Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nomor Barcode / Kode Produk',
                hintText: 'Contoh: CONTOH-001',
                prefixIcon: Icon(Icons.qr_code),
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Pilih cepat barcode barang:',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final prod in CatalogSample.products)
                  if (prod.barcode != null)
                    ActionChip(
                      label: Text(
                        prod.barcode!,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () {
                        controller.text = prod.barcode!;
                      },
                    ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final query = controller.text.trim().toLowerCase();
              final match = CatalogSample.products.firstWhere(
                (p) =>
                    p.barcode?.toLowerCase() == query ||
                    p.name.toLowerCase().contains(query),
                orElse: () => CatalogSample.products.first,
              );
              setState(() {
                _detectedProduct = match;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Cari'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AppSessionScope.of(context);

    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pemindai')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.videocam_off_outlined,
                  size: 56,
                  color: AppColors.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Izin Kamera Dibutuhkan',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Aktifkan izin kamera untuk memindai barcode produk secara otomatis.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryAction(
                  label: 'Beri Izin Kamera',
                  onPressed: () => setState(() => _hasPermission = true),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _manualBarcodeDialog,
                  child: const Text('Gunakan Barcode Manual'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Simulated Camera Viewport
            Center(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        Colors.blueGrey.shade900.withValues(alpha: 0.8),
                        Colors.black,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _detectedProduct != null
                              ? AppColors.success
                              : AppColors.accent,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          // Animated scan laser beam
                          AnimatedBuilder(
                            animation: _scanAnimController,
                            builder: (context, _) {
                              return Positioned(
                                top: 236 * _scanAnimController.value,
                                left: 8,
                                right: 8,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: _detectedProduct != null
                                        ? AppColors.success
                                        : AppColors.accent,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (_detectedProduct != null
                                                    ? AppColors.success
                                                    : AppColors.accent)
                                                .withValues(alpha: 0.8),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Center(
                            child: Icon(
                              Icons.qr_code_scanner,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Top Bar Controls: Flash, Close, Flip
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.screen,
              right: AppSpacing.screen,
              child: Row(
                children: [
                  IconButton.filled(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Kembali',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  IconButton.filled(
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: _isTorchOn ? Colors.amber : Colors.white,
                    ),
                    tooltip: _isTorchOn ? 'Matikan Lampu' : 'Nyalakan Lampu',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _isTorchOn = !_isTorchOn;
                      });
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.filled(
                    icon: const Icon(Icons.keyboard, color: Colors.white),
                    tooltip: 'Input Manual',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                    ),
                    onPressed: _manualBarcodeDialog,
                  ),
                ],
              ),
            ),

            // Bottom Product Detected Card
            Positioned(
              bottom: AppSpacing.md,
              left: AppSpacing.screen,
              right: AppSpacing.screen,
              child: _detectedProduct == null
                  ? Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: AppRadius.controlBorder,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Arahkan kamera ke barcode produk...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.panelBorder,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDark.withValues(
                              alpha: 0.32,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: AppColors.success,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Barcode Valid',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _detectedProduct!.barcode ?? '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _detectedProduct!.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: AppSpacing.sm,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${formatRupiah(_detectedProduct!.price)} / ${_detectedProduct!.unit}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '• ${_detectedProduct!.locationLabel}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.map_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Lihat di Denah'),
                                  onPressed: () {
                                    final fixtureId =
                                        _detectedProduct!.fixtureId;
                                    Navigator.of(context).pop();
                                    widget.onHighlightOnFloorPlan?.call(
                                      fixtureId,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: FilledButton.icon(
                                  icon: const Icon(
                                    Icons.add_shopping_cart,
                                    size: 18,
                                  ),
                                  label: const Text('+ Keranjang'),
                                  onPressed: () {
                                    session.cart.addProduct(_detectedProduct!);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${_detectedProduct!.name} dimasukkan ke kasir',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
