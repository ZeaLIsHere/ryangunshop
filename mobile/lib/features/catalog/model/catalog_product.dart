import '../../../core/data/product_record.dart';

/// Data produk untuk tampilan katalog; seluruh nominal dalam rupiah bulat.
class CatalogProduct {
  factory CatalogProduct.fromRecord(ProductRecord record) => CatalogProduct(
    id: record.id,
    barcode: record.barcode,
    name: record.name,
    price: record.salePrice,
    costPrice: record.costPrice,
    stock: record.stock,
    category: record.category,
    unit: record.unit,
    fixtureId: record.fixtureId,
    locationLabel: record.locationLabel,
    lowStockThreshold: record.lowStockThreshold,
  );

  const CatalogProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.unit,
    required this.fixtureId,
    required this.locationLabel,
    required this.category,
    this.costPrice = 0,
    this.barcode,
    this.lowStockThreshold = 5,
    this.hasSamplePhoto = false,
  }) : assert(price >= 0),
       assert(stock >= 0),
       assert(lowStockThreshold >= 0),
       assert(costPrice >= 0);

  final String id;
  final String name;
  final int price;
  final int stock;
  final String unit;
  final String fixtureId;
  final String locationLabel;

  /// Kategori produk, dipakai filter kategori pada katalog.
  final String category;

  /// Harga modal satuan; 0 berarti belum diisi.
  final int costPrice;

  /// Margin kotor per unit dalam rupiah.
  int get margin => price - costPrice;

  /// Persentase margin terhadap harga jual (0-100).
  double get marginPercent => price == 0 ? 0 : margin / price * 100;
  final String? barcode;
  final int lowStockThreshold;

  /// Penanda pratinjau foto contoh; belum menyimpan berkas gambar.
  final bool hasSamplePhoto;

  ProductStockStatus get stockStatus {
    if (stock == 0) return ProductStockStatus.empty;
    if (stock <= lowStockThreshold) return ProductStockStatus.low;
    return ProductStockStatus.available;
  }
}

enum ProductStockStatus { available, low, empty }
