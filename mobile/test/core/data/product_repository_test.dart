import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/in_memory_product_repository.dart';
import 'package:ryangunshop/core/data/product_record.dart';

void main() {
  test('repository lokal dapat mencari dan menyimpan produk', () async {
    final repository = InMemoryProductRepository([
      const ProductRecord(
        id: 'p-1',
        barcode: '8990001',
        name: 'Air Mineral',
        salePrice: 4000,
        stock: 8,
      ),
    ]);

    expect((await repository.findByBarcode('8990001'))?.name, 'Air Mineral');
    await repository.save(
      const ProductRecord(
        id: 'p-1',
        barcode: '8990001',
        name: 'Air Mineral',
        salePrice: 4000,
        stock: 7,
      ),
    );
    expect((await repository.listProducts()).single.stock, 7);
  });
}
