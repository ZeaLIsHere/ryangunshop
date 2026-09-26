import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/features/catalog/model/catalog_product.dart';
import 'package:ryangunshop/features/catalog/sample/catalog_sample.dart';
import 'package:ryangunshop/features/checkout/sample/checkout_sample.dart';
import 'package:ryangunshop/features/payment/model/payment_preview.dart';
import 'package:ryangunshop/features/payment/sample/payment_sample.dart';

void main() {
  test('stok nol, ambang menipis, dan stok cukup dibedakan', () {
    final products = CatalogSample.products;
    expect(products.first.stockStatus, ProductStockStatus.available);
    expect(products[2].stockStatus, ProductStockStatus.empty);
    expect(products.last.stock, products.last.lowStockThreshold);
    expect(products.last.stockStatus, ProductStockStatus.low);
  });

  test('snapshot keranjang sesuai nominal contoh pembayaran', () {
    final total = CheckoutSample.items.fold(
      0,
      (sum, item) => sum + item.subtotal,
    );
    expect(total, 23000);
    expect(PaymentSample.cash.total, total);
    expect(PaymentSample.cash.change, 2000);
    expect(
      PaymentSample.qrisScenarios.map((item) => item.qrisStatus),
      QrisStatus.values,
    );
    expect(
      PaymentSample.qrisScenarios.every((item) => item.total == total),
      isTrue,
    );
  });

  test('kembalian hanya muncul saat tunai mencukupi', () {
    for (final received in <int?>[null, 0, 22999]) {
      final preview = PaymentPreview(
        total: 23000,
        method: PaymentMethod.cash,
        cashReceived: received,
      );
      expect(preview.change, isNull);
    }
    expect(
      const PaymentPreview(
        total: 23000,
        method: PaymentMethod.cash,
        cashReceived: 23000,
      ).change,
      0,
    );
    expect(PaymentSample.qrisScenarios.last.change, isNull);
  });
}
