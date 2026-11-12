import 'package:flutter/foundation.dart';

import '../../catalog/model/catalog_product.dart';
import '../model/cart_item.dart';
import '../model/cart_scenario.dart';

/// ViewModel untuk mengelola keranjang transaksi kasir.
class CartViewModel extends ChangeNotifier {
  CartViewModel({bool withSampleItems = false})
    : _items = withSampleItems ? List.of(_sampleItems) : <CartItem>[];

  static const _sampleItems = <CartItem>[
    CartItem(
      productId: 'contoh-produk-1',
      productName: 'Beras pandan wangi 1 kg',
      unitPrice: 16000,
      quantity: 1,
      unit: 'bungkus',
    ),
    CartItem(
      productId: 'contoh-produk-4',
      productName: 'Mi instan goreng',
      unitPrice: 3500,
      quantity: 2,
      unit: 'bungkus',
    ),
  ];

  final List<CartItem> _items;

  int _discount = 0;
  String _note = '';
  CartScenario _scenario = CartScenario.ready;

  List<CartItem> get items => List.unmodifiable(_items);
  int get discount => _discount;
  String get note => _note;
  CartScenario get scenario => _scenario;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  int get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);

  int get total {
    final calc = subtotal - _discount;
    return calc < 0 ? 0 : calc;
  }

  bool get isEmpty => _items.isEmpty;

  void selectScenario(CartScenario scenario) {
    if (_scenario == scenario) return;
    _scenario = scenario;
    notifyListeners();
  }

  void resetScenario() => selectScenario(CartScenario.ready);

  void addProduct(CatalogProduct product, {int quantity = 1}) {
    final index = _items.indexWhere((item) => item.productId == product.id);
    if (index >= 0) {
      final existing = _items[index];
      _items[index] = CartItem(
        productId: existing.productId,
        productName: existing.productName,
        unitPrice: existing.unitPrice,
        quantity: existing.quantity + quantity,
        unit: existing.unit,
      );
    } else {
      _items.add(
        CartItem(
          productId: product.id,
          productName: product.name,
          unitPrice: product.price,
          quantity: quantity,
          unit: product.unit,
        ),
      );
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      final existing = _items[index];
      _items[index] = CartItem(
        productId: existing.productId,
        productName: existing.productName,
        unitPrice: existing.unitPrice,
        quantity: newQuantity,
        unit: existing.unit,
      );
      _discount = _discount.clamp(0, subtotal);
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    _discount = _discount.clamp(0, subtotal);
    notifyListeners();
  }

  void setDiscount(int discount) {
    _discount = discount.clamp(0, subtotal);
    notifyListeners();
  }

  void setNote(String note) {
    _note = note;
    notifyListeners();
  }

  void restoreDraft(
    List<CartItem> items, {
    int discount = 0,
    String note = '',
  }) {
    _items
      ..clear()
      ..addAll(items);
    _discount = discount.clamp(0, subtotal);
    _note = note;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _discount = 0;
    _note = '';
    notifyListeners();
  }
}
