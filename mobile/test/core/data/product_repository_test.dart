import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/data/app_database.dart';
import 'package:ryangunshop/core/data/drift_product_repository.dart';
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

  test('repository Drift menyimpan produk dan menolak stok negatif', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftProductRepository(database);
    const product = ProductRecord(
      id: 'p-2',
      barcode: '8990002',
      name: 'Teh',
      salePrice: 5000,
      stock: 4,
    );
    await repository.save(product);
    expect((await repository.findByBarcode('8990002'))?.stock, 4);
    expect((await repository.listProducts()).single.name, 'Teh');
    await repository.save(product.copyWith(stock: 2));
    expect((await repository.findByBarcode('8990002'))?.stock, 2);
    expect(
      () => repository.save(
        const ProductRecord(
          id: 'p-3',
          barcode: '8990002',
          name: 'Produk lain',
          salePrice: 6000,
          stock: 1,
        ),
      ),
      throwsA(isA<Exception>()),
    );
    expect((await repository.listProducts()), hasLength(1));
    expect(
      () => repository.save(product.copyWith(stock: -1)),
      throwsArgumentError,
    );
    expect((await repository.findByBarcode('8990002'))?.stock, 2);
  });
}
