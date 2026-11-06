import 'package:flutter/foundation.dart';

import '../../catalog/model/catalog_product.dart';
import '../model/cart_item.dart';

/// ViewModel untuk mengelola keranjang transaksi kasir.
class CartViewModel extends ChangeNotifier {
  final List<CartItem> _items = [
    const CartItem(
      productId: 'contoh-produk-1',
      productName: 'Beras pandan wangi 1 kg',
      unitPrice: 16000,
      quantity: 1,
      unit: 'bungkus',
    ),
    const CartItem(
      productId: 'contoh-produk-4',
      productName: 'Mi instan goreng',
      unitPrice: 3500,
      quantity: 2,
      unit: 'bungkus',
    ),
  ];

  int _discount = 0;
  String _note = '';

  List<CartItem> get items => List.unmodifiable(_items);
  int get discount => _discount;
  String get note => _note;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  int get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);

  int get total {
    final calc = subtotal - _discount;
    return calc < 0 ? 0 : calc;
  }

  bool get isEmpty => _items.isEmpty;

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
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
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

  void clearCart() {
    _items.clear();
    _discount = 0;
    _note = '';
    notifyListeners();
  }
}
