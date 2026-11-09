class ProductRecord {
  const ProductRecord({
    required this.id,
    required this.barcode,
    required this.name,
    required this.salePrice,
    required this.stock,
  });

  final String id;
  final String barcode;
  final String name;
  final int salePrice;
  final int stock;

  ProductRecord copyWith({int? stock}) => ProductRecord(
    id: id,
    barcode: barcode,
    name: name,
    salePrice: salePrice,
    stock: stock ?? this.stock,
  );
}
