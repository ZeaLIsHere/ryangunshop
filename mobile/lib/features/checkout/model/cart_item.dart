/// Snapshot UI keranjang, agar perubahan katalog tidak mengubah harga item.
class CartItem {
  const CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.unit,
  }) : assert(unitPrice >= 0),
       assert(quantity > 0);

  final String productId;
  final String productName;
  final int unitPrice;
  final int quantity;
  final String unit;

  int get subtotal => unitPrice * quantity;
}
