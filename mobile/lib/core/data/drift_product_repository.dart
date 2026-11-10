import 'app_database.dart';
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
        product.barcode.trim().isEmpty ||
        product.name.trim().isEmpty ||
        product.salePrice <= 0 ||
        product.stock < 0) {
      throw ArgumentError('Data produk tidak valid');
    }
    await database.saveProduct(
      ProductsCompanion.insert(
        id: product.id,
        barcode: product.barcode,
        name: product.name,
        salePrice: product.salePrice,
        stock: product.stock,
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
  );
}
