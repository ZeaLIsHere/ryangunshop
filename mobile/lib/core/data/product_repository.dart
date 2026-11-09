import 'product_record.dart';

abstract interface class ProductRepository {
  Future<List<ProductRecord>> listProducts();
  Future<ProductRecord?> findByBarcode(String barcode);
  Future<void> save(ProductRecord product);
}
