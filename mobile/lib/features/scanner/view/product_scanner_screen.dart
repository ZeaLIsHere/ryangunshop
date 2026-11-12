import 'package:flutter/material.dart';

import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/model/catalog_product.dart';
import '../model/scanner_scenario.dart';
import '../view_model/scanner_view_model.dart';
import 'manual_product_search_screen.dart';
import 'scanner_status_panel.dart';

/// Pratinjau alur pemindai tanpa kamera atau deteksi produk nyata.
class ProductScannerScreen extends StatefulWidget {
  const ProductScannerScreen({
    this.onHighlightOnFloorPlan,
    this.viewModel,
    super.key,
  });

  final ValueChanged<String>? onHighlightOnFloorPlan;
  final ScannerViewModel? viewModel;

  @override
  State<ProductScannerScreen> createState() => _ProductScannerScreenState();
}

class _ProductScannerScreenState extends State<ProductScannerScreen> {
  late ScannerViewModel _viewModel;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? ScannerViewModel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && widget.viewModel == null) {
      _initialized = true;
      _loadScannerProducts();
    }
  }

  Future<void> _loadScannerProducts() async {
    final session = AppSessionScope.of(context);
    if (session.database == null) return;
    try {
      final records = await session.productRepository.listProducts();
      if (!mounted) return;
      setState(() {
        _viewModel = ScannerViewModel(
          products: records.map(CatalogProduct.fromRecord).toList(),
        );
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    if (widget.viewModel == null) _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openManualSearch() async {
    final session = AppSessionScope.of(context);
    ScannerViewModel? localViewModel;
    if (session.database != null) {
      try {
        final records = await session.productRepository.listProducts();
        if (!mounted) return;
        localViewModel = ScannerViewModel(
          products: records.map(CatalogProduct.fromRecord).toList(),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk lokal gagal dimuat. Coba lagi.'),
          ),
        );
        return;
      }
    }
    final searchViewModel = localViewModel ?? _viewModel;
    final product = await Navigator.of(context).push<CatalogProduct>(
      MaterialPageRoute(
        builder: (_) => ManualProductSearchScreen(
          viewModel: searchViewModel,
          isLocal: session.database != null,
        ),
      ),
    );
    localViewModel?.dispose();
    if (!mounted || product == null) return;
    _viewModel.selectManualProduct(product);
  }

  Future<void> _confirmProduct() async {
    final product = _viewModel.detectedProduct;
    if (product == null || product.stock == 0) return;
    final session = AppSessionScope.of(context);
    var selected = product;
    if (session.database != null) {
      try {
        final products = await session.productRepository.listProducts();
        if (!mounted) return;
        final matches = products.where((record) => record.id == product.id);
        if (matches.isEmpty || matches.first.stock == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produk ini belum tersimpan atau stoknya habis.'),
            ),
          );
          return;
        }
        selected = CatalogProduct.fromRecord(matches.first);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk lokal gagal diperiksa. Coba lagi.'),
          ),
        );
        return;
      }
    }
    session.cart.addProduct(selected);
    _viewModel.markAdded();
  }

  void _highlightOnFloorPlan() {
    final fixtureId = _viewModel.detectedProduct?.fixtureId;
    if (fixtureId == null) return;
    Navigator.of(context).pop();
    widget.onHighlightOnFloorPlan?.call(fixtureId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.ink,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: _SimulatedCameraPreview(
                  scenario: _viewModel.scenario,
                  isTorchOn: _viewModel.isTorchOn,
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.screen,
                right: AppSpacing.screen,
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Kembali',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Pemindai Produk',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.surface),
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: Icon(
                        _viewModel.isTorchOn ? Icons.flash_on : Icons.flash_off,
                      ),
                      tooltip: _viewModel.isTorchOn
                          ? 'Matikan Lampu Simulasi'
                          : 'Nyalakan Lampu Simulasi',
                      onPressed:
                          _viewModel.scenario ==
                                  ScannerScenario.permissionDenied ||
                              _viewModel.scenario == ScannerScenario.failure
                          ? null
                          : _viewModel.toggleTorch,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.search),
                      tooltip: 'Cari Produk Manual',
                      onPressed: _openManualSearch,
                    ),
                    PopupMenuButton<ScannerScenario>(
                      tooltip: 'Pilih Skenario Contoh',
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.surface,
                      ),
                      onSelected: _viewModel.selectScenario,
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: ScannerScenario.ready,
                          child: Text('Siap memindai'),
                        ),
                        PopupMenuItem(
                          value: ScannerScenario.loading,
                          child: Text('Memuat hasil'),
                        ),
                        PopupMenuItem(
                          value: ScannerScenario.empty,
                          child: Text('Tidak ditemukan'),
                        ),
                        PopupMenuItem(
                          value: ScannerScenario.permissionDenied,
                          child: Text('Izin kamera ditolak'),
                        ),
                        PopupMenuItem(
                          value: ScannerScenario.failure,
                          child: Text('Kamera gagal'),
                        ),
                        PopupMenuItem(
                          value: ScannerScenario.offline,
                          child: Text('Mode offline'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: AppSpacing.screen,
                right: AppSpacing.screen,
                bottom: AppSpacing.screen,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.68,
                  ),
                  child: SingleChildScrollView(
                    child: ScannerStatusPanel(
                      viewModel: _viewModel,
                      onManualSearch: _openManualSearch,
                      onConfirm: _confirmProduct,
                      onHighlightOnFloorPlan:
                          widget.onHighlightOnFloorPlan == null
                          ? null
                          : _highlightOnFloorPlan,
                      onReturnToCheckout: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimulatedCameraPreview extends StatelessWidget {
  const _SimulatedCameraPreview({
    required this.scenario,
    required this.isTorchOn,
  });

  final ScannerScenario scenario;
  final bool isTorchOn;

  @override
  Widget build(BuildContext context) {
    final unavailable =
        scenario == ScannerScenario.permissionDenied ||
        scenario == ScannerScenario.failure;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isTorchOn
              ? [AppColors.primary, AppColors.primaryDark]
              : [AppColors.primaryDark, AppColors.ink],
        ),
      ),
      child: Align(
        alignment: const Alignment(0, -0.42),
        child: FractionallySizedBox(
          widthFactor: 0.62,
          child: AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: unavailable ? AppColors.warning : AppColors.accent,
                  width: AppSpacing.base / 2,
                ),
                borderRadius: AppRadius.panelBorder,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    unavailable
                        ? Icons.videocam_off_outlined
                        : Icons.qr_code_scanner,
                    color: AppColors.surface,
                    size: AppSpacing.minTouchTarget,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Kamera tidak aktif',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.surface),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    isTorchOn
                        ? 'Lampu simulasi aktif'
                        : 'Arahkan barcode ke bingkai kamera',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.primaryLight),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
