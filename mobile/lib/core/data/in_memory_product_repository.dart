import 'product_record.dart';
import 'product_repository.dart';

/// Adapter sementara untuk wiring UI sebelum database lokal diaktifkan.
/// Tidak digunakan sebagai penyimpanan produksi.
class InMemoryProductRepository implements ProductRepository {
  InMemoryProductRepository([Iterable<ProductRecord> seed = const []])
    : _products = {for (final product in seed) product.id: product};

  final Map<String, ProductRecord> _products;

  List<ProductRecord> get snapshot => _products.values.toList();

  // Mutasi sinkron agar nota dan seluruh pengurangan stok tidak tersela await.
  void deductStock(Map<String, int> quantities) {
    for (final entry in quantities.entries) {
      final product = _products[entry.key]!;
      _products[entry.key] = product.copyWith(
        stock: product.stock - entry.value,
      );
    }
  }

  @override
  Future<List<ProductRecord>> listProducts() async => _products.values.toList();

  @override
  Future<ProductRecord?> findByBarcode(String barcode) async {
    for (final product in _products.values) {
      if (product.barcode == barcode) return product;
    }
    return null;
  }

  @override
  Future<void> save(ProductRecord product) async {
    _products[product.id] = product;
  }

  @override
  Future<void> delete(String id) async {
    _products.remove(id);
  }

  @override
  Future<void> seedIfEmpty(List<ProductRecord> starterRecords) async {
    if (_products.isEmpty) {
      for (final product in starterRecords) {
        _products[product.id] = product;
      }
    }
  }
}
