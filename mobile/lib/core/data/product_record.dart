class ProductRecord {
  const ProductRecord({
    required this.id,
    this.barcode,
    required this.name,
    required this.salePrice,
    required this.stock,
    this.costPrice = 0,
    this.category = 'Lainnya',
    this.unit = 'pcs',
    this.fixtureId = '',
    this.locationLabel = 'Belum ditentukan',
    this.lowStockThreshold = 5,
  });

  final String id;
  final String? barcode;
  final String name;
  final int salePrice;
  final int stock;
  final int costPrice;
  final String category;
  final String unit;
  final String fixtureId;
  final String locationLabel;
  final int lowStockThreshold;

  ProductRecord copyWith({int? stock}) => ProductRecord(
    id: id,
    barcode: barcode,
    name: name,
    salePrice: salePrice,
    stock: stock ?? this.stock,
    costPrice: costPrice,
    category: category,
    unit: unit,
    fixtureId: fixtureId,
    locationLabel: locationLabel,
    lowStockThreshold: lowStockThreshold,
  );
}
