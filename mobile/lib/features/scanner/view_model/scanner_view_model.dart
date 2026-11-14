import 'package:flutter/foundation.dart';

import '../../../core/data/product_repository.dart';
import '../../catalog/model/catalog_product.dart';
import '../../checkout/view_model/cart_view_model.dart';
import '../model/scanner_scenario.dart';

class ScannerViewModel extends ChangeNotifier {
  ScannerViewModel({required this.repository});

  final ProductRepository repository;
  ScannerScenario scenario = ScannerScenario.ready;
  CatalogProduct? detectedProduct;
  String? code;
  String? error;
  int quantity = 1;
  bool confirming = false;
  bool _disposed = false;
  int _revision = 0;

  bool get scanning => scenario == ScannerScenario.ready;

  Future<List<CatalogProduct>> loadProducts() async =>
      (await repository.listProducts()).map(CatalogProduct.fromRecord).toList();

  Future<void> detect(String raw) async {
    if (!scanning || raw.trim().isEmpty || raw.length > 4096) return;
    code = raw.trim();
    await retryLookup();
  }

  Future<void> retryLookup() async {
    if (code == null || scenario == ScannerScenario.loading || confirming) {
      return;
    }
    final revision = ++_revision;
    scenario = ScannerScenario.loading;
    error = null;
    detectedProduct = null;
    notifyListeners();
    try {
      final record = await repository.findByBarcode(code!);
      if (_disposed || revision != _revision) return;
      detectedProduct = record == null
          ? null
          : CatalogProduct.fromRecord(record);
      quantity = 1;
      scenario = record == null
          ? ScannerScenario.empty
          : ScannerScenario.result;
    } catch (_) {
      if (_disposed || revision != _revision) return;
      scenario = ScannerScenario.failure;
      error = 'Katalog gagal dibaca. Barcode tetap tersimpan; coba lagi.';
    }
    notifyListeners();
  }

  void selectManualProduct(CatalogProduct product) {
    if (confirming) return;
    _revision++;
    code = product.barcode;
    detectedProduct = product;
    quantity = 1;
    error = null;
    scenario = ScannerScenario.result;
    notifyListeners();
  }

  void changeQuantity(int value) {
    if (confirming || value < 1 || value > (detectedProduct?.stock ?? 0)) {
      return;
    }
    quantity = value;
    notifyListeners();
  }

  Future<void> confirm(CartViewModel cart) async {
    final product = detectedProduct;
    if (confirming || scenario != ScannerScenario.result || product == null) {
      return;
    }
    confirming = true;
    error = null;
    notifyListeners();
    try {
      final records = await repository.listProducts();
      if (_disposed) return;
      final matches = records.where((p) => p.id == product.id);
      if (matches.isEmpty) {
        detectedProduct = null;
        scenario = ScannerScenario.empty;
        error = 'Produk sudah dihapus dari katalog.';
        return;
      }
      final fresh = CatalogProduct.fromRecord(matches.single);
      detectedProduct = fresh;
      final inCart = cart.items
          .where((p) => p.productId == fresh.id)
          .fold(0, (sum, p) => sum + p.quantity);
      if (quantity > fresh.stock - inCart) {
        error = 'Stok tidak cukup. Stok ${fresh.stock}, di keranjang $inCart.';
        quantity = (fresh.stock - inCart).clamp(
          1,
          fresh.stock > 0 ? fresh.stock : 1,
        );
        return;
      }
      if (fresh.price != product.price) {
        error = 'Harga berubah. Periksa harga terbaru lalu konfirmasi ulang.';
        return;
      }
      final oldLines = cart.items.where((p) => p.productId == fresh.id);
      if (oldLines.any((p) => p.unitPrice != fresh.price)) {
        error = 'Harga di keranjang berbeda. Periksa produk di Kasir dahulu.';
        return;
      }
      cart.addProduct(fresh, quantity: quantity);
      scenario = ScannerScenario.added;
    } catch (_) {
      if (!_disposed) {
        error = 'Produk gagal diperiksa. Belum ditambahkan; coba lagi.';
      }
    } finally {
      confirming = false;
      if (!_disposed) notifyListeners();
    }
  }

  void reset() {
    if (confirming) return;
    _revision++;
    scenario = ScannerScenario.ready;
    detectedProduct = null;
    code = null;
    error = null;
    quantity = 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }
}
