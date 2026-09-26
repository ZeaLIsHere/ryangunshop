import '../model/cart_item.dart';

abstract final class CheckoutSample {
  /// Snapshot contoh; belum ada aksi menambah barang atau transaksi nyata.
  static const items = <CartItem>[
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
}
