import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/session/app_session.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../catalog/model/catalog_product.dart';
import '../../../core/format/rupiah.dart';
import '../../catalog/view/product_form_screen.dart';
import '../../checkout/view/cart_checkout_screen.dart';
import '../view_model/scanner_view_model.dart';
import 'manual_product_search_screen.dart';
import 'scanner_camera.dart';
import 'scanner_status_panel.dart';

class ProductScannerScreen extends StatefulWidget {
  const ProductScannerScreen({
    this.onHighlightOnFloorPlan,
    this.viewModel,
    this.camera,
    super.key,
  });

  final ValueChanged<String>? onHighlightOnFloorPlan;
  final ScannerViewModel? viewModel;
  final ScannerCamera? camera;

  @override
  State<ProductScannerScreen> createState() => _ProductScannerScreenState();
}

class _ProductScannerScreenState extends State<ProductScannerScreen>
    with WidgetsBindingObserver {
  late final ScannerCamera _camera;
  ScannerViewModel? _model;
  ModalRoute<dynamic>? _route;
  bool _visible = true;
  bool _foreground = true;
  bool _closing = false;
  Future<void> _cameraQueue = Future.value();

  @override
  void initState() {
    super.initState();
    _camera = widget.camera ?? AndroidScannerCamera();
    _camera.addListener(_cameraChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_model == null) {
      _model =
          widget.viewModel ??
          ScannerViewModel(
            repository: AppSessionScope.of(context).productRepository,
          );
      _model!.addListener(_syncCamera);
    }
    final route = ModalRoute.of(context);
    if (_route != route) {
      _route?.secondaryAnimation?.removeListener(_syncCamera);
      _route = route;
      _route?.secondaryAnimation?.addListener(_syncCamera);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncCamera();
    });
  }

  void _cameraChanged() {
    if (mounted) setState(() {});
  }

  bool get _wantCamera =>
      !_closing &&
      mounted &&
      _visible &&
      _foreground &&
      (_route?.isCurrent ?? true) &&
      _model!.scanning;

  void _syncCamera() {
    _cameraQueue = _cameraQueue.then((_) async {
      if (_closing) return;
      if (_wantCamera) {
        // Izin ditolak tidak diminta ulang tanpa tindakan pengguna.
        if (_camera.error == null) await _camera.start();
      } else {
        await _camera.stop();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncCamera();
  }

  Future<T?> _withoutCamera<T>(Future<T?> Function() action) async {
    _visible = false;
    _syncCamera();
    await _cameraQueue;
    if (!mounted) return null;
    try {
      return await action();
    } finally {
      _visible = true;
      if (mounted) _syncCamera();
    }
  }

  Future<void> _manualSearch() async {
    await _withoutCamera(() async {
      final product = await Navigator.of(context).push<CatalogProduct>(
        MaterialPageRoute(
          builder: (_) => ManualProductSearchScreen(viewModel: _model!),
        ),
      );
      if (mounted && product != null) _model!.selectManualProduct(product);
      return product;
    });
  }

  Future<void> _addProduct() async {
    final session = AppSessionScope.of(context);
    if (!session.role.canManageProducts) return;
    await _withoutCamera(() async {
      try {
        final products = await _model!.loadProducts();
        if (!mounted || !session.role.canManageProducts) return null;
        final draft = await Navigator.of(context).push<CatalogProduct>(
          MaterialPageRoute(
            builder: (_) => ProductFormScreen(
              initialBarcode: _model!.code,
              existingProducts: products,
              isLocal: true,
            ),
          ),
        );
        if (!mounted || draft == null) return null;
        if (!session.role.canManageProducts) {
          throw StateError('Izin pemilik diperlukan');
        }
        if (draft.barcode != null &&
            await session.productRepository.findByBarcode(draft.barcode!) !=
                null) {
          throw StateError('Barcode sudah terdaftar');
        }
        if (!mounted || !session.role.canManageProducts) return null;
        await session.productRepository.save(draft.toRecord());
        if (mounted) _model!.selectManualProduct(draft);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Produk gagal disimpan. Periksa katalog dan coba lagi.',
              ),
            ),
          );
        }
      }
      return null;
    });
  }

  Future<void> _detail() async {
    final product = _model!.detectedProduct;
    if (product == null) return;
    await _withoutCamera(
      () => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(product.name),
          content: SingleChildScrollView(
            child: Text(
              '${formatRupiah(product.price)} / ${product.unit}\nStok ${product.stock}\n${product.locationLabel}\nBarcode: ${product.barcode ?? 'Tanpa barcode'}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkout() async {
    await _withoutCamera(
      () => Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const CartCheckoutScreen()),
      ),
    );
  }

  @override
  void dispose() {
    _closing = true;
    WidgetsBinding.instance.removeObserver(this);
    _route?.secondaryAnimation?.removeListener(_syncCamera);
    _camera.removeListener(_cameraChanged);
    _model?.removeListener(_syncCamera);
    if (widget.viewModel == null) _model?.dispose();
    unawaited(_cameraQueue.then((_) => _camera.close()));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _model!,
    builder: (context, _) => Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        title: const Text('Pemindai Produk'),
        actions: [
          if (_camera.torchAvailable)
            IconButton(
              constraints: const BoxConstraints(
                minWidth: AppSpacing.minTouchTarget,
                minHeight: AppSpacing.minTouchTarget,
              ),
              tooltip: _camera.torchOn ? 'Matikan Lampu' : 'Nyalakan Lampu',
              icon: Icon(_camera.torchOn ? Icons.flash_on : Icons.flash_off),
              onPressed: _camera.toggleTorch,
            ),
          IconButton(
            constraints: const BoxConstraints(
              minWidth: AppSpacing.minTouchTarget,
              minHeight: AppSpacing.minTouchTarget,
            ),
            tooltip: 'Cari Produk Manual',
            icon: const Icon(Icons.search),
            onPressed: _manualSearch,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _camera.preview((code) {
                if (_wantCamera) unawaited(_model!.detect(code));
              }),
            ),
            if (_camera.running && _model!.scanning)
              const Align(
                alignment: Alignment(0, -0.5),
                child: IgnorePointer(
                  child: Icon(
                    Icons.crop_free,
                    size: AppSpacing.minTouchTarget * 3,
                    color: AppColors.surface,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.68,
                  ),
                  child: SingleChildScrollView(
                    child: ScannerStatusPanel(
                      viewModel: _model!,
                      camera: _camera,
                      onRetryCamera: () async {
                        await _cameraQueue;
                        if (_wantCamera) await _camera.start();
                      },
                      onManualSearch: _manualSearch,
                      onConfirm: () async {
                        final session = AppSessionScope.of(context);
                        await session.loadLocalCart();
                        if (!context.mounted) return;
                        if (!session.isLocalCartReady) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Keranjang gagal dimuat. Coba lagi.',
                              ),
                            ),
                          );
                          return;
                        }
                        await _model!.confirm(session.cart);
                      },
                      onDetail: _detail,
                      onReturnToCheckout: _checkout,
                      onAddProduct:
                          AppSessionScope.of(context).role.canManageProducts
                          ? _addProduct
                          : null,
                    ),
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
