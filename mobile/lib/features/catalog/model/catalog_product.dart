/// Data produk untuk tampilan katalog; seluruh nominal dalam rupiah bulat.
class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.unit,
    required this.fixtureId,
    required this.locationLabel,
    this.barcode,
    this.lowStockThreshold = 5,
  }) : assert(price >= 0),
       assert(stock >= 0),
       assert(lowStockThreshold >= 0);

  final String id;
  final String name;
  final int price;
  final int stock;
  final String unit;
  final String fixtureId;
  final String locationLabel;
  final String? barcode;
  final int lowStockThreshold;

  ProductStockStatus get stockStatus {
    if (stock == 0) return ProductStockStatus.empty;
    if (stock <= lowStockThreshold) return ProductStockStatus.low;
    return ProductStockStatus.available;
  }
}

enum ProductStockStatus { available, low, empty }
