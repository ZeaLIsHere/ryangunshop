import 'app_database.dart';

import 'package:drift/drift.dart' show Value;

import 'product_record.dart';
import 'product_repository.dart';

/// Sumber produk lokal untuk fitur yang sudah siap memakai data tersimpan.
class DriftProductRepository implements ProductRepository {
  const DriftProductRepository(this.database);

  final AppDatabase database;

  @override
  Future<List<ProductRecord>> listProducts() async =>
      (await database.listProducts()).map(_toRecord).toList();

  @override
  Future<ProductRecord?> findByBarcode(String barcode) async {
    final product = await database.findProductByBarcode(barcode);
    return product == null ? null : _toRecord(product);
  }

  @override
  Future<void> save(ProductRecord product) async {
    if (product.id.trim().isEmpty ||
        (product.barcode != null && product.barcode!.trim().isEmpty) ||
        product.name.trim().isEmpty ||
        product.salePrice <= 0 ||
        product.costPrice < 0 ||
        product.stock < 0 ||
        product.lowStockThreshold < 0 ||
        product.category.trim().isEmpty ||
        product.unit.trim().isEmpty ||
        product.locationLabel.trim().isEmpty) {
      throw ArgumentError('Data produk tidak valid');
    }
    await database.saveProduct(
      ProductsCompanion.insert(
        id: product.id,
        barcode: Value(product.barcode?.trim()),
        name: product.name,
        salePrice: product.salePrice,
        stock: product.stock,
        costPrice: Value(product.costPrice),
        category: Value(product.category),
        unit: Value(product.unit),
        fixtureId: Value(product.fixtureId),
        locationLabel: Value(product.locationLabel),
        lowStockThreshold: Value(product.lowStockThreshold),
        updatedAt: DateTime.now(),
      ),
    );
  }

  ProductRecord _toRecord(Product product) => ProductRecord(
    id: product.id,
    barcode: product.barcode,
    name: product.name,
    salePrice: product.salePrice,
    stock: product.stock,
    costPrice: product.costPrice,
    category: product.category,
    unit: product.unit,
    fixtureId: product.fixtureId,
    locationLabel: product.locationLabel,
    lowStockThreshold: product.lowStockThreshold,
  );
}
