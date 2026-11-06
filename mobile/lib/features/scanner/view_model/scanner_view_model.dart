import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../catalog/model/catalog_product.dart';
import '../model/scanner_scenario.dart';
import '../sample/scanner_sample.dart';

/// Mengelola state simulasi pemindaian dan pencarian produk contoh.
class ScannerViewModel extends ChangeNotifier {
  ScannerViewModel({List<CatalogProduct> products = ScannerSample.products})
    : _products = List.unmodifiable(products);

  final List<CatalogProduct> _products;
  Timer? _scanTimer;
  bool _disposed = false;
  ScannerScenario _scenario = ScannerScenario.ready;
  CatalogProduct? _detectedProduct;
  double? _confidence;
  bool _isTorchOn = false;

  ScannerScenario get scenario => _scenario;
  CatalogProduct? get detectedProduct => _detectedProduct;
  double? get confidence => _confidence;
  bool get isTorchOn => _isTorchOn;

  List<CatalogProduct> searchProducts(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return _products;
    return _products.where((product) {
      return product.name.toLowerCase().contains(normalized) ||
          (product.barcode?.toLowerCase().contains(normalized) ?? false);
    }).toList();
  }

  void simulateScan() {
    _scanTimer?.cancel();
    _detectedProduct = null;
    _confidence = null;
    _scenario = ScannerScenario.loading;
    notifyListeners();

    _scanTimer = Timer(const Duration(milliseconds: 900), () {
      if (_disposed) return;
      for (final product in _products) {
        if (product.id == ScannerSample.detectedProductId) {
          _detectedProduct = product;
          break;
        }
      }
      _confidence = _detectedProduct == null ? null : ScannerSample.confidence;
      _scenario = _detectedProduct == null
          ? ScannerScenario.empty
          : ScannerScenario.result;
      notifyListeners();
    });
  }

  void selectManualProduct(CatalogProduct product) {
    _scanTimer?.cancel();
    _detectedProduct = product;
    _confidence = null;
    _scenario = ScannerScenario.result;
    notifyListeners();
  }

  void markAdded() {
    if (_scenario != ScannerScenario.result || _detectedProduct == null) return;
    _scenario = ScannerScenario.added;
    notifyListeners();
  }

  void selectScenario(ScannerScenario scenario) {
    if (scenario == ScannerScenario.loading) {
      simulateScan();
      return;
    }
    _scanTimer?.cancel();
    _detectedProduct = null;
    _confidence = null;
    _isTorchOn = false;
    _scenario = scenario;
    notifyListeners();
  }

  void reset() => selectScenario(ScannerScenario.ready);

  void toggleTorch() {
    _isTorchOn = !_isTorchOn;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _scanTimer?.cancel();
    super.dispose();
  }
}
